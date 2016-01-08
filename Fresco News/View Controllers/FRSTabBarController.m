//
//  FRSTabBarController.m
//  Fresco
//
//  Created by Daniel Sun on 12/18/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import "FRSTabBarController.h"

#import "FRSOnboardingViewController.h"
#import "FRSNavigationController.h"

#import "FRSProfileViewController.h"
#import "FRSHomeViewController.h"

#import "UIColor+Fresco.h"


@interface FRSTabBarController ()

@end

@implementation FRSTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureAppearance];
    [self configureViewControllers];
    
    [self configureTabBarItems];
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
        vc.title = nil;
        vc.tabBarItem.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
    }];
    
    [self configureIrisItem];
    
    // Do any additional setup after loading the view.
}

-(void)configureAppearance{
    [self.tabBar setBarTintColor:[UIColor frescoTabBarColor]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)configureTabBarItems{
    
    UITabBarItem *item0 = [self.tabBar.items objectAtIndex:0];
    item0.image = [[UIImage imageNamed:@"tab-bar-home"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item0.selectedImage = [[UIImage imageNamed:@"tab-bar-home-sel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    UITabBarItem *item1 = [self.tabBar.items objectAtIndex:1];
    item1.image = [[UIImage imageNamed:@"tab-bar-story"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item1.selectedImage = [[UIImage imageNamed:@"tab-bar-story-sel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    UITabBarItem *item2 = [self.tabBar.items objectAtIndex:2];
    item2.image = [[UIImage imageNamed:@"tab-bar-iris"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item2.selectedImage = [[UIImage imageNamed:@"tab-bar-iris"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    UITabBarItem *item3 = [self.tabBar.items objectAtIndex:3];
    item3.image = [[UIImage imageNamed:@"tab-bar-assign"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item3.selectedImage = [[UIImage imageNamed:@"tab-bar-assign-sel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    UITabBarItem *item4 = [self.tabBar.items objectAtIndex:4];
    item4.image = [[UIImage imageNamed:@"tab-bar-profile"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item4.selectedImage = [[UIImage imageNamed:@"tab-bar-profile-sel"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

-(void)configureViewControllers{
    UIViewController *vc = [[FRSNavigationController alloc] initWithRootViewController:[[FRSHomeViewController alloc] init]];
    UIViewController *vc1 = [[FRSOnboardingViewController alloc] init];
    UIViewController *vc2 = [[UIViewController alloc] init];
    UIViewController *vc3 = [[UIViewController alloc] init];
    UIViewController *vc4 = [[FRSNavigationController alloc] initWithRootViewController:[[FRSProfileViewController alloc] init]];
    
    self.viewControllers = @[vc, vc1, vc2, vc3, vc4];
}

-(void)configureIrisItem{
    
    CGFloat origin = self.view.frame.size.width * 2/5;
    CGFloat width = self.view.frame.size.width/5;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(origin, 0, width, 50)];
    view.backgroundColor = [UIColor frescoOrangeColor];
    [self.tabBar insertSubview:view atIndex:0];
    
}


#pragma mark Delegate

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    
    switch ([self.tabBar.items indexOfObject:item]) {
        case 0:
            [self handleHomeTabPressed];
            break;
        case 1:
            [self handleStoryTabPressed];
            break;
        case 2:
            [self handleCameraTabPressed];
            break;
        case 3:
            [self handleAssignmentTabPressed];
            break;
        case 4:
            [self handleProfileTabPressed];
            break;
        default:
            break;
    }
}

-(void)handleHomeTabPressed{
    self.lastActiveIndex = 0;
}

-(void)handleStoryTabPressed{
    self.lastActiveIndex = 1;
}

-(void)handleCameraTabPressed{
//    FRSCameraViewController *camVC = [[FRSCameraViewController alloc] init];
//    [self presentViewController:camVC animated:YES completion:nil];
}

-(void)handleAssignmentTabPressed{
    self.lastActiveIndex = 3;
}

-(void)handleProfileTabPressed{
    self.lastActiveIndex = 4;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
