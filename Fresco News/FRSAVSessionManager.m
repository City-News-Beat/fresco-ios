//
//  FRSAVSessionManager.m
//  Fresco
//
//  Created by Daniel Sun on 11/16/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import "FRSAVSessionManager.h"

@interface FRSAVSessionManager ()

@property (nonatomic, readwrite) BOOL AVSetupSuccess;
@property (nonatomic, retain) AVCaptureVideoDataOutput *videoOutput;

//@property (nonatomic, assign) BOOL capturingStilImage;

@end

@implementation FRSAVSessionManager

+ (instancetype)defaultManager {
    static FRSAVSessionManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      _manager = [[FRSAVSessionManager alloc] init];
    });
    return _manager;
}

- (dispatch_queue_t)sessionQueue {
    if (!_sessionQueue) {
        _sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    }
    return _sessionQueue;
}

/* 
    Whoever wrote this: do not make structures with FRS prefix just because, there's no reason this couldn't have just returned an AVAuthorizationStatus
 */

- (FRSAVAuthStatus)authStatus {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
    case AVAuthorizationStatusAuthorized:
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"first-camera"]) {
            [[NSUserDefaults standardUserDefaults] setObject:@(TRUE) forKey:@"first-camera"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [FRSTracker track:cameraEnabled];
            [FRSTracker track:microphoneEnabled];
        }
        return FRSAVStatusAuthorized;
        break;
    case AVAuthorizationStatusNotDetermined:
        return FRSAVStatusNotDetermined;
        break;
    case AVAuthorizationStatusDenied:
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"first-camera-disabled"]) {
            [[NSUserDefaults standardUserDefaults] setObject:@(TRUE) forKey:@"first-camera-disabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [FRSTracker track:cameraDisabled];
            [FRSTracker track:microphoneDisabled];
        }
        return FRSAVStatusDenied;
        break;
    default:
        return FRSAVStatusDenied;
        break;
    }
}

- (void)clearCaptureSession {
    dispatch_async(self.sessionQueue, ^{
      [self.session stopRunning];
      _session = nil;
    });
}

- (void)startCaptureSessionForCaptureMode:(FRSCaptureMode)captureMode withCompletion:(void (^)())completion {
    self.session = [[AVCaptureSession alloc] init];

    dispatch_async(self.sessionQueue, ^{
      if (self.authStatus == FRSAVStatusNotDetermined) {
          dispatch_suspend(self.sessionQueue);
          [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                   completionHandler:^(BOOL granted) {
                                     dispatch_resume(self.sessionQueue);
                                     [self startCaptureSessionForCaptureMode:captureMode withCompletion:completion];
                                   }];
      } else if (self.authStatus == FRSAVStatusDenied) {
          return; //theoretically should never be called, becuase you can't get in without access to camera.
      }

      else
          self.AVSetupSuccess = YES;

      if (![self videoInputDevice])
          return;

      [self configureInputsOutputs];
      [self checkThumb];

      if (captureMode == FRSCaptureModePhoto)
          self.session.sessionPreset = AVCaptureSessionPresetPhoto;
      else
          self.session.sessionPreset = AVCaptureSessionPresetHigh;

      if (completion)
          completion();
    });
}

- (void)checkThumb {
}

- (void)configureInputsOutputs {

    //VIDEO INPUT
    if ([self.session canAddInput:[self videoInputDevice]]) {
        [self.session addInput:[self videoInputDevice]];
    } else {
        self.AVSetupSuccess = NO;
    }

    //AUDIO INPUT

    NSError *error;

    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];

    if ([self.session canAddInput:audioDeviceInput]) {
        [self.session addInput:audioDeviceInput];
    } else {
        self.AVSetupSuccess = NO;
    }

    //VIDEO OUTPUT

    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.session canAddOutput:self.movieFileOutput]) {
        [self.session addOutput:self.movieFileOutput];

        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection.isVideoStabilizationSupported) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }

        AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];

        // create a queue to run the capture on
        dispatch_queue_t captureQueue = dispatch_queue_create("captureQueue", NULL);

        // setup our delegate
        [videoOutput setSampleBufferDelegate:self queue:captureQueue];
        //[self.session addOutput:videoOutput];

        // configure the pixel format
        // Add the input and output

    } else
        self.AVSetupSuccess = NO;

    //PHOTO OUTPUT
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([self.session canAddOutput:self.stillImageOutput]) {
        self.stillImageOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
        [self.session addOutput:self.stillImageOutput];
    } else
        self.AVSetupSuccess = NO;

    [self.session startRunning];
}

- (AVCaptureDeviceInput *)videoInputDevice {

    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = [devices firstObject];

    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            captureDevice = device;
            break;
        }
    }

    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];

    return videoDeviceInput ?: nil;
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    dispatch_async(self.sessionQueue, ^{
      AVCaptureDevice *device = [self videoInputDevice].device;
      NSError *error = nil;
      if ([device lockForConfiguration:&error]) {
          // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
          // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
          if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode]) {
              device.focusPointOfInterest = point;
              device.focusMode = focusMode;
          }

          if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
              device.exposurePointOfInterest = point;
              device.exposureMode = exposureMode;
          }

          device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
          [device unlockForConfiguration];
      } else {
          NSLog(@"Could not lock device for configuration: %@", error.localizedDescription);
      }
    });
}

//-(UIInterfaceOrientation)initialOrientation{
//
//
//    return [UIApplication sharedApplication].statusBarOrientation;
//
////    dispatch_async(dispatch_get_main_queue(), ^{
////
////        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
////        AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
////        if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
////            initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
////        }
////
////        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
////        previewLayer.connection.videoOrientation = initialVideoOrientation;
////
////    }
////
////                   });
//}

- (void)configureOrientationForPreview:(UIView *)preview {

    //COME BACK TO THIS

    dispatch_async(dispatch_get_main_queue(), ^{

      UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;

      AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
      if (statusBarOrientation != UIInterfaceOrientationUnknown) {
          initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
      }

      AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)preview.layer;
      previewLayer.connection.videoOrientation = initialVideoOrientation;

    });
}

@end
