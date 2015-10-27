//
//  SwitchingRootViewController.m
//  FrescoNews
//
//  Created by Fresco News on 6/9/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

@import AVFoundation;

#import "FRSRootViewController.h"
#import "FRSDataManager.h"
#import "FRSTabBarController.h"
#import "FRSFirstRunWrapperViewController.h"
#import "NotificationsViewController.h"
#import "FRSCamViewController.h"
#import "OnboardPageViewController.h"
#import "BaseNavigationController.h"
#import "TOSViewController.h"
#import "FRSOnboardViewConroller.h"
#import <BTBadgeView.h>

@interface FRSRootViewController () <UITabBarControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NotificationsViewController *notificationsView;

@property (strong, nonatomic) UIProgressView *progressView;

@end

@implementation FRSRootViewController

#pragma mark - Orientation

-(BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad{

    [super viewDidLoad];
    
    //Add progress indicator
    UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    
    progress.frame = CGRectMake(0, 64 , [[UIScreen mainScreen] bounds].size.width, 2.5);
    progress.tintColor = [UIColor frescoBlueColor];
    
    self.progressView = progress;
    
    [self.tbc.view addSubview:self.progressView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdatedTOSNeeded:) name:NOTIF_UPDATED_TOS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUploadProgress:) name:NOTIF_UPLOAD_PROGRESS object:nil];


}

#pragma mark - View Controller swapping

- (void)hideTabBar{
    
    [UIView animateWithDuration:0.3f animations:^{
        self.tbc.tabBar.frame = CGRectOffset(self.tbc.tabBar.frame, 0, 80);
    }];
    
}

- (void)showTabBar{
    
    [UIView animateWithDuration:0.3f animations:^{
        
        float y = [UIScreen mainScreen].bounds.size.height - self.tbc.tabBar.frame.size.height ;
        
        self.tbc.tabBar.frame = CGRectMake(self.tbc.tabBar.frame.origin.x, y, self.tbc.tabBar.frame.size.width, self.tbc.tabBar.frame.size.height);
        
    }];
}


- (void)setRootViewControllerToTabBar{

    [[UITabBar appearance] setTintColor:[UIColor brandDarkColor]]; // setTintColor:
    
    if(!self.tbc){
        self.tbc = (FRSTabBarController *)[self rootViewControllerWithIdentifier:@"tabBarController" underNavigationController:NO];
    }
    
    [self switchRootViewController:self.tbc];
    
    self.tbc.selectedIndex = 0;
    
}

- (void)setRootViewControllerToCamera{
    
    [self.tbc presentCamera];
}

- (void)setRootViewControllerToHighlights{
    
    [self.tbc setSelectedIndex:0];
}

/**
 *  Sets the root view controller completely to the first run
 */

- (void)setRootViewControllerToFirstRun{

    FRSFirstRunWrapperViewController *vc = [[FRSFirstRunWrapperViewController alloc] init];

    [self switchRootViewController:vc];
    
}

- (void)setRootViewControllerToOnboard{

    FRSOnboardViewConroller *onboardVC = [[FRSOnboardViewConroller alloc] init];

    [self switchRootViewController:onboardVC];
    
}

- (void)switchRootViewController:(UIViewController *)controller{
    
    // swap the view controllers
    UIViewController *source = self.viewController;
    UIViewController *destination = controller;
    UIViewController *container = self;
    
    [container addChildViewController:destination];
    
    // we'll always be replacing our whole view
    destination.view.frame = self.view.bounds;
    
    if (source) {
        [source willMoveToParentViewController:nil];
        [container transitionFromViewController:source
                               toViewController:destination
                                       duration:0
                                        options:UIViewAnimationOptionTransitionCrossDissolve
                                     animations:nil
                                     completion:^(BOOL finished) {
                                         [source removeFromParentViewController];
                                         [destination didMoveToParentViewController:container];
                                     }];
    }
    else {
        [self.view addSubview:destination.view];
        [destination didMoveToParentViewController:container];
    }
    
    // store the new view controller
    self.viewController = controller;
    
}


- (UIViewController *)rootViewControllerWithIdentifier:(NSString *)identifier underNavigationController:(BOOL)underNavigationController
{
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];
    
    UIViewController *viewController;
    
    if (underNavigationController) {
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:identifier];
        viewController = [[BaseNavigationController alloc] initWithRootViewController:vc];
        vc.navigationController.navigationBar.hidden = YES;
    }
    else
        viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    
    return viewController;
}

#pragma mark - NotificationCenter Listener

- (void)updateUploadProgress:(NSNotification *)notif{

    dispatch_async(dispatch_get_main_queue(), ^{
        
        if([notif.userInfo objectForKey:@"fractionCompleted"] != nil){
            
            NSNumber *progress = (NSNumber *)[notif.userInfo objectForKey:@"fractionCompleted"];
            
            [UIView animateWithDuration:1 animations:^{
                [self.progressView setProgress:progress.floatValue animated:YES];
            }];
            
        }

    });

}

- (void)handleUpdatedTOSNeeded:(NSNotification *)notification{
    
    UIAlertController *alertCon = [FRSAlertViewManager
                                   alertControllerWithTitle:@"Updated Terms of Service"
                                   message:@"We’ve updated our Terms of Service since the last time you logged on. Please read the terms before continuing."
                                   action:@"Logout" handler:^(UIAlertAction *action) {
                                       
                                       [[FRSDataManager sharedManager] logout];
                                       
                                       [self setRootViewControllerToHighlights];
                                       
                                   }];
    
    [alertCon addAction:[UIAlertAction actionWithTitle:@"Open Terms" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        
        TOSViewController *tosVC = [TOSViewController new];
        tosVC.agreedState = YES;
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tosVC];
        
        [self presentViewController:navigationController animated:YES completion:nil];
        
    }]];
    
    [self presentViewController:alertCon animated:YES completion:nil];

}

@end