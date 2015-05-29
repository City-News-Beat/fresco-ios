//
//  GalleryViewController.h
//  FrescoNews
//
//  Created by Elmir Kouliev on 5/29/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FRSBaseViewController.h"
#import "FRSGallery.h"

@interface GalleryViewController : FRSBaseViewController

@property (nonatomic, strong) FRSGallery *gallery;

- (void)setGallery:(FRSGallery *)gallery;


@end

