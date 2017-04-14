//
//  FRSGalleryMediaImageCollectionViewCell.m
//  Fresco
//
//  Created by Revanth Kumar Yarlagadda on 4/13/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import "FRSGalleryMediaImageCollectionViewCell.h"
#import "FRSPost.h"
#import <Haneke/Haneke.h>
#import "NSURL+Fresco.h"

@interface FRSGalleryMediaImageCollectionViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) FRSPost *post;

@end

@implementation FRSGalleryMediaImageCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(void)loadPost:(FRSPost *)post {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //    self.imageView.image = nil;
        self.userInteractionEnabled = YES;
        self.post = post;
        
        //    [self loadImage];
    });

}

- (void)loadImage {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = nil;
        if(!self.post.imageUrl) return;
        
        [self.imageView
         hnk_setImageFromURL:[NSURL
                              URLResizedFromURLString:self.post.imageUrl
                              width:([UIScreen mainScreen].bounds.size.width * [[UIScreen mainScreen] scale])
                              ]
         ];
    });

}

@end
