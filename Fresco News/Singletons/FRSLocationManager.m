//
//  FRSLocationManager.m
//  Fresco
//
//  Created by Fresco News on 7/15/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import "FRSLocationManager.h"
#import "FRSDataManager.h"
#import "FRSAssignment.h"
@import Parse;

@interface FRSLocationManager ()

/**
*  Timer for location update interval
*/

@property (strong, nonatomic) NSTimer *locationTimer;


/**
 *  Current assignment of the location manager
 */

@property (strong, nonatomic) FRSAssignment *currentAssignment;

@property (strong, nonatomic) FRSAssignment *nearestAssignment;

@end

@implementation FRSLocationManager

#pragma mark - static methods

+ (FRSLocationManager *)sharedManager
{
    static FRSLocationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FRSLocationManager alloc] init];
    });
    return manager;
}

- (void)setupLocationMonitoringForState:(LocationManagerState)state
{
    
    /* How to debug background location updates, in the simulator
     1. Pause at beginning of didFinishLaunchingWithOptions (if necessary for steps 2 and/or 3 below)
     2. Xcode/scheme location simulation should be disabled, i.e. Select "Don't Simulate Location" from the pulldown
     2b. Better: Edit Scheme > Run > Options > Core Location > Default Location > Set to "None"
     3. Simulate location via iOS Simulator > Debug > Location > Freeway Drive
     4. Unpause
     5. Terminate the app
     6. Monitor background launches via iOS Simulator > Debug > Open System Log...
     6b. Also you may be able to debug background launches using scheme launch option "Wait for executable to be launched"
     */
    // NSLog(@"Background launch via UIApplicationLaunchOptionsLocationKey");
    self.delegate = self;
    
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
//    self.allowsBackgroundLocationUpdates = YES;
//    }
    
    if([self respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]){
        [self setAllowsBackgroundLocationUpdates:YES];
    }

    self.managerState = state;
    self.stopLocationUpdates = NO;
    
    //Checks to see if there is a logged in user 
    
    
    if(state == LocationManagerStateBackground){
        
        if (![[FRSDataManager sharedManager] isLoggedIn])
            return;
    
        self.pausesLocationUpdatesAutomatically = YES;
        self.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        
        self.activityType = CLActivityTypeFitness;
        
        [self requestAlwaysAuthorization];
        
        NSLog(@"START MONITORING");
        
        [self startMonitoringSignificantLocationChanges];
        
//                Uncomment for local notifications while testing
//        UILocalNotification *notification = [[UILocalNotification alloc] init];
//        notification.alertBody = @"Started";
//        notification.soundName = UILocalNotificationDefaultSoundName;
//        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
//        notification.timeZone = [NSTimeZone defaultTimeZone];
//        [[UIApplication sharedApplication] setScheduledLocalNotifications:@[notification]];
        
    }
    
    else if(state == LocationManagerStateForeground){
        
        self.desiredAccuracy = kCLLocationAccuracyBest;
    
        [self requestAlwaysAuthorization];
        
        [self startUpdatingLocation];
    
    }
    
}


#pragma mark - Location Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
 
//    NSLog(@"manager state = %@, sef.stopLocationUpdates=%@", self.managerState, self.stopLocationUpdates)
    
    if(!self.stopLocationUpdates){
        
        if (locations)
            [self pingUserLocationToServer:locations];
    
    }

}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // TODO: Also check for kCLAuthorizationStatusAuthorizedAlways
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
                
//        [self presentViewController:[FRSAlertViewManager
//                                     alertControllerWithTitle:@"Access to Location Disabled"
//                                     message:[NSString stringWithFormat:@"To re-enable, go to Settings and turn on Location Service for the %@ app.", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]
//                                     action:DISMISS]
//                           animated:YES
//                         completion:nil];
//        
//        [self.locationManager stopUpdatingLocation];

    }
}


/**
 *  Simply restarts location updates, used with timer to automatically restart
 */

- (void)restartLocationUpdates
{
    [self startUpdatingLocation];
    
    self.stopLocationUpdates = NO;
}


/**
 *  Sends location data to server
 *
 *  @param locations Array of locations from manager's didUpdateLocations
 */

- (void)pingUserLocationToServer:(NSArray *)locations{
    
    if (!self.currentLocation || [self.currentLocation distanceFromLocation:[locations lastObject]] > 0) {
        
        self.currentLocation = [locations lastObject];
        
        NSDictionary *params = @{@"lat" : @(self.location.coordinate.latitude),
                                 @"lon" : @(self.location.coordinate.longitude)};
        
        NSLog(@"CURRENT LOC = %ld %ld", self.location.coordinate.latitude, self.location.coordinate.longitude);
        
        [[FRSDataManager sharedManager] updateUserLocation:params completion:^(NSDictionary *response, NSError *error) {
            
            if(response){
                [self updateAssignemntsQuickActionWithResponse:response];
            }
            
        }];
        
        //Check if we're inactive, then send the local push for the assignment
        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive || [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground){
            [self sendLocalPushForAssignment];
        }
        
        //        Uncomment for local notifications while testing
//        UILocalNotification *notification = [[UILocalNotification alloc] init];
//        notification.alertBody = [self.location description];
//        notification.soundName = UILocalNotificationDefaultSoundName;
//        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
//        notification.timeZone = [NSTimeZone defaultTimeZone];
//        [[UIApplication sharedApplication] setScheduledLocalNotifications:@[notification]];
        
    }
    
    //Stop updating location, will be turned back on `restartLocationUpdates` on the interval
    [self stopUpdatingLocation];
    
    self.stopLocationUpdates = YES;
    
    //Set interval for location update every `locationUpdateInterval` seconds
    if (self.locationTimer == nil) {
        
        self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:LOCATION_UPDATE_INTERVAL
                                                              target:self
                                                            selector:@selector(restartLocationUpdates)
                                                            userInfo:nil
                                                             repeats:YES];
    }

}

-(void)updateAssignemntsQuickActionWithResponse:(NSDictionary *)response{
    
    NSArray *assignments = response[@"data"][@"assignments_nearby"];
    
    //DEBUG
    
    NSInteger rand = arc4random_uniform(5);
    
    NSMutableArray *array = [NSMutableArray new];
    
    for (NSInteger i = 0; i < rand; i++){
        [array addObject:[NSString stringWithFormat:@"%lu klasdf", i]];
    }
    
    assignments = [array copy];
    
    //end debug
    
    if (!assignments) return;
    
    NSArray *shortcutItems = [[UIApplication sharedApplication] shortcutItems];
    
    if (shortcutItems.count != 3) return;
    
    NSString *title = @"Assignments";
    NSString *subtitle;
    UIApplicationShortcutIcon *map = [UIApplicationShortcutIcon iconWithTemplateImageName:@"quick-action-map"];
    
    if ([assignments count] == 0){
        subtitle = @"";
    }
    else if ([assignments count] == 1){
        subtitle = assignments[0];
    }
    else {
        subtitle = [NSString stringWithFormat:@"%ld nearby", assignments.count];
    }
    
    UIApplicationShortcutItem *aItem = [[UIMutableApplicationShortcutItem alloc] initWithType:@"quick-action-map" localizedTitle:title localizedSubtitle:subtitle icon:map userInfo:nil];
    if (!aItem) return;
    
    NSArray *newItems = @[shortcutItems[0], shortcutItems[1], aItem];
    [[UIApplication sharedApplication] setShortcutItems:newItems];
    
}

/**
 *  Sends out local push for nearest assignment within range of the user
 */

- (void)sendLocalPushForAssignment{

    [[FRSDataManager sharedManager] getAssignmentsWithinRadius:20 ofLocation:self.location.coordinate withResponseBlock:^(id responseObject, NSError *error) {
        
        if([responseObject count] > 0){
            
            FRSAssignment *retrievedAssignment = (FRSAssignment *)[responseObject firstObject];
            
            //Check if the current assignment is nil, or if the current assignment and the fethced one are different
            if(self.currentAssignment == nil || !([retrievedAssignment.assignmentId isEqualToString:self.currentAssignment.assignmentId])){
                
                CGFloat distanceInMiles = [self.location distanceFromLocation:retrievedAssignment.locationObject] / kMetersInAMile;
                
                //Checks if the user is within radius of the assignmnet
                if(distanceInMiles < [retrievedAssignment.radius floatValue]){
            
                    self.currentAssignment = [responseObject firstObject];
                    
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    notification.alertBody = [NSString stringWithFormat:@"In range of %@", self.currentAssignment.title];
                    notification.userInfo = @{
                                              @"type" : NOTIF_ASSIGNMENT,
                                              NOTIF_ASSIGNMENT : self.currentAssignment.assignmentId};
                    
                    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
                    notification.soundName = UILocalNotificationDefaultSoundName;
                    notification.timeZone = [NSTimeZone defaultTimeZone];
                    [[UIApplication sharedApplication] setScheduledLocalNotifications:@[notification]];
                    
                }
                
            }
        }
    }];
}





@end
