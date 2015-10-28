//
//  FRSOnboardPageViewController.h
//  Fresco
//
//  Created by Elmir Kouliev on 7/16/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OnboardPageCellController.h"

@interface OnboardPageViewController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (assign, nonatomic) NSInteger currentIndex;

- (void)movedToViewAtIndex:(NSInteger)index;

@end