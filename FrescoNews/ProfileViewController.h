//
//  FullPageGalleryViewController.h
//  FrescoNews
//
//  Created by Jason Gresh on 3/19/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

typedef void(^FRSRefreshResponseBlock)(BOOL success, NSError* error);

#import <UIKit/UIKit.h>
@class GalleryView, FRSStory;
@interface ProfileViewController : UIViewController
@property (weak, nonatomic) IBOutlet GalleryView *galleryView;
@property (weak, nonatomic) IBOutlet UIView *profileView;
@property (weak, nonatomic) IBOutlet UIView *profileWrapperView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) FRSStory *story;
@end
