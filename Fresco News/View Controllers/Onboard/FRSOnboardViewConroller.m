//
//  FRSOnboardVC.m
//  Fresco
//
//  Created by Omar El-Fanek on 9/1/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import "FRSOnboardViewConroller.h"
#import "OnboardPageViewController.h"
#import "OnboardPageCellController.h"
#import "UIColor+Additions.h"
#import "FRSProgressView.h"

@interface FRSOnboardViewConroller ()

/*
** Views and Viewcontrollers
*/

@property (strong, nonatomic) OnboardPageViewController *pagedViewController;

@property (weak, nonatomic) IBOutlet UIView *containerPageView;

/*
** UI Elements
*/

- (IBAction)nextButtonTapped:(id)sender;

@property (strong, nonatomic) IBOutlet UIButton *nextButton;

@property (strong, nonatomic) IBOutlet UIView *circleView1;

@property (strong, nonatomic) IBOutlet UIView *circleView2;

@property (strong, nonatomic) IBOutlet UIView *circleView3;

@property (strong, nonatomic) IBOutlet UIView *emptyCircleView1;

@property (strong, nonatomic) IBOutlet UIView *emptyCircleView2;

@property (strong, nonatomic) IBOutlet UIView *emptyCircleView3;

@property (strong, nonatomic) IBOutlet UIView *progressView;

@property (strong, nonatomic) IBOutlet UIView *emptyProgressView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emptyProgressViewLeadingConstraint;

@property (strong, nonatomic) FRSProgressView *frsProgressView;

/*
** Misc.
*/

@property (assign) BOOL didComeFromIndex0;

@property (assign) BOOL didComeFromIndex1;

@property (assign) BOOL didComeFromIndex2;


@property (assign) BOOL didFinishAnimationAtIndex0;

@property (assign) BOOL didFinishAnimationAtIndex1;

@property (assign) BOOL didFinishAnimationAtIndex2;


@property (nonatomic, assign) BOOL animationIsRunning;

@property (nonatomic, assign) NSTimeInterval delay;

@property (nonatomic, assign) int pageCount;

@end

@implementation FRSOnboardViewConroller

- (void)viewDidLoad {
    
    [super viewDidLoad];


    //First make the paged view controller
    self.pagedViewController = [[OnboardPageViewController alloc]
                                initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                options:nil];
    
    //Add onboard view controller to parent view controller
    [self addChildViewController:self.pagedViewController];
    
    //Set bounds of paged view controller to bounds of subview in the xib
    self.pagedViewController.view.frame = self.containerPageView.frame;
    
    //Add paged view controller as subview to containerPageViewController
    [self.view addSubview:self.pagedViewController.view];
    
    //Set didMove for the paged view controller
    [self.pagedViewController didMoveToParentViewController:self];
    

    
    //Initialize Bools
    self.didComeFromIndex0 = NO;
    self.didComeFromIndex1 = NO;
    self.didComeFromIndex2 = NO;

    self.didFinishAnimationAtIndex0 = NO;
    self.didFinishAnimationAtIndex1 = NO;
    self.didFinishAnimationAtIndex2 = NO;

}

- (void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    
    self.pageCount = 3;
    
    self.frsProgressView = [[FRSProgressView alloc] initWithFrame:CGRectMake(
                                                                             0,
                                                                             [[UIScreen mainScreen] bounds].size.height - 65,
                                                                             [[UIScreen mainScreen] bounds].size.width,
                                                                             65) andPageCount:self.pageCount];
    
    [self.view addSubview:self.frsProgressView];
    
}

- (IBAction)nextButtonTapped:(id)sender {
    
    [self.pagedViewController movedToViewAtIndex:self.pagedViewController.currentIndex];
    
}


- (void)updateStateWithIndex:(NSInteger)index{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.frsProgressView animateProgressViewAtPercent: ((float)(index+1) / (self.pageCount + 1))];
   
    });
}


@end
