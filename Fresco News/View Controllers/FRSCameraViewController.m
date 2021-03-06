//
//  FRSCameraViewController.m
//  Fresco
//
//  Created by Daniel Sun on 11/13/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import "FRSCameraViewController.h"

//Apple APIs
@import Photos;
@import AVFoundation;
@import CoreMotion;

//Managers
#import "FRSAVSessionManager.h"
#import "FRSLocator.h"

//Categories
//#import "UIColor+Additions.h"
#import "UIColor+Fresco.h"
#import "UIView+Helpers.h"
#import "UIImage+Helpers.h"
#import "FRSAssignment.h"
#import "CLLocation+EXIFGPS.h"
#import "FRSTabBarController.h"
#import "FRSBaseViewController.h"

#define ICON_WIDTH 24
#define PREVIEW_WIDTH 56
#define APERTURE_WIDTH 72
#define SIDE_PAD 12
#define PHOTO_FRAME_RATIO 4 / 3

static int const maxVideoLength = 60.0; // in seconds, triggers trim

@interface FRSCameraViewController () <AVCaptureFileOutputRecordingDelegate>

@property (strong, nonatomic) FRSAVSessionManager *sessionManager;
@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) UIView *preview;

@property (strong, nonatomic) UIView *bottomClearContainer;
@property (strong, nonatomic) UIView *bottomOpaqueContainer;

@property (strong, nonatomic) UIImageView *videoRotateIV;
@property (strong, nonatomic) UIImageView *videoPhoneIV;

@property (strong, nonatomic) UIView *apertureShadowView;
@property (strong, nonatomic) UIView *apertureAnimationView;
@property (strong, nonatomic) UIView *apertureBackground;
@property (strong, nonatomic) UIImageView *apertureImageView;
@property (strong, nonatomic) UIView *apertureMask;
@property (strong, nonatomic) UIView *ivContainer;
@property (strong, nonatomic) UIButton *clearButton;

@property (strong, nonatomic) UIView *topContainer;

@property (strong, nonatomic) UIButton *apertureButton;

@property (strong, nonatomic) UIButton *previewButton;
@property (strong, nonatomic) UIImageView *previewBackgroundIV;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (strong, nonatomic) UIView *captureModeToggleView;
@property (strong, nonatomic) UIImageView *cameraIV;
@property (strong, nonatomic) UIImageView *videoIV;

@property (strong, nonatomic) UIButton *flashButton;

@property (strong, nonatomic) UIButton *nextButton;
@property (strong, nonatomic) UIButton *closeButton;

@property (strong, nonatomic) UIImageView *locationIV;
@property (strong, nonatomic) UILabel *assignmentLabel;

@property (strong, nonatomic) UIView *whiteView;

@property (nonatomic) UIDeviceOrientation currentOrientation;

@property (nonatomic) BOOL capturingImage;

@property (nonatomic) BOOL flashIsOn;
@property (nonatomic) BOOL torchIsOn;

@property (nonatomic, strong) FRSTabBarController *tabBarController;

@property (strong, nonatomic) CAShapeLayer *circleLayer;
@property (nonatomic) BOOL isRecording;
@property (strong, nonatomic) NSTimer *videoTimer;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@property (nonatomic) BOOL firstTime;
@property (nonatomic) BOOL firstTimeAni;

@property (nonatomic) CGRect originalApertureFrame;
@property (nonatomic) UIDeviceOrientation lastOrientation;
@property (nonatomic) CGFloat rotationIVOriginalY;

@property (nonatomic, retain) NSMutableArray *positions;
@property (strong, nonatomic) UIView *alertContainer;
@property (nonatomic) BOOL didPush;

@end

@implementation FRSCameraViewController

- (instancetype)initWithCaptureMode:(FRSCaptureMode)captureMode {
    self = [super init];

    if (self) {
        self.sessionManager = [FRSAVSessionManager defaultManager];
        self.captureMode = captureMode;
        self.lastOrientation = UIDeviceOrientationPortrait;
        self.firstTime = YES;
        self.firstTimeAni = YES;
    }

    return self;
}

- (instancetype)initWithCaptureMode:(FRSCaptureMode)captureMode selectedAssignment:(NSDictionary *)assignment selectedGlobalAssignment:(NSDictionary *)globalAssignment {
    self = [super init];

    if (self) {
        self.sessionManager = [FRSAVSessionManager defaultManager];
        self.captureMode = captureMode;
        self.lastOrientation = UIDeviceOrientationPortrait;
        self.firstTime = YES;
        self.firstTimeAni = YES;

        self.preselectedGlobalAssignment = globalAssignment;
        self.preselectedAssignment = assignment;
    }

    return self;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
}

- (void)viewDidLoad {

    [super viewDidLoad];

    [self configureUI];
    [self updatePreviewButtonWithImage:Nil];
    [self setAppropriateIconsForCaptureState];
    [self adjustFramesForCaptureState];
    [self rotateAppForOrientation:self.lastOrientation];

    [self checkLibrary];

    //[self addPanGesture];

    self.isRecording = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopVideoCaptureIfNeeded) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)addPanGesture {
    UIPinchGestureRecognizer *zoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoom:)];
    [self.view addGestureRecognizer:zoomGesture];
}

- (void)zoom:(UIPinchGestureRecognizer *)recognizer {

    AVCaptureVideoPreviewLayer *previewLayer = self.captureVideoPreviewLayer;

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        beginGestureScale = effectiveScale;

        if (beginGestureScale <= 0) {
            beginGestureScale = 1;
            effectiveScale = 1;
        }
    }

    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for (i = 0; i < numTouches; ++i) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
        if (![previewLayer containsPoint:convertedLocation]) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }

    if (allTouchesAreOnThePreviewLayer) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        effectiveScale = beginGestureScale * recognizer.scale;

        if (effectiveScale < 1.0)
            effectiveScale = 1.0;
        CGFloat maxScaleAndCropFactor = device.activeFormat.videoMaxZoomFactor;
        if (effectiveScale > maxScaleAndCropFactor)
            effectiveScale = maxScaleAndCropFactor;

        if ([device respondsToSelector:@selector(setVideoZoomFactor:)]
            && device.activeFormat.videoMaxZoomFactor >= effectiveScale) {

            if ([device lockForConfiguration:nil]) {
                [device setVideoZoomFactor:effectiveScale];
                [device unlockForConfiguration];
            }
        }
    }
}
- (void)fetchGalleryAssetsInBackgroundWithCompletion:(void (^)())completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      self.fileLoader = [[FRSFileLoader alloc] initWithDelegate:Nil];
      PHAsset *firstAsset = [self.fileLoader assetAtIndex:0];

      if (firstAsset) {
          // image that fits predicate at index 0
          [self.fileLoader getDataFromAsset:firstAsset
                                   callback:^(UIImage *image, AVAsset *video, PHAssetMediaType mediaType, NSError *error) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                       [self updatePreviewButtonWithImage:image];
                                       self.capturingImage = NO;
                                       self.previewButton.userInteractionEnabled = YES;
                                       self.nextButton.userInteractionEnabled = YES;
                                     });
                                   }];
      } else {
          // no image
      }
    });
}

- (void)checkLibrary {
    [self fetchGalleryAssetsInBackgroundWithCompletion:Nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [FRSTracker screen:@"Camera"];

    self.isPresented = YES;
    self.didPush = NO;

    if (!self.sessionManager.session.isRunning) {

        [self.sessionManager startCaptureSessionForCaptureMode:self.captureMode
                                                withCompletion:^{
                                                  [self configurePreviewLayer];
                                                }];
    }

    [self shouldShowStatusBar:NO animated:YES];

    [self.navigationController setNavigationBarHidden:TRUE animated:YES];

    self.motionManager = [[CMMotionManager alloc] init];
    [self startTrackingMovement];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    entry = [NSDate date];
    self.preview.alpha = 1.0;
}

- (void)viewDidDisappear:(BOOL)animated {

    [super viewDidDisappear:animated];

    if (entry) {
        exit = [NSDate date];

        NSInteger secondsInCamera = [exit timeIntervalSinceDate:entry];
        [FRSTracker track:cameraSession parameters:@{ activityDuration : @(secondsInCamera) }];
    }

    [self.sessionManager clearCaptureSession];

    [_captureVideoPreviewLayer removeFromSuperlayer];

    self.isPresented = NO;
    [self.motionManager stopAccelerometerUpdates];
    [self.motionManager stopGyroUpdates];
    [self shouldShowStatusBar:YES animated:YES];
}

#pragma mark - UI configuration methods

- (void)configureUI {
    [self configurePreview];
    [self configureBottomContainer];
    [self configureTopContainer];
}

- (void)configureTopContainer {

    self.topContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 10, self.view.frame.size.width, 24)];
    self.topContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.topContainer];

    self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(5, -7, 38, 38)];
    [self.closeButton setImage:[UIImage imageNamed:@"x-icon-light"] forState:UIControlStateNormal];
    [self.closeButton addDropShadowWithColor:[UIColor frescoShadowColor] path:nil];

    [self.closeButton addTarget:self action:@selector(dismissAndReturnToPreviousTab) forControlEvents:UIControlEventTouchUpInside];
    [self.topContainer addSubview:self.closeButton];

    self.locationIV = [[UIImageView alloc] initWithFrame:CGRectMake(self.closeButton.frame.origin.x + self.closeButton.frame.size.width + 17, 1, 22, 22)];
    self.locationIV.contentMode = UIViewContentModeScaleAspectFit;
    self.locationIV.image = [UIImage imageNamed:@"crosshairs-icon"];
    [self.locationIV addDropShadowWithColor:[UIColor frescoShadowColor] path:nil];
    self.locationIV.alpha = 0.0;
    [self.topContainer addSubview:self.locationIV];

    self.assignmentLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.locationIV.frame.origin.x + self.locationIV.frame.size.width + 7, 0, [self assignmentLabelWidth], 24)];
    self.assignmentLabel.textColor = [UIColor whiteColor];
    self.assignmentLabel.font = [UIFont helveticaNeueMediumWithSize:15];
    [self.assignmentLabel addDropShadowWithColor:[UIColor frescoShadowColor] path:nil];
    self.assignmentLabel.alpha = 0.0;
    [self.topContainer addSubview:self.assignmentLabel];
}

- (NSInteger)assignmentLabelWidth {
    return self.view.frame.size.width - 24 - 22 - 10 - 17 - 7 - 12 - 7;
}

- (void)configurePreview {
    self.preview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * PHOTO_FRAME_RATIO)];
    self.preview.backgroundColor = [UIColor blackColor];

    UITapGestureRecognizer *focusGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToFocus:)];
    [self.preview addGestureRecognizer:focusGR];

    [self.view addSubview:self.preview];
}

- (void)checkThumb {

    /*UIGraphicsBeginImageContextWithOptions(self.captureVideoPreviewLayer.frame.size, NO, 0);
     [self.captureVideoPreviewLayer renderInContext:UIGraphicsGetCurrentContext()];
     UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     
     dispatch_async(dispatch_get_main_queue(), ^{
     [self luminanceOfImage:outputImage];
     });
     
     [self performSelector:@selector(checkThumb) withObject:Nil afterDelay:.5];*/
}

- (void)luminanceOfImage:(UIImage *)inputImage {
    //check for thumb
}

- (void)configurePreviewLayer {
    dispatch_async(dispatch_get_main_queue(), ^{
      CALayer *viewLayer = self.preview.layer;
      self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.sessionManager.session];
      self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
      self.captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
      [viewLayer addSublayer:self.captureVideoPreviewLayer];
      self.captureVideoPreviewLayer.frame = self.preview.frame;
      [self checkThumb];
    });
}

- (void)updatePreviewButtonWithAsset {
}

- (void)dismissAndReturnToPreviousTab {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self shouldShowStatusBar:YES animated:YES];
}

- (void)updatePreviewButtonWithImage:(UIImage *)image {

    dispatch_async(dispatch_get_main_queue(), ^{
      UIImageView *temp = [[UIImageView alloc] initWithFrame:self.previewButton.frame];
      temp.image = image;
      [temp clipAsCircle];
      temp.transform = CGAffineTransformMakeScale(0.000001, 0.000001);

      if (self.previewBackgroundIV.alpha <= 0) {
          [self.previewBackgroundIV addSubview:temp];

          [self createNextButtonWithFrame:self.previewButton.frame];
          self.nextButton.transform = CGAffineTransformMakeScale(0.00001, 0.00001);
          [self.previewBackgroundIV addSubview:self.nextButton];

          [UIView animateWithDuration:0.3
              delay:0
              options:UIViewAnimationOptionCurveEaseInOut
              animations:^{
                temp.transform = CGAffineTransformMakeScale(1.01, 1.01);
                self.previewBackgroundIV.alpha = 1.0;
                self.nextButton.transform = CGAffineTransformMakeScale(1.01, 1.01);
                self.nextButton.alpha = 0.7;
              }
              completion:^(BOOL finished) {
                [self.previewButton setImage:image forState:UIControlStateNormal];
                [temp removeFromSuperview];
              }];
      }

      else if (self.nextButton) { //The next button has been animated in once
          self.previewBackgroundIV.alpha = 1.0;
          [self.previewBackgroundIV insertSubview:temp belowSubview:self.nextButton];
          [UIView animateWithDuration:0.3
              delay:0
              options:UIViewAnimationOptionCurveEaseInOut
              animations:^{
                temp.transform = CGAffineTransformMakeScale(1.01, 1.01);
              }
              completion:^(BOOL finished) {
                [self.previewButton setImage:image forState:UIControlStateNormal];
                [temp removeFromSuperview];
              }];
      } else { //First time the next button has been animated
          self.previewBackgroundIV.alpha = 1.0;
          [self.previewBackgroundIV addSubview:temp];

          [self createNextButtonWithFrame:self.previewButton.frame];
          self.nextButton.transform = CGAffineTransformMakeScale(0.001, 0.001);
          [self.previewBackgroundIV addSubview:self.nextButton];

          [UIView animateWithDuration:0.3
              delay:0
              options:UIViewAnimationOptionCurveEaseInOut
              animations:^{
                self.nextButton.transform = CGAffineTransformMakeScale(1.01, 1.01);
                self.nextButton.alpha = 0.7;
              }
              completion:^(BOOL finished) {
                [self.previewButton setImage:image forState:UIControlStateNormal];
              }];
      }
    });
}

- (void)configureBottomContainer {

    self.bottomOpaqueContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width * PHOTO_FRAME_RATIO, self.view.frame.size.width, self.view.frame.size.height - (self.view.frame.size.width * PHOTO_FRAME_RATIO))];
    self.bottomOpaqueContainer.backgroundColor = [UIColor frescoBackgroundColorLight];
    // 239 239 233
    [self.view addSubview:self.bottomOpaqueContainer];

    self.bottomClearContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width * PHOTO_FRAME_RATIO, self.view.frame.size.width, self.view.frame.size.height - (self.view.frame.size.width * PHOTO_FRAME_RATIO))];
    self.bottomClearContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bottomClearContainer];

    self.bottomOpaqueContainer.layer.shadowOffset = CGSizeMake(0, -1);
    self.bottomOpaqueContainer.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.bottomOpaqueContainer.layer.shadowOpacity = 1.0;

    [self configureNextSection];
    [self configureApertureButton];
    [self configureFlashButton];
    [self configureToggleView];
    [self setAppropriateIconsForCaptureState];
}

- (void)configureNextSection {
    self.previewBackgroundIV = [[UIImageView alloc] initWithFrame:CGRectMake(SIDE_PAD, 0, PREVIEW_WIDTH, PREVIEW_WIDTH)];
    self.previewBackgroundIV.image = [UIImage imageNamed:@"white-background-circle"];
    [self.previewBackgroundIV centerVerticallyInView:self.bottomClearContainer];
    self.previewBackgroundIV.userInteractionEnabled = YES;
    self.previewBackgroundIV.alpha = 0.0;
    [self.bottomClearContainer addSubview:self.previewBackgroundIV];
    [self.previewBackgroundIV addDropShadowWithColor:[UIColor frescoShadowColor] path:nil];

    self.previewButton = [[UIButton alloc] initWithFrame:CGRectMake(4, 4, PREVIEW_WIDTH - 8, PREVIEW_WIDTH - 8)];
    self.previewButton.contentMode = UIViewContentModeScaleAspectFill;
    self.previewButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.previewButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    self.previewButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.previewButton addTarget:self action:@selector(handlePreviewButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.previewButton clipAsCircle];
    [self.previewBackgroundIV addSubview:self.previewButton];
}

- (void)createNextButtonWithFrame:(CGRect)frame {
    self.nextButton = [[UIButton alloc] initWithFrame:frame];
    [self.nextButton setTitle:@"NEXT" forState:UIControlStateNormal];
    [self.nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.nextButton setBackgroundColor:[UIColor whiteColor]];
    [self.nextButton clipAsCircle];
    [self.nextButton.titleLabel setFont:[UIFont notaBoldWithSize:15]];
    [self.nextButton addTarget:self action:@selector(handlePreviewButtonTapped) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureApertureButton {

    self.apertureShadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APERTURE_WIDTH, APERTURE_WIDTH)];
    [self.apertureShadowView centerHorizontallyInView:self.bottomClearContainer];
    [self.apertureShadowView centerVerticallyInView:self.bottomClearContainer];
    [self.apertureShadowView addDropShadowWithColor:[UIColor frescoShadowColor] path:nil];
    [self.bottomClearContainer addSubview:self.apertureShadowView];

    self.apertureBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APERTURE_WIDTH, APERTURE_WIDTH)];
    self.apertureBackground.layer.cornerRadius = self.apertureBackground.frame.size.width / 2.;
    self.apertureBackground.layer.masksToBounds = YES;
    [self.apertureShadowView addSubview:self.apertureBackground];

    self.apertureBackground.backgroundColor = [UIColor blueColor];

    self.apertureAnimationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APERTURE_WIDTH, APERTURE_WIDTH)];
    [self.apertureAnimationView centerHorizontallyInView:self.apertureBackground];
    [self.apertureAnimationView centerVerticallyInView:self.apertureBackground];
    self.apertureAnimationView.layer.cornerRadius = APERTURE_WIDTH / 2.;
    self.apertureAnimationView.layer.masksToBounds = YES;
    self.apertureAnimationView.alpha = 0.0;
    self.apertureAnimationView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [self.apertureBackground addSubview:self.apertureAnimationView];

    self.apertureMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.apertureBackground.frame.size.width, self.apertureBackground.frame.size.height)];
    self.apertureMask.backgroundColor = [UIColor clearColor];
    self.apertureMask.layer.borderColor = [UIColor frescoOrangeColor].CGColor;
    self.apertureMask.layer.borderWidth = 4.0;
    [self.apertureBackground addSubview:self.apertureMask];
    self.apertureMask.layer.cornerRadius = self.apertureMask.frame.size.width / 2;

    self.originalApertureFrame = CGRectMake(4, 4, APERTURE_WIDTH - 8, APERTURE_WIDTH - 8);
    self.apertureButton = [[UIButton alloc] initWithFrame:self.originalApertureFrame];

    self.apertureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, APERTURE_WIDTH - 8, APERTURE_WIDTH - 8)];
    [self.apertureImageView setImage:[UIImage imageNamed:@"camera-iris"]];
    self.apertureImageView.alpha = 1;
    self.apertureImageView.contentMode = UIViewContentModeScaleAspectFill;

    self.ivContainer = [[UIView alloc] initWithFrame:self.apertureShadowView.frame];
    //    self.ivContButton = [[UIButton alloc] initWithFrame:self.apertureShadowView.frame];

    self.videoRotateIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 92.2, 92.2)];
    [self.videoRotateIV centerHorizontallyInView:self.ivContainer];
    [self.videoRotateIV centerVerticallyInView:self.ivContainer];

    [self.videoRotateIV setImage:[UIImage imageNamed:@"videoRotateLeft"]];
    self.videoRotateIV.layer.shadowColor = [UIColor blackColor].CGColor;
    self.videoRotateIV.layer.shadowOffset = CGSizeMake(0, 2);
    self.videoRotateIV.layer.shadowOpacity = 0.15;
    self.videoRotateIV.layer.shadowRadius = 1.0;
    self.videoRotateIV.alpha = 1.0;
    self.rotationIVOriginalY = self.videoRotateIV.frame.origin.y;
    self.videoRotateIV.userInteractionEnabled = YES;

    self.videoPhoneIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 13, 22)];
    [self.videoPhoneIV centerHorizontallyInView:self.ivContainer];
    [self.videoPhoneIV centerVerticallyInView:self.ivContainer];

    self.videoPhoneIV.frame = CGRectOffset(self.videoPhoneIV.frame, 0, 3);

    [self.videoPhoneIV setImage:[UIImage imageNamed:@"cellphone"]];
    self.videoPhoneIV.alpha = (self.captureMode == FRSCaptureModeVideo && self.lastOrientation == UIDeviceOrientationPortrait) ? 0.7 : 0.0;
    self.videoPhoneIV.contentMode = UIViewContentModeScaleAspectFill;
    self.videoPhoneIV.userInteractionEnabled = YES;

    [self.apertureButton addSubview:self.apertureImageView];

    [self.ivContainer addSubview:self.videoPhoneIV];
    [self.ivContainer addSubview:self.videoRotateIV];

    [self.apertureMask addSubview:self.apertureButton];

    [self.bottomClearContainer addSubview:self.ivContainer];

    self.clearButton = [[UIButton alloc] initWithFrame:self.ivContainer.bounds];
    [self.ivContainer addSubview:self.clearButton];

    [self.apertureButton addTarget:self action:@selector(handleApertureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.apertureButton addTarget:self action:@selector(handleApertureButtonDepressed) forControlEvents:UIControlEventTouchDown];
    [self.apertureButton addTarget:self action:@selector(handleApertureButtonReleased) forControlEvents:UIControlEventTouchDragExit];

    [self.clearButton addTarget:self action:@selector(handleApertureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.clearButton addTarget:self action:@selector(handleApertureButtonDepressed) forControlEvents:UIControlEventTouchDown];
    [self.clearButton addTarget:self action:@selector(handleApertureButtonReleased) forControlEvents:UIControlEventTouchDragExit];
}

- (void)handleApertureButtonDepressed {

    self.apertureButton.userInteractionEnabled = NO;
    self.clearButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:0
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{

          self.videoRotateIV.frame = CGRectOffset(self.videoRotateIV.frame, 0, 1);
          self.videoRotateIV.layer.shadowOffset = CGSizeMake(0, 1);

        }
        completion:^(BOOL finished) {
          self.apertureButton.userInteractionEnabled = YES;
          self.clearButton.userInteractionEnabled = YES;
        }];
}

- (void)handleApertureButtonReleased {

    self.apertureButton.userInteractionEnabled = NO;
    self.clearButton.userInteractionEnabled = NO;

    [UIView animateWithDuration:0
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{

          self.videoRotateIV.frame = CGRectOffset(self.videoRotateIV.frame, 0, -1);
          self.videoRotateIV.layer.shadowOffset = CGSizeMake(0, 2);

        }
        completion:^(BOOL finished) {
          self.apertureButton.userInteractionEnabled = YES;
          self.clearButton.userInteractionEnabled = YES;
        }];
}

- (void)animatePhoneRotationForVideoOrientation {

    self.apertureButton.userInteractionEnabled = NO;
    self.clearButton.userInteractionEnabled = NO;

    CGFloat duration = 0.3;

    [UIView animateWithDuration:duration / 4.
        delay:0
        options:UIViewAnimationOptionCurveEaseIn
        animations:^{
          self.videoPhoneIV.transform = CGAffineTransformMakeRotation((M_PI * 2.) / -3.);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:duration / 4.
              delay:0
              options:UIViewAnimationOptionCurveLinear
              animations:^{
                self.videoPhoneIV.transform = CGAffineTransformMakeRotation((M_PI * 2.) * 2. / -3.);
              }
              completion:^(BOOL finished) {
                [UIView animateWithDuration:duration / 4.
                    delay:0
                    options:UIViewAnimationOptionCurveLinear
                    animations:^{
                      self.videoPhoneIV.transform = CGAffineTransformMakeRotation(M_PI * -2.0);
                    }
                    completion:^(BOOL finished) {
                      [UIView animateWithDuration:0.06
                          delay:0
                          options:UIViewAnimationOptionCurveLinear
                          animations:^{
                            self.videoPhoneIV.transform = CGAffineTransformMakeRotation(M_PI * -0.1);
                          }
                          completion:^(BOOL finished) {
                            [UIView animateWithDuration:0.06
                                delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                                animations:^{
                                  self.videoPhoneIV.transform = CGAffineTransformMakeRotation(0);
                                }
                                completion:^(BOOL finished) {
                                  self.apertureButton.userInteractionEnabled = YES;
                                  self.clearButton.userInteractionEnabled = YES;
                                }];
                          }];
                    }];
              }];
        }];
}

- (void)animateRotateView:(UIView *)view withDuration:(CGFloat)duration counterClockwise:(BOOL)counterClockwise {

    NSInteger mult = 1;
    if (counterClockwise)
        mult = -1;

    [UIView animateWithDuration:duration / 3.
        delay:0
        options:UIViewAnimationOptionCurveEaseIn
        animations:^{
          view.transform = CGAffineTransformMakeRotation((M_PI * 2.) / 3. * mult);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:duration / 3.
              delay:0
              options:UIViewAnimationOptionCurveLinear
              animations:^{
                view.transform = CGAffineTransformMakeRotation((M_PI * 2.) * 2. / 3. * mult);
              }
              completion:^(BOOL finished) {
                [UIView animateWithDuration:duration / 3.
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                   view.transform = CGAffineTransformMakeRotation(M_PI * 2. * mult);
                                 }
                                 completion:nil];
              }];
        }];
}

- (void)animateVideoRotateHide {

    [UIView animateWithDuration:0.45 / 2
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{

          self.apertureShadowView.transform = CGAffineTransformMakeScale(0.9, 0.9);

        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.45 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.apertureShadowView.transform = CGAffineTransformMakeScale(1, 1);
                           }
                           completion:nil];
        }];

    [self animateRotateView:self.videoRotateIV withDuration:0.45 counterClockwise:YES];
    [self animateRotateView:self.videoPhoneIV withDuration:0.45 counterClockwise:YES];

    [UIView animateWithDuration:0.45
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{

                       self.ivContainer.transform = CGAffineTransformMakeScale(0.01, 0.01);
                       self.videoRotateIV.alpha = 0;
                       self.videoPhoneIV.alpha = 0;

                     }
                     completion:nil];

    [UIView animateWithDuration:0.45
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{

                       self.apertureImageView.transform = CGAffineTransformMakeRotation(M_PI);
                       self.apertureImageView.transform = CGAffineTransformMakeScale(1, 1);
                       self.apertureImageView.alpha = 1;

                     }
                     completion:nil];
}

- (void)animateVideoRotationAppear {

    CGFloat duration = self.firstTimeAni ? 0.05 : 0.45;

    [UIView animateWithDuration:duration / 2
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{

          self.apertureShadowView.transform = CGAffineTransformMakeScale(0.9, 0.9);

        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:duration / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.apertureShadowView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                           }
                           completion:nil];
        }];

    [self animateRotateView:self.videoRotateIV withDuration:duration counterClockwise:NO];
    [self animateRotateView:self.videoPhoneIV withDuration:duration counterClockwise:NO];

    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{

                       self.videoRotateIV.alpha = 1.0;
                       self.videoPhoneIV.alpha = 1.0;

                       self.ivContainer.transform = CGAffineTransformMakeScale(1.0, 1.0);

                     }
                     completion:^(BOOL finished){

                     }];

    [UIView animateWithDuration:duration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{

                       self.apertureImageView.transform = CGAffineTransformMakeRotation(M_PI);
                       self.apertureImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
                       self.apertureImageView.alpha = 0;

                     }
                     completion:nil];

    self.firstTimeAni = NO;
}

- (void)configureFlashButton {

    // We start at the edge of the aperture button and then center the view between the aperture button and the recordModeToggleView
    NSInteger apertureEdge = self.apertureShadowView.frame.origin.x + self.apertureShadowView.frame.size.width;
    NSInteger xOrigin = apertureEdge + (self.view.frame.size.width - apertureEdge - SIDE_PAD - (ICON_WIDTH * 2)) / 2;

    NSInteger sidePad = 7;

    self.flashButton = [[UIButton alloc] initWithFrame:CGRectMake(xOrigin - sidePad, -sidePad, ICON_WIDTH + sidePad * 2, ICON_WIDTH + sidePad * 2)];
    [self.flashButton centerVerticallyInView:self.bottomClearContainer];
    [self.flashButton addDropShadowWithColor:[UIColor frescoShadowColor] path:nil];
    self.flashButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.flashButton.clipsToBounds = YES;
    //    [self.flashButton addObserver:self forKeyPath:@"highlighted" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.bottomClearContainer addSubview:self.flashButton];
    [self.flashButton addTarget:self action:@selector(flashButtonTapped) forControlEvents:UIControlEventTouchUpInside];
}

- (void)flashButtonTapped {

    if (self.captureMode == FRSCaptureModeVideo) {
        if (self.torchIsOn == NO) {
            [self torch:YES];

            [self.flashButton setImage:[UIImage imageNamed:@"torch-on"] forState:UIControlStateNormal];

        } else {
            [self torch:NO];

            [self.flashButton setImage:[UIImage imageNamed:@"torch-off"] forState:UIControlStateNormal];
        }

    } else {
        if (self.flashIsOn == NO) {
            [self flash:YES];

            [self.flashButton setImage:[UIImage imageNamed:@"flash-on"] forState:UIControlStateNormal];

        } else {
            [self flash:NO];

            [self.flashButton setImage:[UIImage imageNamed:@"flash-off"] forState:UIControlStateNormal];
        }
    }
}

- (void)torch:(BOOL)on {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        if (on) {
            [device setTorchMode:AVCaptureTorchModeOn];
            self.torchIsOn = YES;
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            self.torchIsOn = NO;
        }
        [device unlockForConfiguration];
    }
}

- (void)flash:(BOOL)on {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasFlash]) {
        [device lockForConfiguration:nil];
        if (on) {
            [device setFlashMode:AVCaptureFlashModeOn];
            self.flashIsOn = YES;
        } else {
            [device setFlashMode:AVCaptureFlashModeOff];
            self.flashIsOn = NO;
        }
        [device unlockForConfiguration];
    }
}

- (void)configureToggleView {

    self.captureModeToggleView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - (SIDE_PAD * 2) - ICON_WIDTH, self.previewBackgroundIV.frame.origin.y - 4, ICON_WIDTH + SIDE_PAD * 2, self.previewBackgroundIV.frame.size.height + 6)];
    self.captureModeToggleView.userInteractionEnabled = YES;
    [self.bottomClearContainer addSubview:self.captureModeToggleView];

    [self configureCameraButton];
    [self configureVideoButton];

    UITapGestureRecognizer *toggleGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCaptureMode)];
    [self.captureModeToggleView addGestureRecognizer:toggleGR];
}

- (void)configureCameraButton {

    //we offset the y by 2 pixels because the image has top padding on top and we want to align the content of the image.
    self.cameraIV = [[UIImageView alloc] initWithFrame:CGRectMake(SIDE_PAD, 0, ICON_WIDTH, ICON_WIDTH)];
    self.cameraIV.contentMode = UIViewContentModeCenter;
    self.cameraIV.userInteractionEnabled = YES;
    [self.cameraIV addDropShadowWithColor:[UIColor frescoShadowColor] path:nil];
    [self.captureModeToggleView addSubview:self.cameraIV];
}

- (void)configureVideoButton {

    //The ending y coordinate of the thumbnail icon minus the height of the video icon. We add because the image asset itself has bottom padding and we want to align the content of the image.
    NSInteger yOrigin = self.captureModeToggleView.frame.size.height - ICON_WIDTH + 1;

    self.videoIV = [[UIImageView alloc] initWithFrame:CGRectMake(SIDE_PAD, yOrigin, ICON_WIDTH, ICON_WIDTH)];
    self.videoIV.userInteractionEnabled = YES;
    self.videoIV.contentMode = UIViewContentModeCenter;
    [self.videoIV addDropShadowWithColor:[UIColor frescoShadowColor] path:nil];
    [self.captureModeToggleView addSubview:self.videoIV];
}

- (void)setAppropriateIconsForCaptureState {
    if (self.captureMode == FRSCaptureModePhoto) {
        [self animateShutterExpansionWithColor:[UIColor frescoOrangeColor]];

        [UIView transitionWithView:self.view
            duration:0.3
            options:UIViewAnimationOptionTransitionNone
            animations:^{

              [self.flashButton setImage:[UIImage imageNamed:@"flash-off"] forState:UIControlStateNormal];

              self.cameraIV.image = [UIImage imageNamed:@"camera-on"];
              self.videoIV.image = [UIImage imageNamed:@"video-off"];

            }
            completion:^(BOOL finished) {
              self.flashButton.layer.shadowOpacity = 0.0;
              self.cameraIV.layer.shadowOpacity = 0.0;
              self.videoIV.layer.shadowOpacity = 0.0;
            }];

    } else {
        [self animateShutterExpansionWithColor:[UIColor frescoRedColor]];

        [UIView transitionWithView:self.view
            duration:0.3
            options:UIViewAnimationOptionTransitionNone
            animations:^{

              [self.flashButton setImage:[UIImage imageNamed:@"torch-off"] forState:UIControlStateNormal];

              self.cameraIV.image = [UIImage imageNamed:@"camera-vid-off"];
              self.videoIV.image = [UIImage imageNamed:@"video-vid-on"];
            }
            completion:^(BOOL finished) {
              self.flashButton.layer.shadowOpacity = 1.0;
              self.cameraIV.layer.shadowOpacity = 1.0;
              self.videoIV.layer.shadowOpacity = 1.0;
            }];
    }
}

- (void)animateShutterExpansionWithColor:(UIColor *)color {

    self.apertureAnimationView.backgroundColor = color;
    self.apertureAnimationView.alpha = 1.0;

    [UIView animateWithDuration:0.3
        delay:0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.apertureAnimationView.transform = CGAffineTransformMakeScale(1.00, 1.00);

        }
        completion:^(BOOL finished) {
          self.apertureAnimationView.alpha = 0.0;
          self.apertureAnimationView.transform = CGAffineTransformMakeScale(0.1, 0.1);
          self.apertureAnimationView.center = self.apertureBackground.center;
          self.apertureBackground.backgroundColor = color;
          self.apertureMask.layer.borderColor = color.CGColor;
        }];
}

- (void)adjustFramesForCaptureState {

    NSInteger topToAperture = (self.bottomClearContainer.frame.size.height - self.apertureBackground.frame.size.height) / 2;
    NSInteger offset = topToAperture - 10;

    CGRect bigPreviewFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    CGRect smallPreviewFrame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width * PHOTO_FRAME_RATIO);

    //Default to video frame, shouldnt have to animate at all
    self.preview.frame = bigPreviewFrame;
    self.captureVideoPreviewLayer.frame = bigPreviewFrame;

    self.bottomOpaqueContainer.layer.shadowOpacity = 0;

    if (self.captureMode == FRSCaptureModePhoto) {

        /*UIView *snapshot = [self.preview snapshotViewAfterScreenUpdates:NO];
        [self.view addSubview:snapshot];*/

        [UIView animateWithDuration:0.3
            delay:0
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^{

              // Dispatching the animation of the preview until the next frame because we were having trouble with the animation not being synchronized well otherwise. I can't explain why this was needed but noted that things were slightly better (no black showing underneath) if the layout was done in the completion block so we made the layout happen after this one-frame delay and it seems to fix it.
              dispatch_async(dispatch_get_main_queue(), ^{
                self.preview.frame = smallPreviewFrame;
                self.captureVideoPreviewLayer.frame = smallPreviewFrame;
              });

              self.bottomOpaqueContainer.frame = CGRectMake(0, self.view.frame.size.width * PHOTO_FRAME_RATIO, self.bottomOpaqueContainer.frame.size.width, self.bottomOpaqueContainer.frame.size.height);
              self.bottomClearContainer.frame = CGRectMake(0, self.view.frame.size.width * PHOTO_FRAME_RATIO, self.bottomClearContainer.frame.size.width, self.bottomClearContainer.frame.size.height);

            }
            completion:^(BOOL finished) {
              self.apertureButton.frame = self.originalApertureFrame;
              self.bottomOpaqueContainer.layer.shadowOpacity = 1; //throw in animation block

            }];

        /*[UIView animateWithDuration:0.15 delay:0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
            
            snapshot.alpha = 0;
            
        } completion:^(BOOL finished) {
            [snapshot removeFromSuperview];
            
        }];*/

    } else {

        /*UIView *snapshot = [self.preview snapshotViewAfterScreenUpdates:NO];
        [self.view addSubview:snapshot];*/
        //
        [UIView animateWithDuration:0.3
            delay:0
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^{

              // Dispatching the animation of the preview until the next frame because we were having trouble with the animation not being synchronized well otherwise. I can't explain why this was needed but noted that things were slightly better (no black showing underneath) if the layout was done in the completion block so we made the layout happen after this one-frame delay and it seems to fix it.
              dispatch_async(dispatch_get_main_queue(), ^{
                self.preview.frame = bigPreviewFrame;
                self.captureVideoPreviewLayer.frame = bigPreviewFrame;
              });

              self.bottomOpaqueContainer.frame = CGRectMake(0, self.view.frame.size.height, self.bottomOpaqueContainer.frame.size.width, self.bottomOpaqueContainer.frame.size.height);
              self.bottomClearContainer.frame = CGRectMake(0, self.bottomClearContainer.frame.origin.y + offset, self.bottomClearContainer.frame.size.width, self.bottomClearContainer.frame.size.height);
              self.bottomOpaqueContainer.layer.shadowOpacity = 1;

              //snapshot.transform = CGAffineTransformMakeScale(0, self.bottomOpaqueContainer.frame.size.height);

            }
            completion:^(BOOL finished) {
              self.apertureButton.frame = self.originalApertureFrame;

              [UIView animateWithDuration:0.15
                                    delay:0
                                  options:UIViewAnimationOptionCurveEaseInOut
                               animations:^{

                                 //snapshot.alpha = 0;

                               }
                               completion:^(BOOL finished){
                                   //[snapshot removeFromSuperview];

                               }];

            }];
    }
}

- (void)rotateAppForOrientation:(UIDeviceOrientation)o {
    //    UIDeviceOrientation o = [UIDevice currentDevice].orientation;
    CGFloat angle = 0;
    NSInteger labelWidth = self.captureVideoPreviewLayer.frame.size.width;
    NSInteger offset = 12 + self.closeButton.frame.size.width + 17 + self.locationIV.frame.size.width + 7 + 12;
    if (o == UIDeviceOrientationLandscapeLeft) {

        if (self.captureMode == FRSCaptureModeVideo) {
            [self animateVideoRotateHide];
            self.videoRotateIV.alpha = 0.0;
            self.videoPhoneIV.alpha = 0.0;
        }

        angle = M_PI_2;
        labelWidth = self.captureVideoPreviewLayer.frame.size.height;

        if (self.assignmentLabel.text != nil) {
            [UIView animateWithDuration:0.1
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                               self.topContainer.alpha = 0;
                             }
                             completion:nil];
            [UIView animateWithDuration:0.1
                delay:0.1
                options:UIViewAnimationOptionCurveEaseInOut
                animations:^{
                  self.topContainer.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(self.view.center.x - (ICON_WIDTH), (self.view.center.x - (ICON_WIDTH))), angle);
                }
                completion:^(BOOL finished) {
                  [UIView animateWithDuration:0.1
                                        delay:0
                                      options:UIViewAnimationOptionCurveEaseInOut
                                   animations:^{
                                     self.topContainer.alpha = 1;
                                   }
                                   completion:nil];
                }];
        }

    } else if (o == UIDeviceOrientationLandscapeRight) {

        if (self.captureMode == FRSCaptureModeVideo) {
            [self animateVideoRotateHide];
            self.videoRotateIV.alpha = 0.0;
            self.videoPhoneIV.alpha = 0.0;
        }

        angle = -M_PI_2;
        labelWidth = self.captureVideoPreviewLayer.frame.size.height;

        if (self.assignmentLabel.text != nil) {
            [UIView animateWithDuration:0.1
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                               self.topContainer.alpha = 0;
                             }
                             completion:nil];
            [UIView animateWithDuration:0.1
                delay:0.1
                options:UIViewAnimationOptionCurveEaseInOut
                animations:^{
                  self.topContainer.transform = CGAffineTransformRotate((CGAffineTransformMakeTranslation(self.view.center.x - (self.view.center.x * 2) + (ICON_WIDTH), self.view.center.y - (ICON_WIDTH))), angle);
                }
                completion:^(BOOL finished) {
                  [UIView animateWithDuration:0.1
                                        delay:0
                                      options:UIViewAnimationOptionCurveEaseInOut
                                   animations:^{
                                     self.topContainer.alpha = 1;
                                   }
                                   completion:nil];
                }];
            [UIView animateWithDuration:0.1
                delay:0.1
                options:UIViewAnimationOptionCurveEaseInOut
                animations:^{

                  self.topContainer.transform = CGAffineTransformRotate((CGAffineTransformMakeTranslation(self.view.center.x - (self.view.center.x * 2) + (ICON_WIDTH), self.view.center.y - (ICON_WIDTH * 2))), angle);
                }
                completion:^(BOOL finished) {
                  [UIView animateWithDuration:0.1
                                        delay:0
                                      options:UIViewAnimationOptionCurveEaseInOut
                                   animations:^{
                                     self.topContainer.alpha = 1;
                                   }
                                   completion:nil];
                }];
        }

    } else if (o == UIDeviceOrientationPortraitUpsideDown) {
        /* no longer supported */
        labelWidth = self.captureVideoPreviewLayer.frame.size.width;
        return;

    } else if (o == UIDeviceOrientationPortrait) {

        if (self.captureMode == FRSCaptureModeVideo) {
            [self animateVideoRotationAppear];
            self.videoRotateIV.alpha = 1.0;
            self.videoPhoneIV.alpha = 0.7;
        }

        labelWidth = self.captureVideoPreviewLayer.frame.size.width;
        [UIView animateWithDuration:0.1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.topContainer.alpha = 0;
                         }
                         completion:nil];
        [UIView animateWithDuration:0.1
            delay:0.1
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^{
              self.topContainer.transform = CGAffineTransformRotate(CGAffineTransformMakeTranslation(0, 0), angle);
            }
            completion:^(BOOL finished) {
              [UIView animateWithDuration:0.1
                                    delay:0
                                  options:UIViewAnimationOptionCurveEaseInOut
                               animations:^{
                                 self.topContainer.alpha = 1;
                               }
                               completion:nil];
            }];
    } else {
        return;
    }

    [UIView beginAnimations:@"omar" context:nil];
    [UIView setAnimationDuration:0.2];

    CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);
    self.cameraIV.transform = rotation;
    self.videoIV.transform = rotation;
    self.flashButton.transform = rotation;
    self.apertureBackground.transform = rotation;
    self.previewBackgroundIV.transform = rotation;

    [UIView commitAnimations];

    self.assignmentLabel.frame = CGRectMake(12 + 24 + 17 + 22 + 7 + 7, 0, labelWidth - offset, 24);
}

- (void)animateShutterWithCompletion:(void (^)())completion {

    dispatch_async(dispatch_get_main_queue(), ^{
      [UIView animateWithDuration:0.15
                            delay:0.0
                          options:UIViewAnimationOptionCurveEaseInOut
                       animations:^{
                         self.apertureButton.transform = CGAffineTransformMakeRotation(M_PI / -2);
                       }
                       completion:nil];

      [UIView animateWithDuration:0.15
          delay:0
          options:UIViewAnimationOptionCurveEaseInOut
          animations:^{
            self.apertureButton.transform = CGAffineTransformMakeScale(4.00, 4.00);
          }
          completion:^(BOOL finished) {
            [UIView animateWithDuration:0.15
                delay:0.06
                options:UIViewAnimationOptionCurveEaseOut
                animations:^{
                  self.apertureButton.transform = CGAffineTransformMakeScale(1.00, 1.00);
                }
                completion:^(BOOL finished) {
                  self.apertureButton.frame = self.originalApertureFrame;
                }];
          }];
    });
}

#pragma mark - Button action handlers

- (void)handleApertureButtonTapped:(UIButton *)button {

    if (self.videoRotateIV.frame.origin.y != self.rotationIVOriginalY) {
        [UIView animateWithDuration:0
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                           self.videoRotateIV.frame = CGRectMake(self.videoRotateIV.frame.origin.x, self.rotationIVOriginalY, self.videoRotateIV.frame.size.width, self.videoRotateIV.frame.size.height);
                         }
                         completion:nil];
    }

    if (self.captureMode == FRSCaptureModePhoto) {

        [self captureStillImage];
    } else {
        if (self.lastOrientation == UIDeviceOrientationPortrait) {
            [self animatePhoneRotationForVideoOrientation];
        } else {
            [self toggleVideoRecording];
        }
    }
}

- (void)toggleCaptureMode {

    /* Disables torch when returning from video toggle and torch is enabled */
    [self torch:NO];

    /* Disable mask for transition animation */
    self.apertureMask.layer.borderColor = [UIColor clearColor].CGColor;

    if (self.captureMode == FRSCaptureModePhoto) {
        self.captureMode = FRSCaptureModeVideo;
        //        self.cameraDisabled = YES;
        self.apertureImageView.alpha = 1;

        /* Delay is used to change color of mask after animation completes */

        [self.sessionManager.session beginConfiguration];

        //Change the preset to display properly
        if ([self.sessionManager.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            //Set the session preset to photo, the default mode we enter in as
            [self.sessionManager.session setSessionPreset:AVCaptureSessionPresetHigh];
        }

        [self.sessionManager.session commitConfiguration];

    } else {
        self.captureMode = FRSCaptureModePhoto;

        [self animateVideoRotateHide];

        [self.sessionManager.session beginConfiguration];
        //Change the preset to display properly
        if ([self.sessionManager.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
            //Set the session preset to photo, the default mode we enter in as
            [self.sessionManager.session setSessionPreset:AVCaptureSessionPresetPhoto];
        }

        [self.sessionManager.session commitConfiguration];
    }

    [self rotateAppForOrientation:self.lastOrientation];
    [self setAppropriateIconsForCaptureState];
    [self adjustFramesForCaptureState];
    self.assignmentLabel.frame = CGRectMake(self.locationIV.frame.origin.x + self.locationIV.frame.size.width + 7, 0, self.view.frame.size.width, 24);
}

#pragma mark - Notifications and Observers

//-(void)addObservers{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateApp:) name:UIDeviceOrientationlackNotification object:nil];
//}

#pragma mark - Camera focus

- (void)handleTapToFocus:(UITapGestureRecognizer *)gr {
    CGPoint devicePoint = [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:[gr locationInView:gr.view]];

    CGPoint rawPoint = [gr locationInView:gr.view];
    [self playFocusAnimationAtPoint:rawPoint];

    [self.sessionManager focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)playFocusAnimationAtPoint:(CGPoint)devicePoint {
    UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
    circle.backgroundColor = [UIColor clearColor];
    circle.layer.borderColor = [UIColor whiteColor].CGColor;
    circle.layer.borderWidth = 2.0;
    circle.alpha = 0.0;
    circle.center = devicePoint;
    circle.layer.cornerRadius = circle.frame.size.height / 2;
    circle.clipsToBounds = YES;

    [self.preview addSubview:circle];

    [UIView animateWithDuration:0.3
        delay:0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          circle.alpha = 1.0;
          circle.transform = CGAffineTransformMakeScale(0.6, 0.6);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.3
              delay:0.0
              options:UIViewAnimationOptionCurveEaseInOut
              animations:^{
                circle.alpha = 0;
              }
              completion:^(BOOL finished) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  [circle removeFromSuperview];
                });
              }];
        }];
}

#pragma mark - Capture data processing

- (void)captureStillImage {
    dispatch_async(self.sessionManager.sessionQueue, ^{

      if (self.capturingImage)
          return;
      else {
          self.capturingImage = YES;
          self.previewButton.userInteractionEnabled = NO;
          self.nextButton.userInteractionEnabled = NO;
      }

      AVCaptureConnection *connection = [self.sessionManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];

      // Update the orientation on the still image output video connection before capturing.
      connection.videoOrientation = [self orientationFromDeviceOrientaton];

      //         Capture a still image.

      [self animateShutterWithCompletion:nil];

      [self.sessionManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection
                                                                        completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {

                                                                          CMSampleBufferRef copy = NULL;
                                                                          CMSampleBufferCreateCopy(NULL, imageDataSampleBuffer, &copy);

                                                                          if (copy) {

                                                                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ // 1
                                                                                NSData *imageNSData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:copy];

                                                                                if (imageNSData) {

                                                                                    CGImageSourceRef imgSource = CGImageSourceCreateWithData((__bridge_retained CFDataRef)imageNSData, NULL);

                                                                                    //make the metadata dictionary mutable so we can add properties to it
                                                                                    NSMutableDictionary *metadata = [(__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imgSource, 0, NULL) mutableCopy];

                                                                                    NSMutableDictionary *GPSDictionary = [[metadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary] mutableCopy];

                                                                                    if (!GPSDictionary)
                                                                                        GPSDictionary = [[[FRSLocator sharedLocator].currentLocation EXIFMetadata] mutableCopy];

                                                                                    //Add the modified Data back into the image’s metadata
                                                                                    if (GPSDictionary) {
                                                                                        [metadata setObject:GPSDictionary forKey:(NSString *)kCGImagePropertyGPSDictionary];
                                                                                    }

                                                                                    CFStringRef UTI = CGImageSourceGetType(imgSource); //this is the type of image (e.g., public.jpeg)

                                                                                    //this will be the data CGImageDestinationRef will write into
                                                                                    NSMutableData *newImageData = [NSMutableData data];

                                                                                    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)newImageData, UTI, 1, NULL);

                                                                                    if (!destination)
                                                                                        NSLog(@"***Could not create image destination ***");

                                                                                    //add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
                                                                                    CGImageDestinationAddImageFromSource(destination, imgSource, 0, (__bridge CFDictionaryRef)metadata);

                                                                                    //tell the destination to write the image data and metadata into our data object.
                                                                                    //It will return false if something goes wrong
                                                                                    BOOL success = NO;
                                                                                    success = CGImageDestinationFinalize(destination);

                                                                                    if (!success) {
                                                                                        NSLog(@"***Could not create data from image destination ***");

                                                                                        self.capturingImage = NO;
                                                                                        self.previewButton.userInteractionEnabled = YES;
                                                                                        self.nextButton.userInteractionEnabled = YES;

                                                                                        return;
                                                                                    }

                                                                                    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {

                                                                                      if (status == PHAuthorizationStatusAuthorized) {

                                                                                          // Note that creating an asset from a UIImage discards the metadata.
                                                                                          // In iOS 9, we can use -[PHAssetCreationRequest addResourceWithType:data:options].
                                                                                          // In iOS 8, we save the image to a temporary file and use +[PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:].
                                                                                          if ([PHAssetCreationRequest class]) {

                                                                                              [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{

                                                                                                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:newImageData options:nil];

                                                                                              }
                                                                                                  completionHandler:^(BOOL success, NSError *error) {

                                                                                                    if (!success) {
                                                                                                        NSLog(@"Error occurred while saving image to photo library: %@", error);
                                                                                                        self.capturingImage = NO;
                                                                                                        self.previewButton.userInteractionEnabled = YES;
                                                                                                        self.nextButton.userInteractionEnabled = YES;
                                                                                                    } else {
                                                                                                        [self updatePreviewButtonWithImage:[UIImage imageWithData:newImageData scale:.1]];
                                                                                                        self.capturingImage = NO;
                                                                                                        self.previewButton.userInteractionEnabled = YES;
                                                                                                        self.nextButton.userInteractionEnabled = YES;
                                                                                                    }
                                                                                                  }];
                                                                                          } else {

                                                                                              NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
                                                                                              NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];

                                                                                              NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];

                                                                                              [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{

                                                                                                NSError *error = nil;

                                                                                                [newImageData writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];

                                                                                                if (error) {
                                                                                                    NSLog(@"Error occured while writing image data to a temporary file: %@", error);
                                                                                                } else {
                                                                                                    [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:temporaryFileURL];
                                                                                                }

                                                                                              }
                                                                                                  completionHandler:^(BOOL success, NSError *error) {

                                                                                                    if (!success) {
                                                                                                        NSLog(@"Error occurred while saving image to photo library: %@", error);
                                                                                                    } else {
                                                                                                        [self updatePreviewButtonWithImage:[UIImage imageWithData:newImageData scale:.1]];
                                                                                                    }

                                                                                                    self.capturingImage = NO;
                                                                                                    self.previewButton.userInteractionEnabled = YES;
                                                                                                    self.nextButton.userInteractionEnabled = YES;

                                                                                                    // Delete the temporary file.
                                                                                                    [[NSFileManager defaultManager] removeItemAtURL:temporaryFileURL error:nil];

                                                                                                  }];
                                                                                          }
                                                                                      }
                                                                                    }];
                                                                                } else {
                                                                                    NSLog(@"Could not capture still image: %@", error);
                                                                                }
                                                                              });
                                                                          } else {
                                                                              NSLog(@"Could not capture still image: %@", error);
                                                                          }
                                                                        }];
    });
}

- (void)stopVideoCaptureIfNeeded {
    if (!self.sessionManager.movieFileOutput.isRecording)
        return;
    [self toggleVideoRecording];
}

- (void)animateCloseButtonHide:(BOOL)shouldHide {

    if (shouldHide) {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{

                           self.closeButton.alpha = 0;

                         }
                         completion:nil];
    } else {
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{

                           self.closeButton.alpha = 1;

                         }
                         completion:nil];
    }
}

- (void)toggleVideoRecording {

    if (self.sessionManager.movieFileOutput.isRecording) {

        //Clear the timer so it doesn't re-run
        [self.videoTimer invalidate];
        self.videoTimer = nil;

        [self stopRecordingAnimation];
        self.previewBackgroundIV.alpha = 1.0;
        [self createNextButtonWithFrame:self.previewButton.frame];
        [self.previewBackgroundIV addSubview:self.nextButton];
        [self animateCloseButtonHide:NO];
    } else {
        self.videoTimer = [NSTimer scheduledTimerWithTimeInterval:maxVideoLength target:self selector:@selector(videoEnded:) userInfo:nil repeats:NO];
        [self animateCloseButtonHide:YES];
    }

    dispatch_async(self.sessionManager.sessionQueue, ^{

      if (!self.sessionManager.movieFileOutput.isRecording) {

          AVCaptureConnection *movieConnection = [self.sessionManager.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];

          if (!movieConnection) {
              [self.sessionManager.session beginConfiguration];

              if ([self.sessionManager.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                  //Set the session preset to photo, the default mode we enter in as
                  [self.sessionManager.session setSessionPreset:AVCaptureSessionPresetHigh];
              }

              [self.sessionManager.session commitConfiguration];
          }

          movieConnection = [self.sessionManager.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];

          if (movieConnection.active) {

              AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
              item.keySpace = AVMetadataKeySpaceCommon;
              item.key = AVMetadataCommonKeyLocation;
              item.value = [NSString
                            stringWithFormat:@"%+08.4lf%+09.4lf/",
                            [FRSLocator sharedLocator].currentLocation.coordinate.latitude,
                            [FRSLocator sharedLocator].currentLocation.coordinate.longitude];
              self.sessionManager.movieFileOutput.metadata = @[ item ];

              if ([UIDevice currentDevice].isMultitaskingSupported) {
                  // Setup background task. This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
                  // callback is not received until AVCam returns to the foreground unless you request background execution time.
                  // This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                  // To conclude this background execution, -endBackgroundTask is called in
                  // -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
                  self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
              }

              // Update the orientation on the movie file output video connection before starting recording.
              AVCaptureConnection *connection = [self.sessionManager.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
              connection.videoOrientation = [self orientationFromDeviceOrientaton];

              // Start recording to a temporary file.
              NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
              NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
              [self.sessionManager.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
              //                [self.sessionManager.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
              self.isRecording = TRUE;
              dispatch_async(dispatch_get_main_queue(), ^{
                [self runVideoRecordAnimation];
              });
          }

      } else {
          [self.sessionManager.movieFileOutput stopRecording];
      }
    });
}

- (void)videoEnded:(NSTimer *)timer {
    [self toggleVideoRecording];
}

#pragma mark - File Output Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    // Note that currentBackgroundRecordingID is used to end the background task associated with this recording.
    // This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's isRecording property
    // is back to NO — which happens sometime after this method returns.
    // Note: Since we use a unique file path for each recording, a new recording will not overwrite a recording currently being saved.
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;

    dispatch_block_t cleanup = ^{
      [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
      if (currentBackgroundRecordingID != UIBackgroundTaskInvalid) {
          [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
      }
    };
    self.isRecording = FALSE;
    BOOL success = YES;

    if (error) {
        NSLog(@"Movie file finishing error: %@", error);
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    if (success) {
        // Check authorization status.
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
          if (status == PHAuthorizationStatusAuthorized) {
              // Save the movie file to the photo library and cleanup.
              [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                // In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
                // This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
                if ([PHAssetResourceCreationOptions class]) {
                    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                    options.shouldMoveFile = YES;
                    PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
                } else {
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
                }
              }
                  completionHandler:^(BOOL success, NSError *error) {
                    if (!success) {
                        NSLog(@"Could not save movie to photo library: %@", error);
                    }

                    //                    [[FRSGalleryAssetsManager sharedManager] fetchGalleryAssetsInBackgroundWithCompletion:^{
                    //                        PHAsset *asset = [[FRSGalleryAssetsManager sharedManager].fetchResult firstObject];
                    //
                    //                        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:self.previewBackgroundIV.frame.size contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
                    //
                    //                            [self updatePreviewButtonWithImage:result];
                    //                        }];
                    //
                    //                        cleanup();
                    //                    }];

                  }];
          } else {
              cleanup();
          }
        }];
    } else {
        cleanup();
    }
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateLocationLabelWithAssignment:(FRSAssignment *)assignment {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!assignment.title)
          return;
      self.assignmentLabel.text = [assignment.title uppercaseString];
      self.assignmentLabel.frame = CGRectMake(self.locationIV.frame.origin.x + self.locationIV.frame.size.width + 7, 0, [self assignmentLabelWidth], 24);

      [UIView animateWithDuration:0.15
                       animations:^{
                         self.locationIV.alpha = 1.0;
                         self.assignmentLabel.alpha = 1.0;
                       }];
    });
}

- (void)runVideoRecordAnimation {
    self.captureModeToggleView.alpha = 0.0;

    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.apertureButton.transform = CGAffineTransformMakeRotation(M_PI / -2);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.apertureButton.transform = CGAffineTransformMakeScale(4.00, 4.00);
                     }
                     completion:nil];

    self.previewBackgroundIV.alpha = 0.0;

    int radius = 30;
    self.circleLayer = [CAShapeLayer layer];
    // Make a circular shape

    self.circleLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0 * radius, 2.0 * radius)
                                                       cornerRadius:radius]
                                .CGPath;

    self.circleLayer.position = CGPointMake(CGRectGetMidX(self.apertureBackground.frame) - 30, 6);

    // Configure the apperence of the circle
    self.circleLayer.fillColor = [UIColor clearColor].CGColor;
    self.circleLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.circleLayer.lineWidth = 4;

    // Add to parent layer
    [self.apertureBackground.layer addSublayer:self.circleLayer];

    // Configure animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drawAnimation.duration = maxVideoLength; // for testing purposes
    drawAnimation.repeatCount = 1.0; // Animate only once..

    // Animate from no part of the stroke being drawn to the entire stroke being drawn
    drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    drawAnimation.toValue = [NSNumber numberWithFloat:1.0f];

    // Experiment with timing to get the appearence to look the way you want
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];

    // Add the animation to the circle
    [self.circleLayer addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
}

- (void)stopRecordingAnimation {

    dispatch_async(dispatch_get_main_queue(), ^{

      [UIView animateWithDuration:0.15
          delay:0.0
          options:UIViewAnimationOptionCurveEaseOut
          animations:^{

            self.circleLayer.opacity = 0;

            self.apertureButton.alpha = 1;
            self.apertureButton.transform = CGAffineTransformMakeScale(1.000, 1.000);

          }
          completion:^(BOOL finished) {
            [self.circleLayer removeFromSuperlayer];

          }];

      [UIView animateWithDuration:0.2
          delay:0.0
          options:UIViewAnimationOptionCurveEaseInOut
          animations:^{

            self.apertureButton.transform = CGAffineTransformMakeRotation(M_PI);

          }
          completion:^(BOOL finished) {
            self.captureModeToggleView.alpha = 1.0;
          }];
    });
}

#pragma mark - FRSLocater Delegate

- (void)locationChanged:(CLLocation *)newLocation {
//    [[FRSAPICLient sharedManager] getAssignmentsWithinRadius:[[FRSDataManager sharedManager].currentUser.notificationRadius integerValue] ofLocation:newLocation.coordinate withResponseBlock:^(id responseObject, NSError *error) {
//
//        if([responseObject firstObject] != nil){
//
//            FRSAssignment *assignment = [responseObject firstObject];
//
//            CGFloat distanceInMiles = [[FRSLocationManager sharedManager].location distanceFromLocation:assignment.locationObject] / kMetersInAMile;
//
//            //Check if in range
//            if(distanceInMiles < [assignment.radius floatValue]){
//
//                [self updateLocationLabelWithAssignment:assignment];
//
//            }
//        }
//    }];
}



#pragma mark - Navigation

- (void)handlePreviewButtonTapped {
    if (!self.didPush) {

        if (self.sessionManager.movieFileOutput.isRecording) {
            [self toggleVideoRecording];
        }

        FRSFileViewController *fileView = [[FRSFileViewController alloc] initWithNibName:Nil bundle:Nil];
        fileView.preselectedGlobalAssignment = self.preselectedGlobalAssignment;
        fileView.preselectedAssignment = self.preselectedAssignment;
        fileView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

        [self.navigationController pushViewController:fileView animated:YES];
    }
    self.didPush = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (AVCaptureVideoOrientation)orientationFromDeviceOrientaton {
    switch (self.lastOrientation) {
    case UIDeviceOrientationLandscapeLeft:
        return AVCaptureVideoOrientationLandscapeRight;
        break;
    case UIDeviceOrientationLandscapeRight:
        return AVCaptureVideoOrientationLandscapeLeft;
        break;
    case UIDeviceOrientationPortrait:
        return AVCaptureVideoOrientationPortrait;
    default:
        return AVCaptureVideoOrientationPortrait;
    }
}

#pragma mark - Orientation

- (void)startTrackingMovement {

    self.motionManager.accelerometerUpdateInterval = .2;
    self.motionManager.gyroUpdateInterval = .2;

    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                               if (!error) {
                                                   [self outputAccelertionData:accelerometerData.acceleration];

                                               } else {
                                                   NSLog(@"Motion Manager Error: %@", error);
                                               }
                                             }];

    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.gyroUpdateInterval = 2;
    }

    __block float lastZ = 0;
    __block float lastY = 0;

    [_motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
                                withHandler:^(CMGyroData *_Nullable gyroData, NSError *_Nullable error) {
                                  CGFloat rotationRate = fabs(gyroData.rotationRate.x);
                                  if (rotationRate > .4) {
                                      [self alertUserOfFastPan:TRUE];
                                  }

                                  CGFloat wobbleRate = fabs(gyroData.rotationRate.z);
                                  if (lastZ == 0) {
                                      lastZ = wobbleRate;
                                  } else if (lastZ - wobbleRate < -.7) {
                                      [self alertUserOfWobble:YES];
                                  }

                                  CGFloat forwardWobble = fabs(gyroData.rotationRate.y);
                                  if (lastY == 0) {
                                      lastY = forwardWobble;
                                  } else if (lastY - forwardWobble < -1) {
                                      [self alertUserOfWobble:YES];
                                  }

                                }];
}

- (void)outputAccelertionData:(CMAcceleration)acceleration {

    UIDeviceOrientation orientationNew;

    if (self.sessionManager.movieFileOutput.isRecording)
        return;

    if (acceleration.z > -2 && acceleration.z < 2) {

        if (acceleration.x >= 0.75) {
            orientationNew = UIDeviceOrientationLandscapeRight;

        } else if (acceleration.x <= -0.75) {
            orientationNew = UIDeviceOrientationLandscapeLeft;

        } else if (acceleration.y <= -0.75) {
            orientationNew = UIDeviceOrientationPortrait;

        } else if (acceleration.y >= 0.75) {
            orientationNew = self.lastOrientation;
        } else {
            // Consider same as last time
            return;
        }
    }

    if (orientationNew == self.lastOrientation)
        return;

    self.lastOrientation = orientationNew;

    [self rotateAppForOrientation:orientationNew];
}

- (void)alertUserOfFastPan:(BOOL)isTooFast {

    [self showPan];

    if (wobble && [wobble isValid]) {
        [wobble invalidate];
    }

    wobble = [NSTimer timerWithTimeInterval:.5 target:self selector:@selector(hideAlert) userInfo:Nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:wobble forMode:NSDefaultRunLoopMode];
}

- (void)alertUserOfWobble:(BOOL)isTooFast {

    [self showWobble];

    if (wobble && [wobble isValid]) {
        [wobble invalidate];
    }

    wobble = [NSTimer timerWithTimeInterval:.5 target:self selector:@selector(hideAlert) userInfo:Nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:wobble forMode:NSDefaultRunLoopMode];
}

- (void)showPan {

    if (!hasPanned) {
        hasPanned = TRUE;
        [FRSTracker track:aggressivePan];
    }

    if (_isRecording == FALSE) {
        return;
    }

    if (isShowingPan) {
        return;
    }

    isShowingPan = TRUE;

    panAlert = [[FRSWobbleView alloc] init];
    CGAffineTransform transform;

    if (self.lastOrientation == UIDeviceOrientationLandscapeLeft) {
        // 90 degrees
        double rads = DEGREES_TO_RADIANS(90);
        transform = CGAffineTransformRotate(panAlert.transform, rads);

        panAlert.transform = transform;

        CGRect shakeFrame = panAlert.frame;
        shakeFrame.origin.x += self.view.frame.size.width - (panAlert.frame.size.height / 2) - 33;
        shakeFrame.origin.y += 120;

        if (isShowingWobble) {
            shakeFrame.origin.x -= 50;
        }

        shakeFrame.origin.y = ((self.view.frame.size.height - shakeFrame.size.width) / 2) - 120 + (shakeFrame.size.width) + 25;
        panAlert.frame = shakeFrame;
        panAlert.alpha = 0;
        [self.view addSubview:panAlert];

        [UIView animateWithDuration:.3
                         animations:^{
                           panAlert.alpha = 1;
                         }];

        [self.view bringSubviewToFront:panAlert];
    } else if (self.lastOrientation == UIDeviceOrientationLandscapeRight) {
        double rads = DEGREES_TO_RADIANS(-90);
        transform = CGAffineTransformRotate(panAlert.transform, rads);
        panAlert.transform = transform;

        CGRect shakeFrame = panAlert.frame;
        shakeFrame.origin.x = 15;
        shakeFrame.origin.y += 120;

        if (isShowingWobble) {
            shakeFrame.origin.x += 50;
        }

        shakeFrame.origin.y = ((self.view.frame.size.height - shakeFrame.size.width) / 2) - 120 + (shakeFrame.size.width) + 25;
        panAlert.frame = shakeFrame;
        panAlert.alpha = 0;
        [self.view addSubview:panAlert];

        [UIView animateWithDuration:.3
                         animations:^{
                           panAlert.alpha = 1;
                         }];

        [self.view bringSubviewToFront:panAlert];
    }
}

- (void)showWobble {

    if (!hasShaken) {
        hasShaken = TRUE;
        [FRSTracker track:captureWobble];
    }

    if (_isRecording == FALSE) {
        return;
    }

    if (isShowingWobble) {
        return;
    }

    isShowingWobble = TRUE;

    shakeAlert = [[FRSWobbleView alloc] init];
    [shakeAlert configureForWobble];
    CGAffineTransform transform;

    if (self.lastOrientation == UIDeviceOrientationLandscapeLeft) {
        // 90 degrees
        double rads = DEGREES_TO_RADIANS(90);
        transform = CGAffineTransformRotate(shakeAlert.transform, rads);

        shakeAlert.transform = transform;

        CGRect shakeFrame = shakeAlert.frame;
        shakeFrame.origin.x += self.view.frame.size.width - (shakeAlert.frame.size.height / 2) - 33;
        shakeFrame.origin.y += 120;

        if (isShowingPan) {
            shakeFrame.origin.x -= 50;
        }

        shakeFrame.origin.y = ((self.view.frame.size.height - shakeFrame.size.width) / 2) - 120;
        shakeAlert.frame = shakeFrame;
        shakeAlert.alpha = 0;
        [self.view addSubview:shakeAlert];

        [UIView animateWithDuration:.3
                         animations:^{
                           shakeAlert.alpha = 1;
                         }];

        [self.view bringSubviewToFront:shakeAlert];
    } else if (self.lastOrientation == UIDeviceOrientationLandscapeRight) {
        double rads = DEGREES_TO_RADIANS(-90);
        transform = CGAffineTransformRotate(shakeAlert.transform, rads);
        shakeAlert.transform = transform;

        CGRect shakeFrame = shakeAlert.frame;
        shakeFrame.origin.x = 15;
        shakeFrame.origin.y += 120;

        if (isShowingPan) {
            shakeFrame.origin.x += 50;
        }

        shakeFrame.origin.y = ((self.view.frame.size.height - shakeFrame.size.width) / 2) - 120;
        shakeAlert.frame = shakeFrame;
        shakeAlert.alpha = 0;
        [self.view addSubview:shakeAlert];

        [UIView animateWithDuration:.3
                         animations:^{
                           shakeAlert.alpha = 1;
                         }];

        [self.view bringSubviewToFront:shakeAlert];
    }
}

- (void)hideAlert {
    dispatch_async(dispatch_get_main_queue(), ^{
      [UIView animateWithDuration:0.3
          delay:0.0
          options:UIViewAnimationOptionCurveEaseInOut
          animations:^{
            shakeAlert.alpha = 0;
            panAlert.alpha = 0;
          }
          completion:^(BOOL finished) {
            [shakeAlert removeFromSuperview];
            [panAlert removeFromSuperview];

            shakeAlert = Nil;
            panAlert = Nil;
            isShowingWobble = FALSE;
            isShowingPan = FALSE;
          }];
    });
}

- (void)configureAlertWithText:(NSString *)text {
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

    if (self.isRecording == FALSE) {
        return;
    }

    if (!self.alertContainer) {
        self.alertContainer = [[UIView alloc] initWithFrame:CGRectMake(35, self.view.frame.size.height / 2 - 20, self.view.frame.size.height, 40)];
        self.alertContainer.backgroundColor = [UIColor frescoRedColor];
        self.alertContainer.alpha = 0;
        [self.view addSubview:self.alertContainer];

        title = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.view.frame.size.height, 20)];
        title.text = text;
        title.textColor = [UIColor whiteColor];
        title.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        title.textAlignment = NSTextAlignmentCenter;

        [self.alertContainer addSubview:title];

        CGAffineTransform transform;

        if (self.lastOrientation == UIDeviceOrientationLandscapeLeft) {
            // 90 degrees
            double rads = DEGREES_TO_RADIANS(90);
            transform = CGAffineTransformRotate(self.alertContainer.transform, rads);
        } else if (self.lastOrientation == UIDeviceOrientationLandscapeRight) {
            double rads = DEGREES_TO_RADIANS(-90);
            CGAffineTransformRotate(self.alertContainer.transform, rads);
        }

        self.alertContainer.transform = transform;

        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.alertContainer.alpha = 8;

                         }
                         completion:^(BOOL finished){

                         }];

    } else {
        title.text = text;

        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.alertContainer.alpha = 8;

                         }
                         completion:^(BOOL finished){

                         }];
    }
}

@end
