//
//  FRSAVSessionManager.m
//  Fresco
//
//  Created by Daniel Sun on 11/16/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import "FRSAVSessionManager.h"


@interface FRSAVSessionManager()



@property (nonatomic, readwrite) BOOL AVSetupSuccess;


//@property (nonatomic, assign) BOOL capturingStilImage;

@end

@implementation FRSAVSessionManager

+(instancetype)defaultManager{
    static FRSAVSessionManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[FRSAVSessionManager alloc] init];
    });
    return _manager;
}

-(dispatch_queue_t)sessionQueue{
    if (!_sessionQueue){
        _sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL);
    }
    return _sessionQueue;
}

-(AVCaptureSession *)session{
    if (!_session){
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

-(FRSAVAuthStatus)authStatus{
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
            return FRSAVStatusAuthorized;
            break;
        case AVAuthorizationStatusNotDetermined:
            return FRSAVStatusNotDetermined;
            break;
        case AVAuthorizationStatusDenied:
            return FRSAVStatusDenied;
            break;
        default:
            return FRSAVStatusDenied;
            break;
    }
}

-(void)startCaptureSession{
    dispatch_async(self.sessionQueue, ^{
        if (self.authStatus == FRSAVStatusDenied || self.authStatus == FRSAVStatusNotDetermined){
            self.AVSetupSuccess = NO;
            return;
        }
        else self.AVSetupSuccess = YES;
        
        if (![self videoInputDevice])
            return;
        
        [self.session beginConfiguration];
        
        [self configureInputsOutputs];
        
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
        
        
        [self.session commitConfiguration];
    });
}

-(void)configureInputsOutputs{
    
    //VIDEO INPUT
    if ([self.session canAddInput:[self videoInputDevice]])
        [self.session addInput:[self videoInputDevice]];
    else self.AVSetupSuccess = NO;
    
    //AUDIO INPUT
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    if ([self.session canAddInput:audioDeviceInput])
        [self.session addInput:audioDeviceInput];
    else self.AVSetupSuccess = NO;
    
    //VIDEO OUTPUT
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ( [self.session canAddOutput:movieFileOutput] ) {
        [self.session addOutput:movieFileOutput];
        AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ( connection.isVideoStabilizationSupported ) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        self.movieFileOutput = movieFileOutput;
    } else self.AVSetupSuccess = NO;
    
    //PHOTO OUTPUT
    AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ( [self.session canAddOutput:stillImageOutput] ) {
        stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
        [self.session addOutput:stillImageOutput];
        self.stillImageOutput = stillImageOutput;
    } else self.AVSetupSuccess = NO;
}

-(AVCaptureDeviceInput *)videoInputDevice{
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            captureDevice = device;
            break;
        }
    }
    
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
    
    return videoDeviceInput ? :nil;
    
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *device = [self videoInputDevice].device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error.localizedDescription );
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

-(void)configureOrientationForPreview:(UIView *)preview{
    
    //COME BACK TO THIS
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        
        AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
        if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
            initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
        }
        
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)preview.layer;
        previewLayer.connection.videoOrientation = initialVideoOrientation;
        
    });
}

//-(void)startAVCaptureSession{
//    
//    // Check for device authorization
//    // Check video authorization status. Video access is required and audio access is optional.
//    // If audio access is denied, audio is not recorded during movie recording.
//    
//    
//    // Setup the capture session.
//    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
//    // Why not do all of this on the main queue?
//    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
//    // so that the main queue isn't blocked, which keeps the UI responsive.
//    dispatch_async(self.sessionQueue, ^{
//        
//        if ( self.setupResult != FRSCamSetupResultSuccess ) {
//            return;
//        }
//        
//        self.backgroundRecordingID = UIBackgroundTaskInvalid;
//        NSError *error = nil;
//        
//        AVCaptureDevice *videoDevice = [FRSCamViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
//        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
//        
//        [self.session beginConfiguration];
//        
//        if ([self.session canAddInput:videoDeviceInput] ) {
//            
//            [self.session addInput:videoDeviceInput];
//            self.videoDeviceInput = videoDeviceInput;
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                // Why are we dispatching this to the main queue?
//                // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
//                // can only be manipulated on the main thread.
//                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
//                // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
//                
//                // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
//                // -[viewWillTransitionToSize:withTransitionCoordinator:].
//                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
//                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
//                if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
//                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
//                }
//                
//                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
//                previewLayer.connection.videoOrientation = initialVideoOrientation;
//                
//            });
//            
//        }
//        else {
//            NSLog( @"Could not add video device input to the session" );
//            self.setupResult = FRSCamSetupResultSessionConfigurationFailed;
//        }
//        
//        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
//        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
//        
//        if ( [self.session canAddInput:audioDeviceInput] ) {
//            [self.session addInput:audioDeviceInput];
//        }
//        else {
//            NSLog( @"Could not add audio device input to the session" );
//        }
//        
//        AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
//        if ( [self.session canAddOutput:movieFileOutput] ) {
//            [self.session addOutput:movieFileOutput];
//            AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//            if ( connection.isVideoStabilizationSupported ) {
//                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
//            }
//            self.movieFileOutput = movieFileOutput;
//        }
//        else {
//            NSLog( @"Could not add movie file output to the session" );
//            self.setupResult = FRSCamSetupResultSessionConfigurationFailed;
//        }
//        
//        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
//        if ( [self.session canAddOutput:stillImageOutput] ) {
//            stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
//            [self.session addOutput:stillImageOutput];
//            self.stillImageOutput = stillImageOutput;
//        }
//        else {
//            NSLog( @"Could not add still image output to the session" );
//            self.setupResult = FRSCamSetupResultSessionConfigurationFailed;
//        }
//        
//        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
//        
//        [self.session commitConfiguration];
//        
//        //End session thread
//    });
//
//}

@end