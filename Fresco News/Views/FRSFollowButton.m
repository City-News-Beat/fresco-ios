//
//  FRSFollowButton.m
//  Fresco
//
//  Created by Omar Elfanek on 1/16/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import "FRSFollowButton.h"
#import "FRSUserManager.h"
#import "FRSFollowManager.h"
#import "FRSConnectivityAlertView.h"

@interface FRSFollowButton ()

@property (strong, nonatomic) FRSUser *user;

@end

@implementation FRSFollowButton

- (instancetype)initWithDelegate:(id<FRSFollowButtonDelegate>)delegate user:(FRSUser *)user {
    self = [super init];
    if (self) {

        [self addTarget:self action:@selector(followButtonTappedOnUser) forControlEvents:UIControlEventTouchUpInside];
        self.user = user;
        [self updateIconForFollowing:user.following];
    }
    return self;
}

/**
 This method gets called when the user taps on the following button.
 */
- (void)followButtonTappedOnUser {
    if ([self.user.following boolValue]) {
        [[FRSFollowManager sharedInstance] unfollowUser:self.user
                                             completion:^(id responseObject, NSError *error) {
                                               [self handleResponse:responseObject error:error];
                                             }];
    } else {
        [[FRSFollowManager sharedInstance] followUser:self.user
                                           completion:^(id responseObject, NSError *error) {
                                               [self handleResponse:responseObject error:error];
                                           }];
    }
}

-(void)handleResponse:(id)responseObject error:(NSError *)error {
    if (!error && responseObject) {
        [self updateIconForFollowing:[self.user.following boolValue]];
    } else if (error) {
        FRSConnectivityAlertView *alert = [[FRSConnectivityAlertView alloc] initNoConnectionAlert];
        [alert show];
    }
}

- (void)updateIconForFollowing:(BOOL)following {
    // This check avoids displaying the button if the user in question is the authenticated user
    if ([self.user.uid isEqualToString:[[FRSUserManager sharedInstance] authenticatedUser].uid]) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      if (following) {
          [self setImage:[UIImage imageNamed:@"account-check"] forState:UIControlStateNormal];
          self.tintColor = [UIColor frescoOrangeColor];
      } else {
          [self setImage:[UIImage imageNamed:@"account-add"] forState:UIControlStateNormal];
          self.tintColor = [UIColor blackColor];
      }
    });
}

@end
