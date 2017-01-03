//
//  FRSGalleryDetailView.h
//  Fresco
//
//  Created by Arthur De Araujo on 1/3/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRSGalleryView.h"

@interface FRSGalleryDetailView : UIView <FRSGalleryViewDelegate>

@property (strong, nonatomic) FRSGallery *gallery;
@property NSString *defaultPostID;
@property BOOL didChangeUp;

@property (strong, nonatomic) IBOutlet FRSGalleryView *galleryView;

-(void)configureGalleryView;

@end
