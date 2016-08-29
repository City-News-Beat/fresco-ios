//
//  FRSDefaultNotificationTableViewCell.m
//  Fresco
//
//  Created by Omar Elfanek on 8/10/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSDefaultNotificationTableViewCell.h"
#import "UIColor+Fresco.h"
#import "FRSProfileViewController.h"
#import "FRSAPIClient.h"
#import <Haneke/Haneke.h>

@interface FRSDefaultNotificationTableViewCell ()


@property (weak, nonatomic) IBOutlet UIView *line;

@end

@implementation FRSDefaultNotificationTableViewCell

-(void)awakeFromNib {
    [super awakeFromNib];
}
-(void)prepareForReuse {
    [super prepareForReuse];
}


-(void)configureCellWithType:(FRSNotificationType)notificationType objectID:(NSString *)objectID {
    

    
    [self configureDefaultAttributesForNotification:notificationType];

    
    switch (notificationType) {
            
        case FRSNotificationTypeFollow:
            
            [self configureUserNotificationWithID:objectID];
            
            break;
            
            
            
            
            
            
        default:
            break;
    }
    
    
}

-(void)configureDefaultAttributesForNotification:(FRSNotificationType)notificationType {
    
    self.image.backgroundColor = [UIColor frescoLightTextColor];
    self.image.layer.cornerRadius = 20;
    self.image.clipsToBounds = YES;
    
    if (self.count <= 1) {
        
        self.annotationView.alpha = 0;
        self.annotationLabel.alpha = 0;
        
        switch (notificationType) {
            case FRSNotificationTypeFollow:
                self.bodyLabel.text = @"Followed you.";
                break;
            case FRSNotificationTypeLike:
                self.bodyLabel.text = @"Liked your gallery.";
                break;
            case FRSNotificationTypeRepost:
                self.bodyLabel.text = @"Reposted your gallery.";
                break;
            case FRSNotificationTypeComment:
                self.bodyLabel.text = @"Commented on your gallery.";
                break;
                
            default:
                break;
        }
    } else {
        
    }
}



-(void)configureUserNotificationWithID:(NSString *)notificationID {
    
    self.backgroundColor = [UIColor frescoBackgroundColorLight];
    
    [[FRSAPIClient sharedClient] getUserWithUID:notificationID completion:^(id responseObject, NSError *error) {
        
        self.titleLabel.text = [responseObject objectForKey:@"full_name"];
        
        if([responseObject objectForKey:@"avatar"] != [NSNull null]){
            NSURL *avatarURL = [NSURL URLWithString:[responseObject objectForKey:@"avatar"]];
            [self.image hnk_setImageFromURL:avatarURL];
        }
        
        if ([responseObject objectForKey:@"following"]) {
            [self.followButton setImage:[UIImage imageNamed:@"account-check"] forState:UIControlStateNormal];
            self.followButton.tintColor = [UIColor frescoOrangeColor];
        } else {
            [self.followButton setImage:[UIImage imageNamed:@"account-add"] forState:UIControlStateNormal];
            self.followButton.tintColor = [UIColor frescoMediumTextColor];
        }
        
        

    }];
  
}

















-(void)configureCell {
    
    //Configure background color
    if (self.backgroundViewColor == nil) {
        self.backgroundColor = [UIColor frescoBackgroundColorLight];
    }
    
    
    //Configure labels and rounded image
    self.titleLabel.numberOfLines = 0;
    self.bodyLabel.numberOfLines  = 3;
    self.image.backgroundColor = [UIColor frescoLightTextColor];
    self.image.layer.cornerRadius = 20;
    self.image.clipsToBounds = YES;
    
    
    //Configure count annotation
    self.annotationView.layer.cornerRadius = 12;
    if (self.count <= 1) {
        self.annotationView.alpha = 0;
    } else if (self.count <= 9) {
        self.titleLabel.text = [NSString stringWithFormat:@"%@ + %ld others", self.titleLabel.text, self.count];
        self.annotationLabel.text = [NSString stringWithFormat:@"+%ld", self.count];
    } else {
        self.annotationLabel.text = @"+";
    }
    
    
    if (self.image.image == nil) {
        self.image.alpha = 0;
        self.annotationView.alpha = 0;
        self.titleLabelLeftConstraint.constant = 8;
        self.bodyLabelLeftConstraint.constant = -40;
    }
    
    
    //if cell.type == follower
    //Configure follow button
    //if following
    //[self.followButton setImage:[UIImage imageNamed:@"already-following"] forState:UIControlStateNormal];
    //self.followButton.tintColor = [UIColor frescoOrangeColor];
    //else if not following
    [self.followButton setImage:[UIImage imageNamed:@"add-follower"] forState:UIControlStateNormal];
    //Button is set to system in IB to keep default fading behavior
    //Alpha is set in the png, setting tint to black retains original alpha in png
    self.followButton.tintColor = [UIColor blackColor];
}

-(IBAction)followTapped:(id)sender {

    if ([self.followButton.imageView.image isEqual:[UIImage imageNamed:@"already-following"]]) {
        [self.followButton setImage:[UIImage imageNamed:@"add-follower"] forState:UIControlStateNormal];
        self.followButton.tintColor = [UIColor frescoOrangeColor];
    } else if ([self.followButton.imageView.image isEqual: [UIImage imageNamed:@"add-follower"]]) {
        [self.followButton setImage:[UIImage imageNamed:@"already-following"] forState:UIControlStateNormal];
        self.followButton.tintColor = [UIColor blackColor];
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    //UITableViewCell subviews' background colors turn to clearColor when selecting/highlighting.
    //Setting the background color overrides this
    self.annotationView.backgroundColor = [UIColor whiteColor];
    self.line.backgroundColor = [UIColor frescoLightTextColor];
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    //UITableViewCell subviews' background colors turn to clearColor when selecting/highlighting.
    //Setting the background color overrides this
    self.annotationView.backgroundColor = [UIColor whiteColor];
    self.line.backgroundColor = [UIColor frescoLightTextColor];
}













@end
