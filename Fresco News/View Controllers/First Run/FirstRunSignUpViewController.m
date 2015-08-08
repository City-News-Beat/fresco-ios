//
//  FirstRunSignUpViewController.m
//  FrescoNews
//
//  Created by Zachary Mayberry on 4/27/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "FirstRunSignUpViewController.h"
#import "FRSDataManager.h"
@import FBSDKLoginKit;
@import FBSDKCoreKit;

@interface FirstRunSignUpViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *fieldsWrapper;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topVerticalSpaceConstraint; // not connected?
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *addPhotoImageView;
@property (weak, nonatomic) IBOutlet UITextField *textfieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *textfieldLastName;
@property (strong, nonatomic) UIImage *selectedImage;
@property (nonatomic) NSURL *socialImageURL;

@end

@implementation FirstRunSignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textfieldFirstName.delegate = self;
    self.textfieldLastName.delegate = self;

    self.textfieldFirstName.returnKeyType = UIReturnKeyNext;
    self.textfieldLastName.returnKeyType = UIReturnKeyDone;

    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    
    singleTap.numberOfTapsRequired = 1;
    
    [self.addPhotoImageView addGestureRecognizer:singleTap];
    
    self.addPhotoImageView.userInteractionEnabled = YES;
    self.addPhotoImageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowOrHide:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowOrHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [self setTwitterInfo];
    [self setFacebookInfo];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.textfieldFirstName) {
        [self.textfieldLastName becomeFirstResponder];
    }else if (textField == self.textfieldLastName) {
        [self.textfieldLastName resignFirstResponder];
    }
    
    return NO;
}

- (void)keyboardWillShowOrHide:(NSNotification *)notification
{
    [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0.3
                        options:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue] animations:^{
                            CGFloat height = 0;
                            if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
                                height = -7 * self.textfieldLastName.frame.size.height;
                            }
                            self.topVerticalSpaceConstraint.constant = height; // Constraint not connected?
                            self.bottomVerticalSpaceConstraint.constant = -1 * height;
                            [self.view layoutIfNeeded];
                        } completion:nil];
}

- (IBAction)actionNext:(id)sender
{
    
    // save this to allow backing to the VC
    self.firstName = [self.textfieldFirstName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.lastName = [self.textfieldLastName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSData *imageData = nil;
    if (self.selectedImage) {
        imageData = UIImageJPEGRepresentation(self.selectedImage, 0.5);
    }
    
    // both fields must be populated
    if ((self.firstName.length && self.lastName.length)) {
        
        NSMutableDictionary *updateParams = [NSMutableDictionary dictionaryWithDictionary:@{ @"firstname" : self.firstName, @"lastname" : self.lastName}];

        if (self.socialImageURL) {
            [updateParams setObject:[self.socialImageURL absoluteString] forKey:@"avatar"];
        }

        [[FRSDataManager sharedManager] updateFrescoUserWithParams:updateParams withImageData:imageData block:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Error: %@", error);
            }
            else {
                [self performSegueWithIdentifier:SEG_SHOW_PERMISSIONS sender:self];
            }
        }];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR
                                                        message:NAME_PROMPT
                                                       delegate:self
                                              cancelButtonTitle:OK
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark - Social data

/*
** Grab info from twitter, and set to respective fields
*/

- (void)setTwitterInfo
{
    if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
        return;
    }

    NSString *twitterUserID = [PFTwitterUtils twitter].userId;
    NSString *twitterScreenName = [PFTwitterUtils twitter].screenName;

    NSString *urlString = TWITTER_USERS_SHOW_URL;
    if (twitterUserID.length > 0) {
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"user_id=%@", twitterUserID]];
    }
    else if (twitterScreenName.length > 0) {
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"screen_name=%@", twitterScreenName]];
    }
    else {
        // Something really went wrong
        return;
    }

    NSURL *verify = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:verify];
    [[PFTwitterUtils twitter] signRequest:request];

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (!connectionError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error = nil;
                NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];

                NSString *profileImageURL = [result[@"profile_image_url_https"] stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
                if (profileImageURL.length > 0) {
                    self.socialImageURL = [NSURL URLWithString:profileImageURL];
                    [self.addPhotoImageView setImageWithURL:self.socialImageURL];
                }

                NSString *names = result[@"name"];
                // Poor man's first name/last name parsing
                if (names.length > 0) {
                    NSMutableArray *array = [NSMutableArray arrayWithArray:[names componentsSeparatedByString:@" "]];
                    if (array.count > 1) {
                        self.lastName = [array lastObject];
                        self.textfieldLastName.text = self.lastName;

                        [array removeLastObject];
                        self.firstName = [array componentsJoinedByString:@" "];
                        self.textfieldFirstName.text = self.firstName;
                    }
                }
            });
        }
    }];
}

/*
** Grab info from facebook, and set to respective fields
*/

- (void)setFacebookInfo
{
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        return;
    }

    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                   parameters:@{@"fields" : @"first_name, last_name, id"}
                                                                   HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.firstName = [result objectForKey:@"first_name"];
                self.lastName = [result objectForKey:@"last_name"];

                self.textfieldFirstName.text = self.firstName;
                self.textfieldLastName.text = self.lastName;

                // grab the image url
                NSString *urlString = [NSString stringWithFormat:@"%@/%@.png", [VariableStore sharedInstance].cdnFacebookBaseURL, [result valueForKeyPath:@"id"]];
                if (urlString) {
                    self.socialImageURL = [NSURL URLWithString:urlString];
                    [self.addPhotoImageView setImageWithURL:self.socialImageURL];
                }
            });
        }
    }];
}

#pragma mark - Touch Events

- (void)tapDetected
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = YES;
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:^{
        self.addPhotoImageView.layer.cornerRadius = self.addPhotoImageView.frame.size.width / 2;
        self.addPhotoImageView.clipsToBounds = YES;
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.textfieldFirstName isFirstResponder] && [touch view] != self.textfieldFirstName) {
        [self.textfieldFirstName resignFirstResponder];
    }
    else if ([self.textfieldLastName isFirstResponder] && [touch view] != self.textfieldLastName) {
        [self.textfieldLastName resignFirstResponder];
    }

    [super touchesBegan:touches withEvent:event];
}

#pragma mark - UIImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.selectedImage = [info valueForKey:UIImagePickerControllerEditedImage];
    self.addPhotoImageView.image = self.selectedImage;

    // Code here to work with media
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    if ([navigationController isKindOfClass:[UIImagePickerController class]]) {
        viewController.navigationItem.title = AVATAR_PROMPT;
        navigationController.navigationBar.tintColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.54];
        [navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar-background"] forBarMetrics:UIBarMetricsDefault];
    }
}

@end