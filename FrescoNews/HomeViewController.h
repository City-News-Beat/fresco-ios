//
//  HomeViewController.h
//  FrescoNews
//
//  Created by Jason Gresh on 3/2/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "FRSBaseViewController.h"

typedef void(^FRSRefreshResponseBlock)(BOOL success, NSError *error);

@interface HomeViewController : FRSBaseViewController

- (void)performNecessaryFetch:(FRSRefreshResponseBlock)responseBlock;

@end

