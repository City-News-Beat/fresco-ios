//
//  ProfileSettingsViewController.m
//  FrescoNews
//
//  Created by Zachary Mayberry on 5/12/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "ProfileSettingsViewController.h"

#import "MKMapView+LegalLabel.h"
#import "FRSUser.h"
#import "FRSDataManager.h"

@interface ProfileSettingsViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *connectTwitterButton;
@property (weak, nonatomic) IBOutlet UIButton *connectFacebookButton;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UISlider *radiusStepper;
@property (weak, nonatomic) IBOutlet UILabel *radiusStepperLabel;
@property (nonatomic) int stepValue;
@property (weak, nonatomic) IBOutlet UITextField *textfieldFirst;
@property (weak, nonatomic) IBOutlet UITextField *textfieldMiddle;
@property (weak, nonatomic) IBOutlet UITextField *textfieldLast;
@property (weak, nonatomic) IBOutlet UITextField *textfieldCurrentPassword;
@property (weak, nonatomic) IBOutlet UITextField *textfieldNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *textfieldEmail;
@property (weak, nonatomic) IBOutlet MKMapView *mapviewRadius;
@end

@implementation ProfileSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateLinkingStatus];
    
    self.frsUser = [FRSDataManager sharedManager].currentUser;
    
    // Radius slider values
    self.scrollView.alwaysBounceHorizontal = NO;
    self.stepValue = 5.0f;

    self.textfieldFirst.text = self.frsUser.first;
    self.textfieldLast.text = self.frsUser.last;
    self.textfieldEmail.text = self.frsUser.email;
}

- (IBAction)valueChanged:(id)sender {
    float newStep = roundf((self.radiusStepper.value) / self.stepValue);
    self.radiusStepper.value = newStep * self.stepValue;
    
    if (self.radiusStepper.value < 2) {
        self.radiusStepperLabel.text = [NSString stringWithFormat:@"%i mile", (int) self.radiusStepper.value];
    } else {
        self.radiusStepperLabel.text = [NSString stringWithFormat:@"%i miles", (int) self.radiusStepper.value];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLinkingStatus {
    
    if (![PFUser currentUser]) {
        [self.connectTwitterButton setHidden:YES];
        [self.connectFacebookButton setHidden:YES];
    } else {
        [self.connectTwitterButton setHidden:NO];
        [self.connectFacebookButton setHidden:NO];
    
        if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
            [self.connectTwitterButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        } else {
            [self.connectTwitterButton setTitle:@"Connect" forState:UIControlStateNormal];
        }
    
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            [self.connectFacebookButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        } else {
            [self.connectFacebookButton setTitle:@"Connect" forState:UIControlStateNormal];
        }
    }
}

- (IBAction)connectFacebook:(id)sender
{
    [self.connectFacebookButton setTitle:@"" forState:UIControlStateNormal];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 20, (self.connectFacebookButton.frame.size.width - 40), 7)];
    spinner.color = [UIColor whiteColor];
    [spinner startAnimating];
    [self.connectFacebookButton addSubview:spinner];

    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [PFFacebookUtils linkUserInBackground:[PFUser currentUser]
                       withPublishPermissions:@[@"publish_actions"]
                                        block:^(BOOL succeeded, NSError *error) {
                                            if (succeeded) {
                                                NSLog(@"Woohoo, user is linked with Facebook!");
                                            }
                                            else {
                                                NSLog(@"%@", error);
                                            }
                                            [spinner removeFromSuperview];
                                            [self updateLinkingStatus];
                                        }];
    }
    else {
        [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSLog(@"The user is no longer associated with their Facebook account.");
            }
            else {
                NSLog(@"%@", error);
            }
            [spinner removeFromSuperview];
            [self updateLinkingStatus];
        }];
    }

}

- (IBAction)connectTwitter:(id)sender
{
    [self.connectTwitterButton setTitle:@"" forState:UIControlStateNormal];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 20, (self.connectTwitterButton.frame.size.width - 40), 7)];
    spinner.color = [UIColor whiteColor];
    [spinner startAnimating];
    [self.connectTwitterButton addSubview:spinner];

    if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        [PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
            if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
                NSLog(@"Woohoo, user logged in with Twitter!");
            }
            else {
                NSLog(@"%@", error);
            }
            [spinner removeFromSuperview];
            [self updateLinkingStatus];
        }];
    }
    else {
        [PFTwitterUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
            if (!error && succeeded) {
                NSLog(@"The user is no longer associated with their Twitter account.");
            }
            else {
                NSLog(@"%@", error);
            }
            [spinner removeFromSuperview];
            [self updateLinkingStatus];
        }];
    }
}

- (IBAction)saveChanges:(id)sender
{
    NSMutableDictionary *updateParams = [[NSMutableDictionary alloc] initWithCapacity:5];
  
    if ([self.textfieldFirst.text length])
        [updateParams setObject:self.textfieldFirst.text forKey:@"firstname"];
    
    if ([self.textfieldLast.text length])
        [updateParams setObject:self.textfieldLast.text forKey:@"lastname"];
 
    if ([self.textfieldEmail.text length])
        [updateParams setObject:self.textfieldEmail.text forKey:@"email"];
    
    
    [[FRSDataManager sharedManager] updateFrescoUserWithParams:updateParams block:^(id responseObject, NSError *error) {
        NSString *title;
        NSString *message;
        if (!error) {
            title = @"Success";
            message = @"Profile settings updated";
        }
        else {
            title = @"Error";
            message = @"Could not save Profile settings";
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];

    }];
}

- (IBAction)changePassword:(UIButton *)sender
{
    NSString *email = self.textfieldEmail.text;
    if (![email length])
        email = [FRSDataManager sharedManager].currentUser.email;
    
    if ([email length]) {
        [PFUser requestPasswordResetForEmail:email];
    }
    else
        NSLog(@"Unxexpected error changing password");
}

- (IBAction)logOut:(id)sender
{
    [[FRSDataManager sharedManager] logout];
    [self navigateToMainApp];
}

- (IBAction)sliderValueChanged:(UISlider *)slider
{
    CGFloat roundedValue = [self roundedValueForSlider:slider];
    
    NSString *pluralizer = (roundedValue > 1 || roundedValue == 0) ? @"s" : @"";
    
    NSString *newValue = [NSString stringWithFormat:@"%2.0f mile%@", roundedValue, pluralizer];
    
    // only update changes
    if (![self.radiusStepperLabel.text isEqualToString:newValue])
        self.radiusStepperLabel.text = newValue;
}

- (IBAction)sliderTouchUpInside:(UISlider *)slider {
    self.radiusStepper.value = [self roundedValueForSlider:slider];
}

- (CGFloat)roundedValueForSlider:(UISlider *)slider
{
    CGFloat roundedValue;
    if (slider.value < 10)
        roundedValue = (int)slider.value;
    else
        roundedValue = ((int)slider.value / 10) * 10;
    
    return roundedValue;
}

#pragma mark - MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [mapView zoomToCurrentLocation];
}

@end
