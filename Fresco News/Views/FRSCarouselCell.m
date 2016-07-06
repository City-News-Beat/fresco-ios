//
//  FRSCarouselCell.m
//  Fresco
//
//  Created by Philip Bernstein on 6/20/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSCarouselCell.h"

@implementation FRSCarouselCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

-(void)loadImage:(PHAsset *)asset {
    if (!imageView) {
        imageView = [[UIImageView alloc] init];
        imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [self addSubview:imageView];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PHImageManager defaultManager]
             requestImageForAsset:asset
             targetSize:CGSizeMake(self.frame.size.width, self.frame.size.height)
             contentMode:PHImageContentModeAspectFill
             options:nil
             resultHandler:^(UIImage *result, NSDictionary *info) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     imageView.image = result;
                     imageView.contentMode = UIViewContentModeScaleAspectFill;
                 });
             }];
        });        
    }
}

-(void)loadVideo:(PHAsset *)asset {
    
    if (!videoView) {
        videoView = [[FRSPlayer alloc] init];
        [[PHImageManager defaultManager]
         requestAVAssetForVideo:asset
         options:nil
         resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:avAsset];
                 videoView = [[FRSPlayer alloc] initWithPlayerItem:playerItem];
                 AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:videoView];
                 playerLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
                 playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                 [self.layer addSublayer:playerLayer];
                 [videoView play];
            
                 [self.players addObject:videoView];
                 
                 UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPlayer)];
                 [self addGestureRecognizer:tap];
             });
         }];
    }
}

-(void)tapPlayer {
    if (videoView.rate != 0) {
        [videoView pause];
    } else {
        [videoView play];
    }
}


-(void)constrainSubview:(UIView *)subView ToBottomOfParentView:(UIView *)parentView WithHeight:(CGFloat)height {
    
    subView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //Trailing
    NSLayoutConstraint *trailing = [NSLayoutConstraint
                                    constraintWithItem:subView
                                    attribute:NSLayoutAttributeTrailing
                                    relatedBy:NSLayoutRelationEqual
                                    toItem:parentView
                                    attribute:NSLayoutAttributeTrailing
                                    multiplier:1
                                    constant:0];
    
    //Leading
    NSLayoutConstraint *leading = [NSLayoutConstraint
                                   constraintWithItem:subView
                                   attribute:NSLayoutAttributeLeading
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:parentView
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1
                                   constant:0];
    
    //Bottom
    NSLayoutConstraint *bottom = [NSLayoutConstraint
                                  constraintWithItem:subView
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:parentView
                                  attribute:NSLayoutAttributeBottom
                                  multiplier:1
                                  constant:0];
    
    [parentView addConstraint:trailing];
    [parentView addConstraint:bottom];
    [parentView addConstraint:leading];
    
}

-(void)constrainToEdges:(UIView *)view {
    
//    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:0 constant:0];
//    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:0 constant:0];
//    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:0 constant:0];
//    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:0 constant:0];
//    [view addConstraints:@[topConstraint,bottomConstraint,leftConstraint,rightConstraint]];
}


@end
