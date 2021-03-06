//
//  FRSAssignmentsViewController.m
//  Fresco
//
//  Created by Fresco News on 1/11/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSAssignmentsViewController.h"
#import "FRSTabBarController.h"
#import "FRSCameraViewController.h"
#import "FRSAssignment.h"
#import "FRSDateFormatter.h"
#import "FRSMapCircle.h"
#import "FRSAssignmentAnnotation.h"
#import "UITextView+Resize.h"
#import "FRSGlobalAssignmentsTableViewController.h"
#import "Haneke.h"
#import "FRSAlertView.h"
#import "DGElasticPullToRefreshLoadingViewCircle.h"
#import "FRSAuthManager.h"
#import "FRSUserManager.h"
#import "FRSAssignmentManager.h"
#import "FRSAssignmentTracker.h"
#import "CLLocation+Fresco.h"

@import MapKit;

@interface FRSAssignmentsViewController () <MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, FRSAlertViewDelegate> {
    NSMutableArray *dictionaryRepresentations;
    BOOL hasSnapped;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *globalAssignmentsBottomContainer;
@property (weak, nonatomic) IBOutlet UILabel *globalAssignmentsLabel;

@property (nonatomic) BOOL isFetching;
@property (nonatomic, retain) NSMutableArray *assignmentIDs;
@property (strong, nonatomic) FRSMapCircle *userCircle;
@property (nonatomic, retain) NSMutableArray *outletImagesViews;
@property (strong, nonatomic) NSArray *assignments;
@property (strong, nonatomic) NSArray *overlays;
@property (strong, nonatomic) NSArray *outlets;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *dismissView;
@property (strong, nonatomic) UIView *assignmentBottomBar;
@property (strong, nonatomic) NSString *assignmentTitle;
@property (strong, nonatomic) NSString *assignmentOutlet;
@property (strong, nonatomic) NSString *assignmentCaption;
@property (strong, nonatomic) NSDate *assignmentExpirationDate;
@property (strong, nonatomic) NSDate *assignmentPostedDate;
@property (strong, nonatomic) UILabel *assignmentTitleLabel;
@property (strong, nonatomic) UILabel *assignmentOutletLabel;
@property (strong, nonatomic) UITextView *assignmentTextView;
@property (strong, nonatomic) UIView *assignmentCard;
@property (strong, nonatomic) UILabel *expirationLabel;
@property (strong, nonatomic) UILabel *distanceLabel;
@property (strong, nonatomic) UILabel *photoCashLabel;
@property (strong, nonatomic) UILabel *videoCashLabel;

@property (strong, nonatomic) NSArray *globalAssignmentsArray;
@property (strong, nonatomic) UIView *assignmentStatsContainer;
@property (strong, nonatomic) FRSAssignment *currentAssignment;
@property (strong, nonatomic) UILabel *postedLabel;
@property (strong, nonatomic) UIButton *navigateButton;
@property (strong, nonatomic) NSString *assignmentID;
@property (strong, nonatomic) UIView *greenView;
@property (strong, nonatomic) UIButton *unacceptAssignmentButton;
@property (strong, nonatomic) UIButton *assignmentActionButton;
@property (strong, nonatomic) NSString *assignemntAcceptButtonTitle;
@property (strong, nonatomic) UILabel *acceptAssignmentDistanceAwayLabel;
@property (strong, nonatomic) UILabel *acceptAssignmentTimeRemainingLabel;
@property (strong, nonatomic) FRSAlertView *expiredAssignmentAlert;
@property (strong, nonatomic) UIView *annotationColorView;
@property (strong, nonatomic) FRSAssignment *acceptedAssignment;
@property (strong, nonatomic) DGElasticPullToRefreshLoadingViewCircle *spinner;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDictionary *acceptedAssignmentDictionary;

@property BOOL didAcceptAssignment;
@property BOOL assignmentDidExpire;
@property BOOL userIsInRange;
@property BOOL shouldRefreshMap;
@property BOOL isCheckingForAcceptedAssignment;
@property BOOL seguedToGlobalAssignment;

@end

@implementation FRSAssignmentsViewController

static NSString *const ACTION_TITLE_ONE = @"ACCEPT";
static NSString *const ACTION_TITLE_TWO = @"OPEN CAMERA";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureMap];
    [self configurePanGestureRec];

    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveLocationUpdate:)
                                                 name:FRSLocationUpdateNotification
                                               object:nil];

    self.assignmentIDs = [[NSMutableArray alloc] init];

    self.assignmentCardIsOpen = NO;
    self.mapShouldFollowUser = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tabBarController.navigationController setNavigationBarHidden:YES];

    [FRSTracker screen:@"Assignments"];

    self.isPresented = YES;

    self.navigationItem.title = @"ASSIGNMENTS";
    [self.navigationController.navigationBar setTitleTextAttributes:
                                                 @{ NSForegroundColorAttributeName : [UIColor whiteColor], NSFontAttributeName : [UIFont notaBoldWithSize:17] }];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    [self removeNavigationBarLine];

    FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!delegate.didPresentPermissionsRequest) { //Avoid double alerts
        [self checkStatusAndPresentPermissionsAlert];
    }

    if (![[FRSAuthManager sharedInstance] isAuthenticated]) {
        if (self.didAcceptAssignment) {
            [self configureUnacceptedAssignment];
        }
    }

    [self checkForAcceptedAssignment];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([FRSLocator sharedLocator].currentLocation) {
        [self locationUpdate:[FRSLocator sharedLocator].currentLocation];
    }

    //If the VC is presented and a selected assignment is set, present that assignment to the user
    //by either pushing the global assignment controller or presenting it on the map
    if (self.selectedAssignment) {
        if ([self.selectedAssignment.latitude isEqual:@0] && [self.selectedAssignment.longitude isEqual:@0]) {
            [self globalAssignmentsSegue];
        } else {
            [self setDefaultAssignment:self.selectedAssignment];
        }

        self.selectedAssignment = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.hasDefault = NO;
    self.defaultID = nil;

    if (self.closeButton) {
        self.closeButton.alpha = 0;
    }

    if (self.seguedToGlobalAssignment) {
        self.seguedToGlobalAssignment = false;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.isPresented = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    if (self.assignmentCardIsOpen) {
        return;
    }

    if (self.didAcceptAssignment) {
        [self updateUIForLocation];
    }

    if (self.didAcceptAssignment && self.mapShouldFollowUser) {
        [self.mapView showAnnotations:self.mapView.annotations animated:YES];
        return;
    }

    if (self.mapShouldFollowUser) {
        [self.mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
    }
}

- (void)configureMap {
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)checkForAcceptedAssignment {
    if (self.isCheckingForAcceptedAssignment) {
        return;
    }
    self.isCheckingForAcceptedAssignment = YES;
    
    if([[FRSAuthManager sharedInstance] isAuthenticated]) {
        [[FRSAssignmentManager sharedInstance] getAcceptedAssignmentWithCompletion:^(id responseObject, NSError *error) {
          self.isCheckingForAcceptedAssignment = NO;
          if (responseObject) {
              FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
              FRSAssignment *assignment = [NSEntityDescription insertNewObjectForEntityForName:@"FRSAssignment" inManagedObjectContext:delegate.managedObjectContext];
              [assignment configureWithDictionary:responseObject];
              self.acceptedAssignmentDictionary = assignment;
              self.assignmentID = assignment.uid;
              self.acceptedAssignment = assignment;
              self.currentAssignment = assignment;
              [self configureAcceptedAssignment:assignment];
          }
        }];
    }
}

- (void)fetchAssignmentsNearLocation:(CLLocation *)location radius:(NSInteger)radii {
    if (self.didAcceptAssignment) {
        return;
    }

    if (self.isFetching)
        return;

    self.isFetching = YES;

    [self checkForAcceptedAssignment];

    [[FRSAssignmentManager sharedInstance] getAssignmentsWithinRadius:radii
                                                           ofLocation:@[ @(location.coordinate.longitude), @(location.coordinate.latitude) ]
                                                       withCompletion:^(id responseObject, NSError *error) {
                                                         NSArray *assignments = (NSArray *)responseObject[@"nearby"];
                                                         NSArray *globalAssignments = (NSArray *)responseObject[@"global"];

                                                         FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                         NSMutableArray *mSerializedAssignments = [NSMutableArray new];

                                                         if (globalAssignments.count > 0) {
                                                             if (self.defaultID) {
                                                                 [self showGlobalAssignmentsBar];
                                                             }
                                                             if (globalAssignments.count > 1) {
                                                                 self.globalAssignmentsLabel.text = [NSString stringWithFormat:@"%lu global assignments", (unsigned long)globalAssignments.count];
                                                             } else {
                                                                 self.globalAssignmentsLabel.text = [NSString stringWithFormat:@"%lu global assignment", (unsigned long)globalAssignments.count];
                                                             }
                                                         }

                                                         self.globalAssignmentsArray = [globalAssignments copy];

                                                         if (self.globalAssignmentsArray.count >= 1) {
                                                             [self showGlobalAssignmentsBar];
                                                         }

                                                         FRSAssignment *defaultAssignment;

                                                         if (assignments.count > 0) {
                                                             for (NSDictionary *dict in assignments) {
                                                                 FRSAssignment *assignmentToAdd = [NSEntityDescription insertNewObjectForEntityForName:@"FRSAssignment" inManagedObjectContext:delegate.managedObjectContext];
                                                                 [assignmentToAdd configureWithDictionary:dict];
                                                                 NSString *uid = assignmentToAdd.uid;

                                                                 if ([uid isEqualToString:self.defaultID]) {
                                                                     defaultAssignment = assignmentToAdd;
                                                                 }

                                                                 if ([self assignmentExists:uid]) {
                                                                     continue;
                                                                 }

                                                                 [mSerializedAssignments addObject:assignmentToAdd];

                                                                 if (!dictionaryRepresentations) {
                                                                     dictionaryRepresentations = [[NSMutableArray alloc] init];
                                                                 }

                                                                 [dictionaryRepresentations addObject:dict];
                                                             }

                                                             self.assignments = [mSerializedAssignments copy];
                                                         }

                                                         [self addAnnotationsForAssignments];

                                                         self.isFetching = NO;

                                                         if (!notFirstFetch) {
                                                             notFirstFetch = TRUE;
                                                             [self cacheAssignments];
                                                         }

                                                         [self addAnnotationsForAssignments];
                                                         [delegate.managedObjectContext save:Nil];
                                                         [delegate saveContext];

                                                         if (self.defaultID && defaultAssignment) {
                                                             [self setDefaultAssignment:defaultAssignment];
                                                         }

                                                         if (self.acceptedAssignment) {
                                                             self.assignmentID = self.acceptedAssignment.uid;
                                                             [self configureAcceptedAssignment:self.acceptedAssignment];
                                                             [self setDefaultAssignment:self.acceptedAssignment];
                                                         }
                                                       }];
}

- (BOOL)location:(CLLocation *)location isWithinAssignmentRadius:(FRSAssignment *)assignment {
    NSNumber *assignmentRadius = assignment.radius;
    float milesRadius = [assignmentRadius floatValue];

    if ([CLLocation calculatedDistanceFromAssignment:assignment] < milesRadius) {
        return TRUE;
    }

    return FALSE;
}

- (BOOL)assignmentExists:(NSString *)assignment {
    __block BOOL returnValue = FALSE;

    [self.assignmentIDs enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
      NSString *currentID = (NSString *)obj;

      if ([currentID isEqualToString:assignment]) {
          returnValue = TRUE;
      }
    }];

    return returnValue;
}

- (void)cacheAssignments {
}

#pragma mark - Region

// gets called when user taps on map icon in tab bar
- (void)setInitialMapRegion {
    // disable snap if already tracking
    if (self.mapShouldFollowUser) {
        // zoom in only if tracking user
        if (!self.didAcceptAssignment) {
            MKCoordinateRegion mapRegion;
            mapRegion.center = self.mapView.userLocation.coordinate;
            mapRegion.span.latitudeDelta = 0.002;
            mapRegion.span.longitudeDelta = 0.002;
            [self.mapView setRegion:mapRegion animated:YES];
        }
        return;
    }

    // disable snap if viewing assignment
    if (self.assignmentCardIsOpen) {
        return;
    }

    if (self.didAcceptAssignment) {
        // show both accepted assignment and user annotation
        [self.mapView showAnnotations:self.mapView.annotations animated:YES];
        return;
    }

    // default snap map cam to user behavior
    if ([FRSLocator sharedLocator].currentLocation) {
        [self adjustMapRegionWithLocation:[FRSLocator sharedLocator].currentLocation];
    }
}

- (void)adjustMapRegionWithLocation:(CLLocation *)location {

    // if user accepted assignment, keep assignment and user annotations on map
    if (self.didAcceptAssignment) {
        [self.mapView showAnnotations:self.mapView.annotations animated:YES];
        return;
    }

    MKCoordinateSpan currentSpan = MKCoordinateSpanMake(0.03f, 0.03f);
    MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude), currentSpan);

    if (self.defaultID) {
        region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([self.currentAssignment.latitude doubleValue], [self.currentAssignment.longitude doubleValue]), currentSpan);
    }

    [self.mapView setRegion:region animated:YES];
}

#pragma mark - Annotations

- (void)addAnnotationsForAssignments {

    if (self.didAcceptAssignment) {
        // avoid drawing mutliple
        if ([self.mapView.annotations count] <= 1 && self.currentAssignment.uid) {
            [self.assignmentIDs addObject:self.currentAssignment.uid];
            [self addAssignmentAnnotation:self.currentAssignment index:0];
        }
        return;
    }

    NSInteger count = 0;

    for (FRSAssignment *assignment in self.assignments) {

        if ([self assignmentExists:assignment.uid]) {
            continue;
        }

        [self.assignmentIDs addObject:assignment.uid];
        [self addAssignmentAnnotation:assignment index:count];

        count++;
    }
}

- (void)removeAssignmentsFromMap {
    id userLocation = [self.mapView userLocation];
    NSMutableArray *assignments = [[NSMutableArray alloc] initWithArray:[self.mapView annotations]];
    if (userLocation != nil) {
        [assignments removeObject:userLocation]; // avoid removing user location off the map
    }

    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[FRSMapCircle class]]) {
            [assignments removeObject:annotation];
        }
    }

    [self.mapView removeAnnotations:assignments];
    assignments = nil;
}

- (void)addAssignmentAnnotation:(FRSAssignment *)assignment index:(NSInteger)index {
    FRSAssignmentAnnotation *ann = [[FRSAssignmentAnnotation alloc] initWithAssignment:assignment atIndex:index];
    // create center coordinate for the assignment
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([assignment.latitude floatValue], [assignment.longitude floatValue]);

    // create MKCircle surroudning the annotation
    CLLocationDistance distance = [assignment.radius floatValue] * metersInAMile;
    FRSMapCircle *circle = [FRSMapCircle circleWithCenterCoordinate:coord radius:distance];
    circle.circleType = FRSMapCircleTypeAssignment;
    ann.outlets = assignment.outlets;

    [self.mapView addOverlay:circle];
    [self.mapView addAnnotation:ann];

    [self setDefaultAssignment:assignment];
}

// used when coming in from another view controller
- (void)setDefaultAssignment:(FRSAssignment *)assignment {

    if (self.hasDefault && [assignment.uid isEqualToString:self.defaultID]) {

        self.assignmentLat = [assignment.latitude floatValue];
        self.assignmentLong = [assignment.longitude floatValue];

        self.assignmentCardIsOpen = YES;

        self.assignmentTitle = assignment.title;
        self.assignmentCaption = assignment.caption;
        self.assignmentExpirationDate = assignment.expirationDate;
        self.assignmentPostedDate = assignment.createdDate;

        self.assignmentID = assignment.uid;

        self.outlets = assignment.outlets;

        if (![assignment.acceptable boolValue]) {
            self.assignemntAcceptButtonTitle = ACTION_TITLE_TWO;
        } else {
            self.assignemntAcceptButtonTitle = ACTION_TITLE_ONE;
        }

        if (self.didAcceptAssignment) {
            self.assignemntAcceptButtonTitle = ACTION_TITLE_TWO;
        }

        [self setExpiration:self.assignmentExpirationDate days:0 hours:0 minutes:0 seconds:0];
        [self setPostedDate];

        [self configureOutlets];
        [self configureAssignmentCard];
        [self animateAssignmentCard];
        [self setExpiration:self.assignmentExpirationDate days:0 hours:0 minutes:0 seconds:0];
        [self setPostedDate];
        [self setDistance];

        self.currentAssignment = assignment;
        [self drawImages];

        if (!self.didAcceptAssignment) {
            MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
            region.center.latitude = [assignment.latitude doubleValue];
            region.center.longitude = [assignment.longitude doubleValue];
            region.span.longitudeDelta = 0.05f;
            region.span.latitudeDelta = 0.05f;
            [self.mapView setRegion:region animated:NO];
        }

        CLLocationCoordinate2D newCenter = CLLocationCoordinate2DMake([assignment.latitude doubleValue], [assignment.longitude doubleValue]);
        newCenter.latitude -= self.mapView.region.span.latitudeDelta * 0.25;
        [self.mapView setCenterCoordinate:newCenter animated:NO];

        self.hasDefault = NO;
        self.defaultID = nil;
        // self.assignmentCardIsOpen = NO;

        [self configureAssignmentCard];
        [self hideGlobalAssignmentsBar];
    }
}

#pragma mark - MapView

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self updateAssignments];
}

- (void)updateAssignments {

    if (self.didAcceptAssignment) {
        return;
    }

    MKCoordinateRegion region = self.mapView.region;
    CLLocationCoordinate2D center = region.center;
    MKCoordinateSpan span = region.span;

    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:(center.latitude - span.latitudeDelta * 0.5) longitude:center.longitude];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:(center.latitude + span.latitudeDelta * 0.5) longitude:center.longitude];
    NSInteger metersLatitude = [loc1 distanceFromLocation:loc2];
    NSInteger milesLatitude = metersLatitude / metersInAMile;

    CLLocation *location = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    [self fetchAssignmentsNearLocation:location radius:milesLatitude];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {

    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        static NSString *annotationIdentifer = @"user-annotation";
        MKAnnotationView *annotationView = (MKAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifer];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifer];
            annotationView.userInteractionEnabled = NO;

            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(-12, -12, 24, 24)];
            view.layer.cornerRadius = view.frame.size.width / 2;
            view.backgroundColor = [UIColor whiteColor];

            view.layer.shadowColor = [UIColor blackColor].CGColor;
            view.layer.shadowOffset = CGSizeMake(0, 2);
            view.layer.shadowOpacity = 0.15;
            view.layer.shadowRadius = 1.5;
            view.layer.shouldRasterize = YES;
            view.layer.rasterizationScale = [[UIScreen mainScreen] scale];

            [annotationView addSubview:view];

            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.frame = CGRectMake(-8, -8, 16, 16);
            imageView.layer.cornerRadius = 8;
            imageView.clipsToBounds = YES;
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [annotationView addSubview:imageView];

            if ([FRSUserManager sharedInstance].authenticatedUser.profileImage) {
                NSString *link = [[FRSUserManager sharedInstance].authenticatedUser valueForKey:@"profileImage"];
                NSURL *url = [NSURL URLWithString:link];
                [imageView hnk_setImageFromURL:url];
                imageView.backgroundColor = [UIColor frescoBlueColor];
            } else {
                imageView.backgroundColor = [UIColor frescoBlueColor];
            }
        } else {
            annotationView.annotation = annotation;
        }
        return annotationView;

    } else {
        static NSString *annotationIdentifer = @"assignment-annotation";
        MKAnnotationView *annotationView = (MKAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifer];
        annotationView = nil; // clear these to force redraw, avoid yellow annotations that shoud be green and visa versa
        self.annotationColorView = nil;
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifer];
            UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 75, 75)];
            container.backgroundColor = [UIColor clearColor];

            UIView *whiteView = [[UIView alloc] initWithFrame:CGRectMake(25.5, 25.5, 24, 24)];
            whiteView.layer.cornerRadius = 12;
            whiteView.backgroundColor = [UIColor whiteColor];

            whiteView.layer.shadowColor = [UIColor blackColor].CGColor;
            whiteView.layer.shadowOffset = CGSizeMake(0, 2);
            whiteView.layer.shadowOpacity = 0.15;
            whiteView.layer.shadowRadius = 1.5;
            whiteView.layer.shouldRasterize = YES;
            whiteView.layer.rasterizationScale = [[UIScreen mainScreen] scale];

            self.annotationColorView = [[UIView alloc] initWithFrame:CGRectMake(4, 4, 16, 16)];
            self.annotationColorView.layer.cornerRadius = 8;

            self.annotationColorView.backgroundColor = [UIColor frescoOrangeColor];

            if (self.didAcceptAssignment && [self location:[[FRSLocator sharedLocator] currentLocation] isWithinAssignmentRadius:self.currentAssignment]) {
                self.annotationColorView.backgroundColor = [UIColor frescoGreenColor];
            }

            [whiteView addSubview:self.annotationColorView];
            [container addSubview:whiteView];
            [annotationView addSubview:container];

            annotationView.enabled = YES;
            annotationView.frame = CGRectMake(0, 0, 75, 75);
        } else {
            annotationView.annotation = annotation;
        }
        return annotationView;
    }

    return nil;
}

#pragma mark - Annotations and Overlays

- (void)addUserLocationCircleOverlay {
    CGFloat radius = 200;

    if (self.userCircle) {
        [self.mapView removeOverlay:self.userCircle];
    }

    CLLocation *userLocation = [FRSLocator sharedLocator].currentLocation;

    self.userCircle = [FRSMapCircle circleWithCenterCoordinate:userLocation.coordinate radius:radius];
    self.userCircle.circleType = FRSMapCircleTypeUser;
    [self.mapView addOverlay:self.userCircle];
    [self.mapView addAnnotation:self.userCircle];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {

    MKCircleRenderer *circleR = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
    if ([overlay isKindOfClass:[FRSMapCircle class]]) {
        FRSMapCircle *circle = (FRSMapCircle *)overlay;

        if (circle.circleType == FRSMapCircleTypeUser) {
            circleR.fillColor = [UIColor frescoLightBlueColor];

        } else if (circle.circleType == FRSMapCircleTypeAssignment) {
            circleR.fillColor = [UIColor frescoOrangeColor];
            if (self.didAcceptAssignment && [self location:[[FRSLocator sharedLocator] currentLocation] isWithinAssignmentRadius:self.currentAssignment]) {
                circleR.fillColor = [UIColor frescoGreenColor];
            }
            circleR.alpha = 0.3;
        }
    }

    return circleR;
}

- (void)removeAllOverlaysIncludingUser:(BOOL)removeUser {
    for (id<MKOverlay> overlay in self.mapView.overlays) {
        if ([overlay isKindOfClass:[FRSMapCircle class]]) {
            FRSMapCircle *circle = (FRSMapCircle *)overlay;

            if (circle.circleType == FRSMapCircleTypeUser) {
                if (!removeUser)
                    continue;
            };

            [self.mapView removeOverlay:circle];
        }
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {

    if ([[view.annotation class] isSubclassOfClass:[MKUserLocation class]]) {
        return;
    }

    self.assignmentCardIsOpen = YES;

    [self.mapView deselectAnnotation:view.annotation animated:NO];

    FRSAssignmentAnnotation *assAnn = (FRSAssignmentAnnotation *)view.annotation;

    if (assAnn.title == nil) { //Checks for user annotation
        return;
    }
    
    self.currentAssignment = assAnn.assignment;

    self.assignmentTitle = assAnn.title;
    self.assignmentCaption = assAnn.subtitle;
    self.assignmentExpirationDate = assAnn.assignmentExpirationDate;
    self.assignmentPostedDate = assAnn.assignmentPostedDate;
    self.assignmentID = assAnn.assignmentId;
    self.outlets = assAnn.outlets;
    self.assignmentExpirationDate = assAnn.assignmentExpirationDate;

    if (!assAnn.isAcceptable) {
        self.assignemntAcceptButtonTitle = ACTION_TITLE_TWO;
    } else {
        self.assignemntAcceptButtonTitle = ACTION_TITLE_ONE;
    }

    if (self.didAcceptAssignment) {
        self.assignemntAcceptButtonTitle = ACTION_TITLE_TWO;
    }

    [self configureOutlets];

    [self setExpiration:self.assignmentExpirationDate days:0 hours:0 minutes:0 seconds:0];
    [self setPostedDate];
    [self configureAssignmentCard];
    [self animateAssignmentCard];
    [self snapToAnnotationView:view]; // Centers map with y offset

    self.assignmentLat = assAnn.coordinate.latitude;
    self.assignmentLong = assAnn.coordinate.longitude;

    [self setDistance];

    if (self.didAcceptAssignment && !self.userIsInRange) {
        [self hideAssignmentsMetaBar];
    } else {
        [self showAssignmentsMetaBar];
    }
}

- (void)setDistance {

    CLLocation *locA = [[CLLocation alloc] initWithLatitude:self.assignmentLat longitude:self.assignmentLong];
    CLLocation *locB = [[CLLocation alloc] initWithLatitude:[FRSLocator sharedLocator].currentLocation.coordinate.latitude longitude:[FRSLocator sharedLocator].currentLocation.coordinate.longitude];
    CLLocationDistance distance = [locA distanceFromLocation:locB];

    CGFloat miles = distance / metersInAMile;
    CGFloat feet = miles * 5280;

    NSString *distanceString;

    if (miles != 0) {
        if (miles <= 10) {
            distanceString = [NSString stringWithFormat:@"%.1f miles away", miles];

        } else {
            //Disable truncation on assignments with a distance away greater than 10 miles
            distanceString = [NSString stringWithFormat:@"%.0f miles away", miles];
        }

        if (feet <= 2000) {
            distanceString = [NSString stringWithFormat:@"%.0f feet away", feet];
        }
    }
    self.distanceLabel.text = distanceString;
    [self.distanceLabel sizeToFit];
    self.navigateButton.frame = CGRectMake(self.distanceLabel.frame.size.width + 60, 66, 24, 24);

    if (!self.userIsInRange) {
        self.acceptAssignmentDistanceAwayLabel.text = [distanceString uppercaseString];
    }
}

- (void)setPostedDate {
    NSString *postedString;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    [formatter setDateFormat:@"h:mm a"];

    postedString = [NSString stringWithFormat:@"Posted %@ at %@", [FRSDateFormatter dateDifference:self.assignmentPostedDate withAbbreviatedMonth:NO], [formatter stringFromDate:self.assignmentPostedDate]];

    self.postedLabel.text = postedString;
}

- (void)setExpiration:(NSDate *)date days:(int)expDays hours:(int)expHours minutes:(int)expMinutes seconds:(int)expSeconds {

    if (self.assignmentDidExpire) {
        return;
    }

    self.assignmentDidExpire = NO;

    NSTimeInterval doubleDiff = [date timeIntervalSinceDate:[NSDate date]];
    long diff = (long)doubleDiff;
    int seconds = diff % 60;
    diff = diff / 60;
    int minutes = diff % 60;
    diff = diff / 60;
    int hours = diff % 24;
    int days = diff / 24;

    if (!date) {
        days = expDays;
        hours = expHours;
        minutes = expMinutes;
        seconds = expSeconds;
    }

    NSString *expirationString;

    if (days != 0) {

        expirationString = [NSString stringWithFormat:@"Expires in %d days", days];
        if (days == 1) {
            expirationString = [NSString stringWithFormat:@"Expires in %d day", days];
        }
    } else if (hours != 0) {
        expirationString = [NSString stringWithFormat:@"Expires in %d hours and %d minutes", hours, minutes];
        if (minutes == 1) {
            expirationString = [NSString stringWithFormat:@"Expires in %d hours and %d minute", hours, minutes];
        } else if (minutes == 0) {
            expirationString = [NSString stringWithFormat:@"Expires in %d hours", hours];
        }
        if (hours == 1) {
            expirationString = [NSString stringWithFormat:@"Expires in %d hour and %d minutes", hours, minutes];
            if (minutes == 1) {
                expirationString = [NSString stringWithFormat:@"Expires in %d hour and %d minute", hours, minutes];
            } else if (minutes == 0) {
                expirationString = [NSString stringWithFormat:@"Expires in %d hours", hours];
            }
        }
    } else if (minutes != 0) {
        expirationString = [NSString stringWithFormat:@"Expires in %d minutes", minutes];
        if (minutes == 1) {
            expirationString = [NSString stringWithFormat:@"Expires in %d minute", minutes];
        }
    } else if (seconds != 0) {
        expirationString = [NSString stringWithFormat:@"Expires in %d seconds", seconds];
        if (seconds == 1) {
            expirationString = [NSString stringWithFormat:@"Expires in %d second", seconds];
        }
    } else {
        expirationString = @"This assignment has expired.";
        if (self.acceptedAssignment) {
            [self assignmentExpired];
        }
    }

    if (minutes <= 0 && seconds <= 0 && hours <= 0 && days <= 0) {
        expirationString = @"This assignment has expired.";
        if (self.acceptedAssignment) {
            [self assignmentExpired];
        }
    }

    self.expirationLabel.text = expirationString;
    self.acceptAssignmentTimeRemainingLabel.text = expirationString;
}

- (void)assignmentExpired {
    self.assignmentDidExpire = YES;
    if (!self.expiredAssignmentAlert) {
        self.expiredAssignmentAlert = [[FRSAlertView alloc] initWithTitle:@"OOPS" message:@"This assignment has expired!" actionTitle:@"OK" cancelTitle:@"" cancelTitleColor:[UIColor frescoBlueColor] delegate:nil];
        [self.expiredAssignmentAlert show];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      [self unacceptAssignment];
      [self reloadAssignmentAnnotations];
    });
}

// removes and readds all assignment annotations
- (void)reloadAssignmentAnnotations {
    [self removeAssignmentsFromMap];
    [self removeAllOverlaysIncludingUser:NO];
    [self addAnnotationsForAssignments];
    [self fetchAssignmentsNearLocation:[[FRSLocator sharedLocator] currentLocation] radius:10];
    [self addAnnotationsForAssignments];
}

// snaps camera to fit assignment annotation between top of assignment card and top of map
- (void)snapToAnnotationView:(MKAnnotationView *)view {
    CLLocationCoordinate2D newCenter = CLLocationCoordinate2DMake(view.annotation.coordinate.latitude, view.annotation.coordinate.longitude);
    newCenter.latitude -= self.mapView.region.span.latitudeDelta * 0.25;
    [self.mapView setCenterCoordinate:newCenter animated:YES];

    if ([self.mapView respondsToSelector:@selector(camera)]) {
        [self.mapView setShowsBuildings:NO];
        MKMapCamera *newCamera = [[self.mapView camera] copy];
        [newCamera setHeading:0];
        [self.mapView setCamera:newCamera animated:YES];
    }
}

// configures assignment card
- (void)createAssignmentView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 49, self.view.frame.size.width, self.view.frame.size.height)];
    self.scrollView.multipleTouchEnabled = NO;
    [self.view addSubview:self.scrollView];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.dismissView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
    [self.scrollView addSubview:self.dismissView];

    // needs to be global variable & removed on dismiss
    self.assignmentCard = [[UIView alloc] initWithFrame:CGRectMake(0, 76 + [UIScreen mainScreen].bounds.size.height / 3.5, self.view.frame.size.width, 1000)]; //Height is 1000 to avoid user overscrolling in y
    self.assignmentCard.backgroundColor = [UIColor frescoBackgroundColorLight];
    [self.scrollView addSubview:self.assignmentCard];

    UIView *topContainer = [[UIView alloc] initWithFrame:CGRectMake(0, -76, self.view.frame.size.width, 76)];
    topContainer.backgroundColor = [UIColor clearColor];
    [self.assignmentCard addSubview:topContainer];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = topContainer.frame;
    gradient.opaque = NO;
    UIColor *startColor = [UIColor clearColor];
    UIColor *endColor = [UIColor colorWithWhite:0 alpha:0.42];
    gradient.colors = [NSArray arrayWithObjects:(id)[startColor CGColor], (id)[endColor CGColor], nil];
    [self.assignmentCard.layer insertSublayer:gradient atIndex:0];

    self.assignmentTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 288, 52)];
    self.assignmentTitleLabel.font = [UIFont notaBoldWithSize:24];
    self.assignmentTitleLabel.numberOfLines = 0;
    self.assignmentTitleLabel.text = self.assignmentTitle;
    self.assignmentTitleLabel.textColor = [UIColor whiteColor];
    self.assignmentTitleLabel.adjustsFontSizeToFitWidth = YES;

    if (self.assignmentTitleLabel.frame.size.height == 72) { // 72 is the size of titleLabel with 3 lines
        [self.assignmentTitleLabel setOriginWithPoint:CGPointMake(16, 0)];
    }

    self.assignmentTitleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.assignmentTitleLabel.layer.shadowOpacity = .15;
    self.assignmentTitleLabel.layer.shadowRadius = 2;
    self.assignmentTitleLabel.layer.shadowOffset = CGSizeMake(0, 1);
    self.assignmentTitleLabel.clipsToBounds = NO;

    [topContainer addSubview:self.assignmentTitleLabel];

    self.assignmentBottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 44)];
    //    float barHeight = 44;
    //    self.assignmentBottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - (barHeight*2) - 5, self.view.frame.size.width, barHeight)];
    self.assignmentBottomBar.backgroundColor = [UIColor frescoBackgroundColorLight];
    [self.view addSubview:self.assignmentBottomBar];

    UIView *bottomContainerLine = [[UIView alloc] initWithFrame:CGRectMake(0, -0.5, self.view.frame.size.width, 0.5)];
    bottomContainerLine.backgroundColor = [UIColor frescoShadowColor];
    [self.assignmentBottomBar addSubview:bottomContainerLine];

    self.assignmentActionButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.assignmentActionButton.frame = CGRectMake(self.view.frame.size.width - 100 - 16, 15, 100, 17);
    [self.assignmentActionButton setTitle:self.assignemntAcceptButtonTitle forState:UIControlStateNormal];
    [self.assignmentActionButton.titleLabel setFont:[UIFont notaBoldWithSize:15]];
    self.assignmentActionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.assignmentActionButton setTitleColor:[UIColor frescoGreenColor] forState:UIControlStateNormal];
    [self.assignmentActionButton addTarget:self action:@selector(assignmentAction) forControlEvents:UIControlEventTouchUpInside];
    self.assignmentActionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.assignmentBottomBar addSubview:self.assignmentActionButton];

    self.spinner = [[DGElasticPullToRefreshLoadingViewCircle alloc] init];
    self.spinner.frame = CGRectMake(self.assignmentActionButton.frame.size.width - 20, self.assignmentActionButton.frame.size.height / 2 - 10, 20, 20);
    self.spinner.tintColor = [UIColor frescoOrangeColor];
    [self.spinner setPullProgress:90];
    self.spinner.alpha = 0;
    [self.view addSubview:self.spinner];

    self.assignmentOutletLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 18, self.view.frame.size.width - 16, 22)];
    [self.assignmentOutletLabel setFont:[UIFont notaMediumWithSize:17]];
    self.assignmentOutletLabel.textColor = [UIColor frescoDarkTextColor];
    self.assignmentOutletLabel.userInteractionEnabled = NO;
    self.assignmentOutletLabel.backgroundColor = [UIColor clearColor];
    self.assignmentOutletLabel.text = self.assignmentOutlet;
    [self.assignmentCard addSubview:self.assignmentOutletLabel];

    self.assignmentTextView = [[UITextView alloc] initWithFrame:CGRectMake(11, 50, self.view.frame.size.width - 16, 220)];
    [self.assignmentCard addSubview:self.assignmentTextView];
    [self.assignmentTextView setFont:[UIFont systemFontOfSize:15]];
    self.assignmentTextView.textColor = [UIColor frescoDarkTextColor];
    self.assignmentTextView.userInteractionEnabled = NO;
    self.assignmentTextView.editable = NO;
    self.assignmentTextView.selectable = NO;
    self.assignmentTextView.scrollEnabled = NO;
    self.assignmentTextView.backgroundColor = [UIColor clearColor];

    [self.assignmentTextView frs_setTextWithResize:self.assignmentCaption];

//    UIImageView *photoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo-icon-profile"]];
//    photoImageView.frame = CGRectMake(16, 10, 24, 24);
//    [self.assignmentBottomBar addSubview:photoImageView];
//
//    self.photoCashLabel = [[UILabel alloc] initWithFrame:CGRectMake(46, 15, 23, 17)];
//    self.photoCashLabel.text = @"$20";
//    self.photoCashLabel.textColor = [UIColor frescoMediumTextColor];
//    self.photoCashLabel.textAlignment = NSTextAlignmentCenter;
//    self.photoCashLabel.font = [UIFont notaBoldWithSize:15];
//    [self.assignmentBottomBar addSubview:self.photoCashLabel];

    if (self.assignmentCard.frame.size.height < self.assignmentTextView.frame.size.height) {
        CGRect cardFrame = self.assignmentCard.frame;
        cardFrame.size.height = self.assignmentTextView.frame.size.height * 2;
        self.assignmentCard.frame = cardFrame;
    }

    NSInteger bottomPadding = 15; // whatever padding we need at the bottom

    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 1);

//    UIImageView *videoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video-icon"]];
//    videoImageView.frame = CGRectMake(85, 10, 24, 24);
//    [self.assignmentBottomBar addSubview:videoImageView];
//
//    self.videoCashLabel = [[UILabel alloc] initWithFrame:CGRectMake(115, 15, 24, 17)];
//    self.videoCashLabel.text = @"$50";
//    self.videoCashLabel.textColor = [UIColor frescoMediumTextColor];
//    self.videoCashLabel.textAlignment = NSTextAlignmentCenter;
//    self.videoCashLabel.font = [UIFont notaBoldWithSize:15];
//    [self.assignmentBottomBar addSubview:self.videoCashLabel];

    self.assignmentStatsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.assignmentTextView.frame.size.height + 50, self.view.frame.size.width, 144)];
    [self.assignmentCard addSubview:self.assignmentStatsContainer];

    UIImageView *clock = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clock"]];
    clock.frame = CGRectMake(16, 12, 24, 24);
    [self.assignmentStatsContainer addSubview:clock];

    UIImageView *mapAnnotation = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"annotation"]];
    mapAnnotation.frame = CGRectMake(16, 66, 24, 24);
    [self.assignmentStatsContainer addSubview:mapAnnotation];

    UIImageView *warning = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"warning"]];
    warning.frame = CGRectMake(16, 110, 24, 24);
    [self.assignmentStatsContainer addSubview:warning];

    self.expirationLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 10, self.view.frame.size.width, 20)];
    self.expirationLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
    self.expirationLabel.textColor = [UIColor frescoDarkTextColor];

    self.postedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 14)];
    self.postedLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.postedLabel.textColor = [UIColor frescoMediumTextColor];
    [self.expirationLabel addSubview:self.postedLabel];

    [self setExpiration:self.assignmentExpirationDate days:0 hours:0 minutes:0 seconds:0];
    [self setPostedDate];

    [self.assignmentStatsContainer addSubview:self.expirationLabel];

    self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 68, self.view.frame.size.width, 20)];
    self.distanceLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
    self.distanceLabel.textColor = [UIColor frescoDarkTextColor];
    self.distanceLabel.text = @"";
    self.distanceLabel.userInteractionEnabled = YES;
    [self.assignmentStatsContainer addSubview:self.distanceLabel];
    [self setDistance];

    self.navigateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.navigateButton.frame = CGRectMake(self.distanceLabel.frame.size.width + 60, 66, 24, 24);
    self.navigateButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
    self.navigateButton.alpha = 0.5;
    [self.navigateButton setImage:[UIImage imageNamed:@"directions-24"] forState:UIControlStateNormal];
    [self.navigateButton addTarget:self action:@selector(navigateToAssignment) forControlEvents:UIControlEventTouchUpInside];
    self.navigateButton.tintColor = [UIColor blackColor];
    [self.assignmentStatsContainer addSubview:self.navigateButton];

    UILabel *warningLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 112, self.view.frame.size.width, 20)];
    warningLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
    warningLabel.textColor = [UIColor frescoDarkTextColor];
    warningLabel.text = @"Not all events are safe. Be careful!";
    [self.assignmentStatsContainer addSubview:warningLabel];

    UITextView *label = [[UITextView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height * 1.6, self.view.frame.size.width, 150)];
    label.text = @"If you keep scrolling you will find a pigeon.\n\n\n\n\nAlmost there...\n\n\n🐦";
    label.font = [UIFont systemFontOfSize:10 weight:UIFontWeightLight];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = self.assignmentCard.backgroundColor;
    label.textColor = [UIColor frescoLightTextColor];
    [self.scrollView addSubview:label];

    [self.assignmentTextView frs_setTextWithResize:self.assignmentCaption];
    self.assignmentCard.frame = CGRectMake(self.assignmentCard.frame.origin.x, self.view.frame.size.height - (24 + self.assignmentTextView.frame.size.height + 24 + 40 + 24 + 44 + 49 + 24 + bottomPadding + 25), self.assignmentCard.frame.size.width, self.assignmentCard.frame.size.height);

    // avoid any drawing above these
    self.scrollView.layer.zPosition = 1;
    self.assignmentBottomBar.layer.zPosition = 2;
}

- (void)navigateToAssignment {
    [[FRSAssignmentManager sharedInstance] navigateToAssignmentWithLatitude:self.assignmentLat longitude:self.assignmentLong navigationController:self.navigationController];
}

#pragma mark - Assignment Card

- (void)configureAssignmentCard {
    if (_scrollView) {
        self.assignmentTitleLabel.text = self.assignmentTitle;
        self.assignmentTextView.text = self.assignmentCaption;
        self.assignmentOutletLabel.text = self.assignmentOutlet;
        [self.assignmentActionButton setTitle:self.assignemntAcceptButtonTitle forState:UIControlStateNormal];

    } else {
        [self createAssignmentView];
    }

    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.assignmentBottomBar];

    currentScroller = self.scrollView;
    currentScroller.delegate = self;

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTap:)];
    [self.dismissView addGestureRecognizer:singleTap];

    [self.assignmentTextView frs_setTextWithResize:self.assignmentCaption];
    self.assignmentCard.frame = CGRectMake(self.assignmentCard.frame.origin.x, self.view.frame.size.height - (24 + self.assignmentTextView.frame.size.height + 24 + 40 + 24 + 44 + 49 + 24 + 15 + 50), self.assignmentCard.frame.size.width, self.assignmentCard.frame.size.height); // :(
    self.assignmentStatsContainer.frame = CGRectMake(self.assignmentStatsContainer.frame.origin.x, self.assignmentTextView.frame.size.height + 14 + 50, self.assignmentStatsContainer.frame.size.width, self.assignmentStatsContainer.frame.size.height);

    [self drawImages];

    self.navigationItem.hidesBackButton = false;
}

- (void)dismissTap:(UITapGestureRecognizer *)sender {

    [self dismissAssignmentCard];

    //Waits for animation to complete before removing from superview
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self.scrollView removeFromSuperview];
    });
}

- (void)animateAssignmentCard {

    [FRSAssignmentTracker trackAssignmentClick:self.currentAssignment didClick:YES];
    
    self.assignmentCardIsOpen = YES;
    self.mapShouldFollowUser = NO;

    UIImage *closeButtonImage = [UIImage imageNamed:@"close"];
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.tintColor = [UIColor whiteColor];
    [self.closeButton setImage:closeButtonImage forState:UIControlStateNormal];
    self.closeButton.frame = CGRectMake(0, 0, 24, 24);
    self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 0);
    [self.closeButton addTarget:self action:@selector(dismissAssignmentCard) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.alpha = 0;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];
    self.navigationItem.leftBarButtonItem = backButton;

    // animate scrollView in y
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       CGRect scrollFrame = self.scrollView.frame;
                       scrollFrame.origin.y = -12;
                       self.scrollView.frame = scrollFrame;
                     }
                     completion:nil];

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.assignmentBottomBar.transform = CGAffineTransformMakeTranslation(0, -93);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.closeButton.alpha = 1;
                     }
                     completion:nil];

    if (self.globalAssignmentsArray.count >= 1) {
        [self hideGlobalAssignmentsBar];
    }

    // configure accepted assignment state
    if (self.acceptedAssignment) {
        if ([self location:[[FRSLocator sharedLocator] currentLocation] isWithinAssignmentRadius:self.acceptedAssignment]) {
            [self showAssignmentsMetaBar];
        } else {
            [self hideAssignmentsMetaBar];
        }
    }
}

- (void)dismissAssignmentCard {
    
    [FRSAssignmentTracker trackAssignmentClick:self.currentAssignment didClick:NO];

    self.assignmentCardIsOpen = NO;

    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.assignmentCard.frame = CGRectMake(self.assignmentCard.frame.origin.x, self.assignmentCard.frame.origin.y + (self.view.frame.size.height - self.assignmentCard.frame.origin.y) + 100, self.assignmentCard.frame.size.width, self.assignmentCard.frame.size.height);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.5
        delay:0.0
        options:UIViewAnimationOptionCurveEaseOut
        animations:^{
          self.assignmentBottomBar.transform = CGAffineTransformMakeTranslation(0, 44);
        }
        completion:^(BOOL finished) {

          [self.scrollView setOriginWithPoint:CGPointMake(0, self.view.frame.size.height)];
        }];

    self.closeButton.alpha = 0;

    [self showGlobalAssignmentsBar];
    self.hasDefault = NO;
}

- (void)configureOutlets {
    NSArray *outlets = self.outlets;

    if (outlets.count == 1) {
        NSDictionary *outlet = [outlets firstObject];

        if (outlet[@"title"] && ![outlet[@"title"] isEqual:[NSNull null]]) {
            self.assignmentOutlet = outlet[@"title"];
        } else {
            self.assignmentOutlet = @"1 active news outlet";
        }
    } else if (outlets.count > 1) {
        self.assignmentOutlet = [NSString stringWithFormat:@"%d active news outlets", (int)self.outlets.count];
    } else if (outlets.count == 0) {
        self.assignmentOutlet = @"No active news outlets";
    }
}

- (void)drawImages {
    if (self.outletImagesViews) {
        for (UIImageView *imageView in self.outletImagesViews) {
            [imageView removeFromSuperview];
        }
    }

    self.outletImagesViews = [[NSMutableArray alloc] init];

    for (NSDictionary *outlet in self.outlets) {

        if (self.outletImagesViews.count >= 3) {
            return;
        }

        if (outlet[@"avatar"] && ![outlet[@"avatar"] isEqual:[NSNull null]]) {
            int xOffset = (int)self.outletImagesViews.count * (int)34 + 13;
            int width = 24;
            int height = 24;
            int y = 16;

            CGRect imageFrame = CGRectMake(xOffset + 4, y, width, height);
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageFrame];
            imageView.layer.masksToBounds = YES;
            imageView.layer.cornerRadius = width / 2;

            [self.outletImagesViews addObject:imageView];

            [self.assignmentCard addSubview:imageView];
            [imageView hnk_setImageFromURL:[NSURL URLWithString:outlet[@"avatar"]]];
        }

        int xOffset = (int)self.outletImagesViews.count * (int)34 + 17 + (3 * (self.outletImagesViews.count > 0));
        CGRect frame = self.assignmentOutletLabel.frame;
        frame.origin.x = xOffset;
        self.assignmentOutletLabel.frame = frame;
    }
}

#pragma mark - UIScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == currentScroller) {
        [self handleAssignmentScroll];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y <= -75) {
        [self dismissAssignmentCard];
    }
}

- (void)handleAssignmentScroll {
}

#pragma mark - Location handling

- (void)didReceiveLocationUpdate:(NSNotification *)notification {
    if([notification.userInfo[@"location"] isKindOfClass:[CLLocation class]]) {
        [self locationUpdate:(CLLocation *)notification.userInfo[@"location"]];
    }
}


/**
 Handles response to a new user location

 @param location Current location of the user to respond with
 */
- (void)locationUpdate:(CLLocation *)location {
    //Make sure we have a valid location before updating
    if(location.coordinate.latitude != 0 && location.coordinate.longitude != 0) return;
    
    if (!hasSnapped) {
        hasSnapped = TRUE;
        [self adjustMapRegionWithLocation:location];
        [self fetchAssignmentsNearLocation:location radius:10];
        [self addAnnotationsForAssignments];
    }
}

#pragma mark - UIPanGestureRec

- (void)configurePanGestureRec {
    self.mapShouldFollowUser = YES;
    UIPanGestureRecognizer *panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    [panRec setDelegate:self];
    [self.mapView addGestureRecognizer:panRec];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)didDragMap:(UIGestureRecognizer *)gestureRecognizer {
    self.mapShouldFollowUser = NO;
}

#pragma mark - Assignment Bars

- (void)showGlobalAssignmentsBar {
    if (self.didAcceptAssignment) {
        return;
    }
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.globalAssignmentsBottomContainer.transform = CGAffineTransformMakeTranslation(0, -44 - 49);
                     }
                     completion:nil];
}

- (void)hideGlobalAssignmentsBar {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.globalAssignmentsBottomContainer.transform = CGAffineTransformMakeTranslation(0, self.globalAssignmentsBottomContainer.frame.size.height);
                     }
                     completion:nil];
}

- (void)showAssignmentsMetaBar {
    self.assignmentBottomBar.transform = CGAffineTransformMakeTranslation(0, -44 - 49);
    //    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    self.scrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)hideAssignmentsMetaBar {
    self.assignmentBottomBar.transform = CGAffineTransformMakeTranslation(0, self.assignmentBottomBar.frame.size.height);
    //    [self.scrollView setContentOffset:CGPointMake(0, -44) animated:YES];
    self.scrollView.frame = CGRectMake(0, 36, self.view.frame.size.width, self.view.frame.size.height);
}

/**
 * Segways to the global assignment screen from the root assignment VC
 */
- (void)globalAssignmentsSegue {
    if (![[UIApplication sharedApplication].keyWindow.rootViewController isKindOfClass:[FRSGlobalAssignmentsTableViewController class]] && self.seguedToGlobalAssignment == false) {
        FRSGlobalAssignmentsTableViewController *tableViewController = [[FRSGlobalAssignmentsTableViewController alloc] init];
        tableViewController.assignments = self.globalAssignmentsArray;
        self.seguedToGlobalAssignment = YES;
        self.closeButton.alpha = 0;
        [self.navigationController pushViewController:tableViewController animated:YES];
        self.selectedAssignment = nil;
    }
}

//Redundant, but we need two because the deep link is not an animated transition
//and we can't pass in a BOOL value to a selector
- (IBAction)globalAssignmentsAnimatedSegue:(id)sender {
    FRSGlobalAssignmentsTableViewController *tableViewController = [[FRSGlobalAssignmentsTableViewController alloc] init];
    tableViewController.assignments = self.globalAssignmentsArray;
    self.seguedToGlobalAssignment = YES;
    self.closeButton.alpha = 0;
    [self.navigationController pushViewController:tableViewController animated:YES];
}

#pragma mark - Assignment Accepting

- (void)assignmentAction {
    if ([self.assignmentActionButton.titleLabel.text isEqualToString:ACTION_TITLE_TWO]) {
        [self openCamera];
    } else {
        [self acceptAssignment];
    }
}

- (void)acceptAssignment {
    self.spinner = [[DGElasticPullToRefreshLoadingViewCircle alloc] init];
    self.spinner.tintColor = [UIColor frescoOrangeColor];
    [self.spinner setPullProgress:90];
    [self startSpinner:self.spinner onButton:self.assignmentActionButton];

    [[FRSAssignmentManager sharedInstance] acceptAssignment:self.assignmentID
                                                 completion:^(id responseObject, NSError *error) {

                                                   [self stopSpinner:self.spinner onButton:self.assignmentActionButton color:[UIColor frescoGreenColor]];

                                                   NSHTTPURLResponse *response = error.userInfo[@"com.alamofire.serialization.response.error.response"];
                                                   NSInteger responseCode = response.statusCode;

                                                   if (responseObject || responseCode == 403) {
                                                       FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                       FRSAssignment *assignment = [NSEntityDescription insertNewObjectForEntityForName:@"FRSAssignment" inManagedObjectContext:delegate.managedObjectContext];
                                                       NSDictionary *dict = responseObject;
                                                       [assignment configureWithDictionary:dict];
                                                       [self configureAcceptedAssignment:assignment];

                                                       self.acceptedAssignmentDictionary = dict;
                                                       
                                                       [FRSAssignmentTracker trackAssignmentAccept:assignment didAccept:YES];
                                                       
                                                       return;
                                                   }

                                                   // user has already accepted the assignment
                                                   if (responseCode == 412) {
                                                       // should never happen
                                                       // bottom tab bar is not visible when in an accepted state
                                                       return;
                                                   }

                                                   // user is not authenticated (allow assignment accept)
                                                   if (responseCode == 403) {
                                                       return;
                                                   }

                                                   if (error.code == -1009) {
                                                       [self presentNoConnectionError];
                                                       return;
                                                   }

                                                   // 101 is unauthenticated (FRSAPIClient)
                                                   if (error.code != 101) {
                                                       [self presentGenericError];
                                                   }
                                                 }];
}

- (void)openCamera {
    FRSCameraViewController *cam = [[FRSCameraViewController alloc] initWithCaptureMode:FRSCaptureModeVideo selectedAssignment:self.acceptedAssignmentDictionary selectedGlobalAssignment:nil];
    UINavigationController *navControl = [[UINavigationController alloc] init];
    navControl.navigationBar.barTintColor = [UIColor frescoOrangeColor];
    [navControl pushViewController:cam animated:NO];
    [navControl setNavigationBarHidden:YES];

    [self presentViewController:navControl
                       animated:YES
                     completion:^{
                       [self.tabBarController setSelectedIndex:3]; // should return to assignments
                     }];
}

- (void)configureAcceptedAssignment:(FRSAssignment *)assignment {

    if (self.didAcceptAssignment) {
        return;
    }

    self.currentAssignment = assignment;
    self.hasDefault = YES;
    self.defaultID = assignment.uid;

    self.assignmentLat = [assignment.latitude floatValue];
    self.assignmentLong = [assignment.longitude floatValue];

    [self didAcceptAssignment:assignment];

    self.greenView = [[UIView alloc] initWithFrame:CGRectMake(0, -20, self.view.frame.size.width, 64)];
    self.greenView.layer.zPosition = 1;
    self.greenView.backgroundColor = [UIColor frescoGreenColor];
    [self.navigationController.navigationBar addSubview:self.greenView];
    [self.navigationController.navigationBar bringSubviewToFront:self.greenView];
    self.navigationController.navigationBar.clipsToBounds = NO;

    UIImage *closeButtonImage = [UIImage imageNamed:@"close"];
    self.unacceptAssignmentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.unacceptAssignmentButton.tintColor = [UIColor whiteColor];
    [self.unacceptAssignmentButton setImage:closeButtonImage forState:UIControlStateNormal];
    self.unacceptAssignmentButton.frame = CGRectMake(12, 30, 24, 24);
    [self.unacceptAssignmentButton addTarget:self action:@selector(unacceptAssignment) forControlEvents:UIControlEventTouchUpInside];
    [self.greenView addSubview:self.unacceptAssignmentButton];

    self.acceptAssignmentDistanceAwayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 28, self.greenView.frame.size.width, 17)];
    self.acceptAssignmentDistanceAwayLabel.text = [self.distanceLabel.text uppercaseString];
    self.acceptAssignmentDistanceAwayLabel.font = [UIFont notaBoldWithSize:15];
    self.acceptAssignmentDistanceAwayLabel.textColor = [UIColor whiteColor];
    self.acceptAssignmentDistanceAwayLabel.textAlignment = NSTextAlignmentCenter;
    [self.greenView addSubview:self.acceptAssignmentDistanceAwayLabel];

    self.acceptAssignmentTimeRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, self.greenView.frame.size.width, 12)];
    self.acceptAssignmentTimeRemainingLabel.text = self.expirationLabel.text;
    self.acceptAssignmentTimeRemainingLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightRegular];
    self.acceptAssignmentTimeRemainingLabel.textColor = [UIColor whiteColor];
    self.acceptAssignmentTimeRemainingLabel.textAlignment = NSTextAlignmentCenter;
    [self.greenView addSubview:self.acceptAssignmentTimeRemainingLabel];

    UIButton *navigationButton = [UIButton buttonWithType:UIButtonTypeSystem];
    navigationButton.frame = CGRectMake(self.greenView.frame.size.width - 36, 30, 24, 24);
    navigationButton.tintColor = [UIColor whiteColor];
    [navigationButton setImage:[UIImage imageNamed:@"navigate-white"] forState:UIControlStateNormal];
    [navigationButton addTarget:self action:@selector(navigateToAssignment) forControlEvents:UIControlEventTouchUpInside];
    [self.greenView addSubview:navigationButton];

    [self updateUIForLocation];

    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
    [self dismissAssignmentCard];

    self.mapShouldFollowUser = YES;
}

- (void)didAcceptAssignment:(FRSAssignment *)assignment {
    self.didAcceptAssignment = YES;
    [self removeAssignmentsFromMap];
    [self removeAllOverlaysIncludingUser:NO];
    [self addAnnotationsForAssignments];
    [self hideGlobalAssignmentsBar];
    [self hideAssignmentsMetaBar];
    [self updateUIForLocation];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
}

#pragma mark - Assignment Unaccepting

- (void)unacceptAssignment {
    self.spinner = [[DGElasticPullToRefreshLoadingViewCircle alloc] init];
    self.spinner.tintColor = [UIColor whiteColor];
    [self.spinner setPullProgress:90];

    [self startSpinner:self.spinner onButton:self.unacceptAssignmentButton];

    [[FRSAssignmentManager sharedInstance] unacceptAssignment:self.assignmentID
                                                   completion:^(id responseObject, NSError *error) {
                                                     // error or response, user should be able to unaccept. at least visually
                                                     [self configureUnacceptedAssignment];
                                                       
                                                     // todo: create FRSObjectCreator class that configures and returns core data objects from a response object
                                                     FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                     FRSAssignment *assignment = [NSEntityDescription insertNewObjectForEntityForName:@"FRSAssignment" inManagedObjectContext:delegate.managedObjectContext];
                                                     [assignment configureWithDictionary:(NSDictionary *)responseObject];
                                                       
                                                     [FRSAssignmentTracker trackAssignmentAccept:assignment didAccept:NO];
                                                   }];
}

- (void)configureUnacceptedAssignment {
    [self stopSpinner:self.spinner onButton:self.unacceptAssignmentButton color:[UIColor whiteColor]];
    self.didAcceptAssignment = NO;
    self.acceptedAssignment = nil;
    self.acceptedAssignmentDictionary = nil;
    self.assignmentIDs = [[NSMutableArray alloc] init];
    self.defaultID = nil;
    self.assignmentDidExpire = NO;

    [self.greenView removeFromSuperview];
    [self.timer invalidate];

    [(FRSTabBarController *)self.tabBarController setIrisItemColor:[UIColor frescoOrangeColor]];

    [self dismissAssignmentCard];
    [self reloadAssignmentAnnotations];

    if ([self location:[[FRSLocator sharedLocator] currentLocation] isWithinAssignmentRadius:self.currentAssignment]) {
        [self.assignmentActionButton setTitle:ACTION_TITLE_ONE forState:UIControlStateNormal];
    }

    if (self.globalAssignmentsArray.count >= 1) {
        [self showGlobalAssignmentsBar];
    }

    // should only come back up if assignment card is open
    if (self.assignmentCardIsOpen) {
        [self showAssignmentsMetaBar];
    } else {
        [self hideAssignmentsMetaBar];
    }
}

#pragma mark - Location Based UI Updates

- (void)updateUIForLocation {
    if ([self location:[[FRSLocator sharedLocator] currentLocation] isWithinAssignmentRadius:self.currentAssignment]) {
        if (!self.userIsInRange) {
            self.shouldRefreshMap = YES;
        } else {
            self.shouldRefreshMap = NO;
        }
        self.userIsInRange = YES;
        [self updateNavBarToOpenCamera];

    } else {
        if (self.userIsInRange) {
            self.shouldRefreshMap = YES;
        } else {
            self.shouldRefreshMap = NO;
        }
        self.userIsInRange = NO;
    }

    if (self.shouldRefreshMap) {
        [self removeAssignmentsFromMap];
        [self removeAllOverlaysIncludingUser:NO];
        [self addAnnotationsForAssignments];
    }
}

- (void)updateExpirationAndDistanceLabels {

    [self updateUIForLocation];

    [self setExpiration:self.assignmentExpirationDate days:0 hours:0 minutes:0 seconds:0];
    [self setDistance];
}

- (void)updateCounter:(NSTimer *)timer {

    if (!self.didAcceptAssignment) {
        return;
    }

    [self setDistance];

    NSDate *now = [NSDate date];
    if ([self.assignmentExpirationDate earlierDate:now] == self.assignmentExpirationDate) {
        [timer invalidate];
    } else {
        NSUInteger flags = NSCalendarUnitYear | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        NSDateComponents *components = [[NSCalendar currentCalendar] components:flags fromDate:now toDate:self.assignmentExpirationDate options:0];
        [self setExpiration:nil days:(int)[components day] hours:(int)[components hour] minutes:(int)[components minute] seconds:(int)[components second]];
        [self setDistance];
    }
}

- (void)updateNavBarToOpenCamera {
    self.acceptAssignmentDistanceAwayLabel.frame = CGRectMake(0, 35, self.greenView.frame.size.width, 17);
    self.acceptAssignmentDistanceAwayLabel.text = @"OPEN YOUR CAMERA";
    if (IS_IPHONE_5) {
        self.acceptAssignmentDistanceAwayLabel.text = ACTION_TITLE_TWO;
    }
    self.acceptAssignmentDistanceAwayLabel.font = [UIFont notaBoldWithSize:15];
    self.acceptAssignmentDistanceAwayLabel.textColor = [UIColor whiteColor];
    self.acceptAssignmentDistanceAwayLabel.textAlignment = NSTextAlignmentCenter;
    [self.greenView addSubview:self.acceptAssignmentDistanceAwayLabel];
    self.acceptAssignmentTimeRemainingLabel.alpha = 0;

    [(FRSTabBarController *)self.tabBarController setIrisItemColor:[UIColor frescoGreenColor]];
    [self.assignmentActionButton setTitle:ACTION_TITLE_TWO forState:UIControlStateNormal];

    if (self.assignmentCardIsOpen) {
        [self showAssignmentsMetaBar];
    }
}

#pragma mark - Spinner

- (void)startSpinner:(DGElasticPullToRefreshLoadingViewCircle *)spinner onButton:(UIButton *)button {
    [button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
    button.tintColor = [UIColor clearColor];
    spinner.frame = CGRectMake(button.frame.size.width - 20, button.frame.size.height / 2 - 10, 20, 20);
    [spinner startAnimating];
    [button addSubview:spinner];
}

- (void)stopSpinner:(DGElasticPullToRefreshLoadingView *)spinner onButton:(UIButton *)button color:(UIColor *)color {

    [button setTitleColor:color forState:UIControlStateNormal];
    [spinner stopLoading];
    [spinner removeFromSuperview];
}


@end
