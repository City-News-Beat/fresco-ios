//
//  StoryCell.h
//  Fresco
//
//  Created by Team Fresco on 2/9/14.
//  Copyright (c) 2014 TapMedia LLC. All rights reserved.
//

@import UIKit;
#import "FRSPost.h"

@interface StoryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *postImageView;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (nonatomic) BOOL didTransition;

@property (weak, nonatomic) FRSPost *post;

- (void)setPost:(FRSPost *)post;

+ (NSString *)identifier;
+ (NSAttributedString *)attributedStringForCaption:(NSString *)caption date:(NSString *)date;
@end
