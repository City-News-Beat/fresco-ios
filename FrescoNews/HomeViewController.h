//
//  HomeViewController.h
//  FrescoNews
//
//  Created by Jason Gresh on 3/2/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^FRSRefreshResponseBlock)(BOOL success, NSError* error);

@class FRSTag;

@interface HomeViewController : UIViewController
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, strong) NSMutableArray *savedPosts;
@property (nonatomic, strong) FRSTag *tag;

@end

