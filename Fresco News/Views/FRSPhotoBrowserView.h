//
//  FRSPhotoBrowserView.h
//  Fresco
//
//  Created by Team Fresco on 3/4/14.
//  Copyright (c) 2014 TapMedia LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FRSPhotoBrowserView : UIView

@property (nonatomic, strong) NSArray *captions;
@property (nonatomic, strong, readonly) NSArray *images;

- (void)setImages:(NSArray *)images withInitialIndex:(NSUInteger)imageIndex;

@end
