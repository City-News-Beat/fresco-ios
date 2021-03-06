//
//  FRSOnboardThreeView.m
//  Fresco
//
//  Created by Omar Elfanek on 12/23/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import "FRSOnboardThreeView.h"
#import "UIColor+Fresco.h"
#import "UIFont+Fresco.h"
#import "UIImageView+Helpers.h"
#import "OEParallax.h"

@interface FRSOnboardThreeView ()

@property (strong, nonatomic) UIImageView *cloudIV;
@property (strong, nonatomic) UIImageView *leftArrowIV;
@property (strong, nonatomic) UIImageView *rightArrowIV;
@property (strong, nonatomic) UIImageView *televisionIV;
@property (strong, nonatomic) UIImageView *newspaperIV;
@property (strong, nonatomic) UIImageView *cashOneIV;
@property (strong, nonatomic) UIImageView *cashTwoIV;
@property (strong, nonatomic) UIImageView *cashThreeIV;
@property (strong, nonatomic) UIButton *cashButton;
@property (strong, nonatomic) UIView *container;
@property (nonatomic) BOOL animating;

@end

@implementation FRSOnboardThreeView

- (instancetype)initWithOrigin:(CGPoint)origin {
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, 320, 288)];
    if (self) {
        [self configureText];
        [self configureIV];
        //        self.animating = NO;

        [OEParallax createParallaxFromView:self.cloudIV withMaxX:20 withMinX:-20 withMaxY:20 withMinY:-20];
    }
    return self;
}

- (void)configureText {
    CGFloat screenWidth = self.bounds.size.width;
    CGFloat offset;

    if (IS_IPHONE_5) {
        offset = 138;
    } else if (IS_STANDARD_IPHONE_6) {
        offset = 164;
    } else if (IS_STANDARD_IPHONE_6_PLUS) {
        offset = 172;
    }

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(screenWidth / 2 - 144, offset, 288, 67)];
    [self addSubview:container];

    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(144 - 109, 0, 218, 19)]; //144 = containerWidth/2, 109 = headerWidth/2
    [header setText:@"See your work in the news"];
    [header setTextColor:[UIColor frescoDarkTextColor]];
    [header setFont:[UIFont notaBoldWithSize:17]];
    header.textAlignment = NSTextAlignmentCenter;
    [container addSubview:header];

    UILabel *subHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 27, 288, 40)]; //144 = containerWidth/2, 109 = headerWidth/2
    [subHeader setText:@"When your media is used we’ll tell you who used it and send you a payment!"];
    [subHeader setTextColor:[UIColor frescoMediumTextColor]];
    [subHeader setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightLight]];
    subHeader.textAlignment = NSTextAlignmentCenter;
    subHeader.numberOfLines = 2;
    [container addSubview:subHeader];

    //    /* DEBUG */
    //    container.backgroundColor = [UIColor blueColor];
    //    header.backgroundColor = [UIColor redColor];
    //    subHeader.backgroundColor = [UIColor redColor];
}

- (void)configureIV {
    NSInteger width = 144;
    NSInteger height = 96;
    CGFloat xOrigin = self.frame.size.width / 2;
    CGFloat yOrigin = 23;
    CGFloat offset;

    if (IS_IPHONE_5) {
        xOrigin = 194;
        yOrigin = 23;
        offset = 205;
    } else if (IS_STANDARD_IPHONE_6) {
        offset = 263;
    } else if (IS_STANDARD_IPHONE_6_PLUS) {
        offset = 295;
    }

    self.container = [[UIView alloc] initWithFrame:CGRectMake(0, offset, 320, 288)];
    [self addSubview:self.container];

    self.leftArrowIV = [[UIImageView alloc] initWithFrame:CGRectMake(104, 143, 28, 26)];
    self.leftArrowIV.image = [UIImage imageNamed:@"upload-dark"];
    self.leftArrowIV.transform = CGAffineTransformMakeRotation(M_PI_2 + 2);
    self.leftArrowIV.layer.shouldRasterize = YES;
    [self.container addSubview:self.leftArrowIV];

    self.rightArrowIV = [[UIImageView alloc] initWithFrame:CGRectMake(192, 143, 28, 26)];
    self.rightArrowIV.image = [UIImage imageNamed:@"upload-dark"];
    self.rightArrowIV.transform = CGAffineTransformMakeRotation(M_PI_2 + 1);
    self.rightArrowIV.layer.shouldRasterize = YES;
    [self.container addSubview:self.rightArrowIV];

    self.televisionIV = [[UIImageView alloc] initWithFrame:CGRectMake(46, 193, 88, 72)];
    self.televisionIV.image = [UIImage imageNamed:@"television"];
    [self.container addSubview:self.televisionIV];

    self.newspaperIV = [[UIImageView alloc] initWithFrame:CGRectMake(194, 194, 80, 72)];
    self.newspaperIV.image = [UIImage imageNamed:@"newspaper"];
    [self.container addSubview:self.newspaperIV];

    self.cloudIV = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - width / 2, yOrigin, width, height)];
    self.cloudIV.image = [UIImage imageNamed:@"grey-cloud"];
    [self.container addSubview:self.cloudIV];

    self.cashOneIV = [UIImageView UIImageViewWithName:@"cash"
                                             andFrame:CGRectMake(205, 36, 35, 24)
                                       andContentMode:UIViewContentModeScaleToFill];
    self.cashOneIV.layer.shouldRasterize = YES;
    self.cashOneIV.transform = CGAffineTransformMakeRotation(.13);
    [self.container addSubview:self.cashOneIV];

    self.cashTwoIV = [UIImageView UIImageViewWithName:@"cash"
                                             andFrame:CGRectMake(45, 60, 35, 24)
                                       andContentMode:UIViewContentModeScaleToFill];
    self.cashTwoIV.layer.shouldRasterize = YES;
    self.cashTwoIV.transform = CGAffineTransformMakeRotation(-.785);
    [self.container addSubview:self.cashTwoIV];

    self.cashThreeIV = [UIImageView UIImageViewWithName:@"cash"
                                               andFrame:CGRectMake(228, 114, 35, 24)
                                         andContentMode:UIViewContentModeScaleToFill];
    self.cashThreeIV.layer.shouldRasterize = YES;
    self.cashThreeIV.transform = CGAffineTransformMakeRotation(.785);
    [self.container addSubview:self.cashThreeIV];

    self.cashOneIV.alpha = 0;
    self.cashTwoIV.alpha = 0;
    self.cashThreeIV.alpha = 0;
}

- (UIImageView *)getCloud {
    return self.cloudIV;
}

- (UIView *)getCloudContainer {
    return self.container;
}

- (void)animate {

    //    if (!self.animating) {
    self.cloudIV.alpha = 1;
    self.televisionIV.alpha = 1;
    self.newspaperIV.alpha = 1;
    self.leftArrowIV.alpha = 1;
    self.rightArrowIV.alpha = 1;
    self.cashOneIV.alpha = 1;
    self.cashTwoIV.alpha = 1;
    self.cashThreeIV.alpha = 1;
    self.cloudIV.transform = CGAffineTransformMakeScale(.96, .96);
    self.cloudIV.alpha = 1;

    //self.cashOneIV.backgroundColor = [UIColor redColor];
    //self.cashTwoIV.backgroundColor = [UIColor blackColor];
    self.cashOneIV.backgroundColor = [UIColor whiteColor];
    self.cashTwoIV.backgroundColor = [UIColor whiteColor];
    self.cashThreeIV.backgroundColor = [UIColor whiteColor];

    [self animateCash1];
    [self animateCash2];
    [self animateCash3];

    //    }
    //    self.animating = YES;
}

- (void)animateCash1 {
    [UIView animateWithDuration:0.25
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.cloudIV.transform = CGAffineTransformMakeScale(1.03, 1.03);
          self.cloudIV.alpha = 1;
          CGMutablePathRef cash1Path1 = CGPathCreateMutable();
          CGPathMoveToPoint(cash1Path1, NULL, 200.0, 70.0);

          [UIView animateWithDuration:1.5
              animations:^{
                CGPathAddCurveToPoint(cash1Path1, NULL,
                                      340.0, 0.0,
                                      130.0, 100.0,
                                      250.0, 300.0);
                [UIView animateWithDuration:0.7
                    delay:0.3
                    options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
                      self.cashOneIV.transform = CGAffineTransformMakeRotation(0.3);
                    }
                    completion:^(BOOL finished) {
                      [UIView animateWithDuration:0.5
                                            delay:0.5
                                          options:UIViewAnimationOptionCurveEaseInOut
                                       animations:^{
                                         self.cashOneIV.transform = CGAffineTransformMakeRotation(-0.3);
                                         self.cashOneIV.alpha = 0;
                                       }
                                       completion:nil];
                    }];
              }
              completion:^(BOOL finished) {
                self.cashOneIV.transform = CGAffineTransformMakeRotation(.13);
              }];

          CAKeyframeAnimation *theAnimation;

          theAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
          theAnimation.path = cash1Path1;
          theAnimation.duration = 1.5;

          [self.cashOneIV.layer addAnimation:theAnimation forKey:@"position"];
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.25
                           animations:^{
                             self.cloudIV.transform = CGAffineTransformMakeScale(1, 1);
                           }];
        }];
}

- (void)animateCash2 {
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       CGMutablePathRef cash1Path1 = CGPathCreateMutable();
                       CGPathMoveToPoint(cash1Path1, NULL, 100.0, 70.0);

                       [UIView animateWithDuration:1.5
                           delay:0.5
                           options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             CGPathAddCurveToPoint(cash1Path1, NULL,
                                                   -90.0, 0.0,
                                                   130.0, 100.0,
                                                   100.0, 240.0);
                             [UIView animateWithDuration:0.7
                                 delay:0.3
                                 options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                   self.cashTwoIV.transform = CGAffineTransformMakeRotation(-0.3);

                                 }
                                 completion:^(BOOL finished) {
                                   [UIView animateWithDuration:0.5
                                                         delay:0.5
                                                       options:UIViewAnimationOptionCurveEaseInOut
                                                    animations:^{
                                                      self.cashTwoIV.transform = CGAffineTransformMakeRotation(0.3);
                                                      self.cashTwoIV.alpha = 0;
                                                    }
                                                    completion:nil];
                                 }];
                           }
                           completion:^(BOOL finished) {
                             //reset
                             self.cashTwoIV.transform = CGAffineTransformMakeRotation(.13);
                           }];

                       CAKeyframeAnimation *theAnimation;
                       theAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
                       theAnimation.path = cash1Path1;
                       theAnimation.duration = 1.5;
                       [self.cashTwoIV.layer addAnimation:theAnimation forKey:@"position"];

                     }
                     completion:nil];
}

- (void)animateCash3 {
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       CGMutablePathRef cash3Path = CGPathCreateMutable();
                       CGPathMoveToPoint(cash3Path, NULL, 200.0, 120.0);

                       [UIView animateWithDuration:1.5
                           animations:^{
                             CGPathAddCurveToPoint(cash3Path, NULL,
                                                   280.0, 100.0,
                                                   230.0, 100.0,
                                                   150.0, 200.0);
                             [UIView animateWithDuration:0.7
                                 delay:0.3
                                 options:UIViewAnimationOptionCurveEaseInOut
                                 animations:^{
                                   self.cashThreeIV.transform = CGAffineTransformMakeRotation(-0.3);
                                 }
                                 completion:^(BOOL finished) {
                                   [UIView animateWithDuration:0.5
                                                         delay:0.5
                                                       options:UIViewAnimationOptionCurveEaseInOut
                                                    animations:^{
                                                      self.cashThreeIV.transform = CGAffineTransformMakeRotation(0.3);
                                                      self.cashThreeIV.alpha = 0;
                                                    }
                                                    completion:nil];
                                 }];
                           }
                           completion:^(BOOL finished) {
                             //reset
                             self.cashThreeIV.transform = CGAffineTransformMakeRotation(-.13);
                           }];

                       CAKeyframeAnimation *cash3Animation;
                       cash3Animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
                       cash3Animation.path = cash3Path;
                       cash3Animation.duration = 1.5;

                       [self.cashThreeIV.layer addAnimation:cash3Animation forKey:@"position"];
                     }
                     completion:^(BOOL finished){
                         //        self.animating = NO;
                     }];
}

@end
