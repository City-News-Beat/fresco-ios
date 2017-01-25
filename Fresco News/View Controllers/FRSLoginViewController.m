//
//  FRSLoginViewController.m
//  Fresco
//
//  Created by Daniel Sun on 12/21/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import "FRSLoginViewController.h"
#import "FRSOnboardingViewController.h"
#import "FRSTabBarController.h"
#import "FRSUploadViewController.h"
#import "FRSAPIClient.h"
#import "DGElasticPullToRefreshLoadingViewCircle.h"
#import "FRSAppDelegate.h"
#import "FRSAlertView.h"
#import "FRSLocationManager.h"
#import "FRSAuthManager.h"
#import "FRSUserManager.h"

@interface FRSLoginViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITextField *userField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIView *usernameHighlightLine;
@property (weak, nonatomic) IBOutlet UIView *passwordHighlightLine;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UILabel *socialLabel;
@property (weak, nonatomic) IBOutlet UIButton *passwordHelpButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *socialTopConstraint;

@property (nonatomic) BOOL didAnimate;
@property (nonatomic) BOOL didTransform;

@property (strong, nonatomic) DGElasticPullToRefreshLoadingViewCircle *loadingView;
@property (strong, nonatomic) UILabel *invalidUserLabel;
@property (nonatomic) BOOL didAuthenticateSocial;
@property (strong, nonatomic) FRSAlertView *alert;
@property (strong, nonatomic) FBSDKLoginManager *fbLoginManager;
@property (strong, nonatomic) FRSLocationManager *locationManager;

@end

@implementation FRSLoginViewController

#pragma mark - View Controller Life Cycle

- (instancetype)init {
    self = [super initWithNibName:@"FRSLoginViewController" bundle:[NSBundle mainBundle]];

    if (self) {
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureSpinner];

    self.locationManager = [[FRSLocationManager alloc] init];

    self.didAnimate = NO;
    self.didTransform = NO;

    self.twitterButton.tintColor = [UIColor colorWithRed:0 green:0.675 blue:0.929 alpha:1]; /*Twitter Blue*/
    self.facebookButton.tintColor = [UIColor colorWithRed:0.231 green:0.349 blue:0.596 alpha:1]; /*Facebook Blue*/

    self.passwordField.tintColor = [UIColor frescoShadowColor];
    self.userField.tintColor = [UIColor frescoShadowColor];

    self.userField.delegate = self;
    self.passwordField.delegate = self;

    UIView *emailLine = [[UIView alloc] initWithFrame:CGRectMake(self.userField.frame.origin.x, self.userField.frame.origin.y, self.userField.frame.size.width, 1)];
    emailLine.backgroundColor = [UIColor frescoOrangeColor];
    [self.userField addSubview:emailLine];

    self.userField.tintColor = [UIColor frescoOrangeColor];
    self.passwordField.tintColor = [UIColor frescoOrangeColor];

    [self.userField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    self.loginButton.enabled = NO;

    self.view.backgroundColor = [UIColor frescoBackgroundColorLight];

    self.passwordField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{ NSForegroundColorAttributeName : [UIColor frescoLightTextColor] }];

    self.userField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email or @username" attributes:@{ NSForegroundColorAttributeName : [UIColor frescoLightTextColor] }];

    self.userField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passwordField.autocorrectionType = UITextAutocorrectionTypeNo;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(dismissKeyboard)];

    [self.view addGestureRecognizer:tap];

    if (IS_IPHONE_5) {
        self.socialTopConstraint.constant = 104;
    } else if (IS_IPHONE_6) {
        self.socialTopConstraint.constant = 120.8;
    } else if (IS_IPHONE_6_PLUS) {
        self.socialTopConstraint.constant = 128;
    }

    self.fbLoginManager = [[FBSDKLoginManager alloc] init];

    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.navigationBarHidden = YES;

    if (!self.didAnimate) {
        [self animateIn];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [FRSTracker track:onboardingReads];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

    if (!self.didAnimate) {
        self.backButton.alpha = 0;
        self.userField.alpha = 0;
        self.usernameHighlightLine.alpha = 0;
        self.passwordField.alpha = 0;
        self.passwordHelpButton.alpha = 0;
        self.passwordHighlightLine.alpha = 0;
        self.loginButton.alpha = 0;
        self.socialLabel.alpha = 0;
        self.twitterButton.alpha = 0;
        self.facebookButton.alpha = 0;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Spinner

- (void)configureSpinner {
    self.loadingView = [[DGElasticPullToRefreshLoadingViewCircle alloc] init];
    self.loadingView.tintColor = [UIColor frescoOrangeColor];
    [self.loadingView setPullProgress:90];
}

- (void)pushViewControllerWithCompletion:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    [self.navigationController pushViewController:viewController animated:animated];
    [CATransaction commit];
}

- (void)startSpinner:(DGElasticPullToRefreshLoadingViewCircle *)spinner onButton:(UIButton *)button {

    [button setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
    spinner.frame = CGRectMake(button.frame.size.width - 20 - 16, button.frame.size.height / 2 - 10, 20, 20);
    [spinner startAnimating];
    [button addSubview:spinner];
}

- (void)stopSpinner:(DGElasticPullToRefreshLoadingView *)spinner onButton:(UIButton *)button {

    [button setTitleColor:[UIColor frescoBlueColor] forState:UIControlStateNormal];
    [spinner stopLoading];
    [spinner removeFromSuperview];
}

#pragma mark - Actions

- (void)logoutAlertAction {
    [self logoutWithPop:NO];
}

- (IBAction)login:(id)sender {
    [self dismissKeyboard];

    //Animate transition
    NSString *username = _userField.text;

    if ([[username substringToIndex:1] isEqualToString:@"@"]) {
        username = [username substringFromIndex:1];
    }

    NSString *password = _passwordField.text;

    if ([password isEqualToString:@""] || [username isEqualToString:@""]) {
        // error out
        [self presentInvalidInfo];
        return;
    }

    [self startSpinner:self.loadingView onButton:self.loginButton];

    //checks if username is a username, if not it's an email.
    if (![self isValidUsername:username]) {
        username = _userField.text;
    }

    [[FRSAuthManager sharedInstance] signIn:username
                                   password:password
                                 completion:^(id responseObject, NSError *error) {

                                   if (error) {
                                       [FRSTracker track:loginError
                                              parameters:@{ @"method" : @"email",
                                                            @"error" : error.localizedDescription }];
                                   }

                                   [self stopSpinner:self.loadingView onButton:self.loginButton];

                                   if (error.code == 0) {

                                       FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
                                       [delegate saveUserFields:responseObject[@"user"]];
                                       [self setMigrateState:responseObject];

                                       [self popToOrigin];

                                       [self stopSpinner:self.loadingView onButton:self.loginButton];
                                       if (self.passwordField.text != nil && ![self.passwordField.text isEqualToString:@""]) {
                                           [[FRSAuthManager sharedInstance] setPasswordUsed:self.passwordField.text];
                                       }

                                       [self stopSpinner:self.loadingView onButton:self.loginButton];
                                       [[FRSAuthManager sharedInstance] setPasswordUsed:self.passwordField.text];

                                       if ([self validEmail:username]) {
                                           [[FRSAuthManager sharedInstance] setEmailUsed:self.userField.text];
                                       }

                                       [self checkStatusAndPresentPermissionsAlert:self.locationManager.delegate];

                                       NSDictionary *socialLinksDict = responseObject[@"user"][@"social_links"];

                                       if (socialLinksDict[@"facebook"] != nil) {
                                           [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"facebook-connected"];
                                       }

                                       if (socialLinksDict[@"twitter"] != nil) {
                                           [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"twitter-connected"];
                                       }

                                       if (responseObject[@"twitter_handle"] != nil) {
                                           [[NSUserDefaults standardUserDefaults] setValue:responseObject[@"twitter_handle"] forKey:@"twitter-handle"];
                                       }

                                       return;
                                   }

                                   if (error.code == -1009) {
                                       self.alert = [[FRSAlertView alloc] initNoConnectionAlert];
                                       [self.alert show];
                                       return;
                                   }

                                   NSHTTPURLResponse *response = error.userInfo[@"com.alamofire.serialization.response.error.response"];
                                   NSInteger responseCode = response.statusCode;

                                   if (responseCode == 401) {
                                       [self presentInvalidInfo];
                                       return;
                                   }

                                   if (error) {
                                       [self presentGenericError];
                                   }
                                 }];
}
- (void)presentInvalidInfo {

    [UIView animateWithDuration:0.15
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{

          self.passwordHighlightLine.backgroundColor = [UIColor frescoRedHeartColor];
          self.usernameHighlightLine.backgroundColor = [UIColor frescoRedHeartColor];

        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.15
                                delay:1.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{

                             self.passwordHighlightLine.backgroundColor = [UIColor frescoLightTextColor];
                             self.usernameHighlightLine.backgroundColor = [UIColor frescoLightTextColor];

                           }
                           completion:nil];
        }];
}

- (void)dismiss {
    self.view.backgroundColor = [UIColor frescoBackgroundColorLight];

    CABasicAnimation *translate = [CABasicAnimation animationWithKeyPath:@"position.y"];
    [translate setFromValue:[NSNumber numberWithFloat:self.view.center.y]];
    [translate setToValue:[NSNumber numberWithFloat:self.view.center.y + 50]];
    [translate setDuration:0.6];
    [translate setRemovedOnCompletion:NO];
    [translate setFillMode:kCAFillModeForwards];
    [translate setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.4:0:0:1.0]];
    [[self.view layer] addAnimation:translate forKey:@"translate"];

    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.view.alpha = 0;
                     }
                     completion:^(BOOL finished){

                     }];

    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    transition.subtype = kCATransitionFromTop;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    //    [[self navigationController] popViewControllerAnimated:NO];
    [self popToOrigin];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

//This response object comes back from login
- (void)setMigrateState:(NSDictionary *)responseObject {
    BOOL shouldSync = false;

    if (responseObject != nil && ![[responseObject valueForKey:@"valid_password"] boolValue]) {
        shouldSync = true;
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"needs-password"];
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:userNeedsToMigrate];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:userHasFinishedMigrating];

    } else if (![[[FRSUserManager sharedInstance] authenticatedUser] username] || ![[[FRSUserManager sharedInstance] authenticatedUser] email]) {
        shouldSync = true;
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:userNeedsToMigrate];
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:userHasFinishedMigrating];
    } else {
        shouldSync = true;
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:userNeedsToMigrate];
    }

    if (shouldSync) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
- (IBAction)twitter:(id)sender {

    self.twitterButton.hidden = true;
    DGElasticPullToRefreshLoadingViewCircle *spinner = [[DGElasticPullToRefreshLoadingViewCircle alloc] init];
    spinner.tintColor = [UIColor frescoOrangeColor];
    [spinner setPullProgress:90];
    [spinner startAnimating];
    [self.twitterButton.superview addSubview:spinner];
    [spinner setFrame:CGRectMake(self.twitterButton.frame.origin.x, self.twitterButton.frame.origin.y, self.twitterButton.frame.size.width, self.twitterButton.frame.size.width)];

    [FRSSocial loginWithTwitter:^(BOOL authenticated, NSError *error, TWTRSession *session, FBSDKAccessToken *token, NSDictionary *responseObject) {

      if (error) {
          [FRSTracker track:loginError
                 parameters:@{ @"method" : @"twitter",
                               @"error" : error.localizedDescription }];
      }

      if (authenticated) {
          NSDictionary *socialLinksDict = responseObject[@"user"][@"social_links"];

          if (socialLinksDict[@"facebook"] != nil) {
              [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"facebook-connected"];
          }

          [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"twitter-connected"];
          [[NSUserDefaults standardUserDefaults] setValue:session.userName forKey:@"twitter-handle"];
          [[NSUserDefaults standardUserDefaults] synchronize];

          FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
          [delegate saveUserFields:responseObject[@"user"]];
          [self setMigrateState:responseObject];

          self.didAuthenticateSocial = YES;

          [self checkStatusAndPresentPermissionsAlert:self.locationManager.delegate];

          [self popToOrigin];

          return;
      }

      if (error) {
          if (error.code == -1009) {
              self.alert = [[FRSAlertView alloc] initNoConnectionAlert];
              [self.alert show];
              [spinner stopLoading];
              [spinner removeFromSuperview];
              self.twitterButton.hidden = false;
              return;
          }

          NSLog(@"TWITTER SIGN IN: %@", error);

          FRSAlertView *alert = [[FRSAlertView alloc] initWithTitle:@"COULDN’T LOG IN" message:@"We couldn’t verify your Twitter account. Please try logging in with your email and password." actionTitle:@"OK" cancelTitle:@"" cancelTitleColor:nil delegate:nil];
          [alert show];
      }

      [spinner stopLoading];
      [spinner removeFromSuperview];
      self.twitterButton.hidden = false;
    }];
}

- (void)popToOrigin {
    FRSAppDelegate *appDelegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate reloadUser];

    NSArray *viewControllers = [self.navigationController viewControllers];

    if ([viewControllers count] == 3) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else if ([viewControllers count] >= 3) {
        [self.navigationController popToViewController:[viewControllers objectAtIndex:2] animated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:Nil];
    }

    //[self postLoginNotification];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)postLoginNotification {
    // temp fix
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:@"user-did-login" object:nil];
    });
}

- (IBAction)facebook:(id)sender {
    self.facebookButton.hidden = true;
    DGElasticPullToRefreshLoadingViewCircle *spinner = [[DGElasticPullToRefreshLoadingViewCircle alloc] init];
    spinner.tintColor = [UIColor frescoOrangeColor];
    [spinner setPullProgress:90];
    [spinner startAnimating];
    [self.facebookButton.superview addSubview:spinner];
    [spinner setFrame:CGRectMake(self.facebookButton.frame.origin.x, self.facebookButton.frame.origin.y, self.facebookButton.frame.size.width, self.facebookButton.frame.size.width)];

    [FRSSocial loginWithFacebook:^(BOOL authenticated, NSError *error, TWTRSession *session, FBSDKAccessToken *token, NSDictionary *responseObject) {

      if (error) {
          [FRSTracker track:loginError
                 parameters:@{ @"method" : @"facebook",
                               @"error" : error.localizedDescription }];
      }

      if (authenticated) {

          if (responseObject[@"twitter_handle"] != nil) {
              [[NSUserDefaults standardUserDefaults] setValue:responseObject[@"twitter_handle"] forKey:@"twitter-handle"];
          }
          NSDictionary *socialLinksDict = responseObject[@"user"][@"social_links"];
          if (socialLinksDict[@"twitter"] != nil) {
              [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"twitter-connected"];
          }

          [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"twitter-connected"];

          NSDictionary *socialDigest = [[FRSAPIClient sharedClient] socialDigestionWithTwitter:nil facebook:[FBSDKAccessToken currentAccessToken]];

          /*  */
          // [[FRSAPIClient sharedClient] setSocialUsed:socialDigest];
          /*  */

          FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
          [delegate saveUserFields:responseObject[@"user"]];
          [self setMigrateState:responseObject];

          NSLog(@"Social Digest: %@", socialDigest);

          [[FRSUserManager sharedInstance] updateUserWithDigestion:socialDigest
                                                        completion:^(id responseObject, NSError *error) {
                                                          [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"facebook-connected"];

                                                          [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{ @"fields" : @"name" }] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                                                            if (!error) {
                                                                [[NSUserDefaults standardUserDefaults] setObject:[result valueForKey:@"name"] forKey:@"facebook-name"];
                                                            }
                                                          }];
                                                        }];
          self.didAuthenticateSocial = YES;
          [self checkStatusAndPresentPermissionsAlert:self.locationManager.delegate];
          [self popToOrigin];

          [spinner stopLoading];
          [spinner removeFromSuperview];
          self.facebookButton.hidden = false;
          return;
      } else {
      }

      if (error) {

          if (error.code == -1009) {
              self.alert = [[FRSAlertView alloc] initNoConnectionAlert];
              [self.alert show];
              [spinner stopLoading];
              [spinner removeFromSuperview];
              self.facebookButton.hidden = false;
              return;
          } else if (error.code == 301) {
              //User dismisses view controller (done/cancel top left)
          }

          FRSAlertView *alert = [[FRSAlertView alloc] initWithTitle:@"COULDN’T LOG IN" message:@"We couldn’t verify your Facebook account. Please try logging in with your email and password." actionTitle:@"OK" cancelTitle:@"" cancelTitleColor:nil delegate:nil];
          [alert show];
      }

      [spinner stopLoading];
      [spinner removeFromSuperview];
      self.facebookButton.hidden = false;
    }
                          parent:self
                         manager:self.fbLoginManager];
}

- (IBAction)next:(id)sender {
    [self.passwordField becomeFirstResponder];
}

- (IBAction)back:(id)sender {
    [self dismissKeyboard];
    [self animateOut];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 / 2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self.navigationController popViewControllerAnimated:NO];

      [[NSNotificationCenter defaultCenter]
          postNotificationName:@"returnToOnboard"
                        object:self];
    });
}

- (IBAction)passwordHelp:(id)sender {

    [self highlightTextField:nil enabled:NO];

    [self.passwordField resignFirstResponder];
    [self.userField resignFirstResponder];

    [self animateFramesForKeyboard:YES];
    //patience, my friend. patience.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      NSURL *url = [NSURL URLWithString:@"https://www.fresconews.com/forgot"];
      [[UIApplication sharedApplication] openURL:url];
    });
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.userField) {
        if ((![self isValidUsername:self.userField.text] && ![self validEmail:self.userField.text]) || [self.userField.text isEqualToString:@""]) {
            [self animateTextFieldError:textField];
            return NO;
        }
    }

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    if (self.userField.editing) {
        if (range.length + range.location > textField.text.length) {
            return NO;
        }

        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return newLength <= 40;
    }

    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {

    [self highlightTextField:textField enabled:YES];

    if (self.passwordField.editing) {
        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.passwordHelpButton.alpha = 1;
                         }
                         completion:nil];
    }

    if (!self.didTransform) {

        [self animateFramesForKeyboard:NO];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.passwordHelpButton.alpha = 0;
                     }
                     completion:nil];

    if (!self.didTransform) {

        [self animateFramesForKeyboard:YES];
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    if ((self.userField.text && self.userField.text.length > 0) && (self.passwordField.text && self.passwordField.text.length >= 1)) {
        if ([self validEmail:self.userField.text] || [self isValidUsername:self.userField.text]) {

            self.loginButton.enabled = YES;

            [UIView transitionWithView:self.loginButton
                              duration:0.2
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                              [self.loginButton setTitleColor:[UIColor frescoBlueColor] forState:UIControlStateNormal];
                            }
                            completion:nil];

        } else {
            [UIView transitionWithView:self.loginButton
                              duration:0.2
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                              [self.loginButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
                            }
                            completion:nil];
        }

    } else if (self.passwordField.text && self.passwordField.text.length < 1) { //SHOULD BE 8, BROUGHT DOWN TO 4 TO TEST MAURICES PASSWORD
        self.loginButton.enabled = NO;

        [UIView transitionWithView:self.loginButton
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                          [self.loginButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
                        }
                        completion:nil];
    }

    if ([self.userField.text isEqualToString:@""]) {
        [UIView transitionWithView:self.loginButton
                          duration:0.2
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                          [self.loginButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
                        }
                        completion:nil];
    }

    if (self.passwordField.editing && ![self.passwordField.text isEqualToString:@""]) { //check whitespace?
        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.passwordHelpButton.alpha = 1;
                         }
                         completion:nil];
    } else {
        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.passwordHelpButton.alpha = 0;
                         }
                         completion:nil];
    }
}

- (void)highlightTextField:(UITextField *)textField enabled:(BOOL)enabled {

    if (!enabled) {
        [UIView animateWithDuration:.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.usernameHighlightLine.backgroundColor = [UIColor frescoShadowColor];
                           self.usernameHighlightLine.transform = CGAffineTransformMakeScale(1, 1);
                           self.passwordHighlightLine.backgroundColor = [UIColor frescoShadowColor];
                           self.passwordHighlightLine.transform = CGAffineTransformMakeScale(1, 1);
                         }
                         completion:nil];

        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.passwordHelpButton.alpha = 0;
                         }
                         completion:nil];
        return;
    }

    if (textField.editing == self.userField.editing) {

        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.usernameHighlightLine.backgroundColor = [UIColor frescoOrangeColor];
                           self.usernameHighlightLine.transform = CGAffineTransformMakeScale(1, 1.5);
                         }
                         completion:nil];

        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.passwordHighlightLine.backgroundColor = [UIColor frescoShadowColor];
                           self.passwordHighlightLine.transform = CGAffineTransformMakeScale(1, 1);
                         }
                         completion:nil];

    } else if (textField.editing == self.passwordField.editing) {

        [UIView animateWithDuration:0.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.passwordHighlightLine.backgroundColor = [UIColor frescoOrangeColor];
                           self.passwordHighlightLine.transform = CGAffineTransformMakeScale(1, 1.5);
                         }
                         completion:nil];

        [UIView animateWithDuration:.15
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                           self.usernameHighlightLine.backgroundColor = [UIColor frescoShadowColor];
                           self.usernameHighlightLine.transform = CGAffineTransformMakeScale(1, 1);
                         }
                         completion:nil];
    }
}

- (void)dismissKeyboard {

    if (self.userField.isEditing || self.passwordField.isEditing) {
        [self highlightTextField:nil enabled:NO];

        [self.userField resignFirstResponder];
        [self.passwordField resignFirstResponder];

        [self animateFramesForKeyboard:YES];
    }
}

- (void)animateFramesForKeyboard:(BOOL)hidden {

    if (hidden) {
        [UIView animateWithDuration:0.4
            delay:0.0
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^{

              if (IS_IPHONE_5) {
                  self.view.transform = CGAffineTransformMakeTranslation(0, 0);
              } else if (IS_IPHONE_6) {
                  self.socialLabel.transform = CGAffineTransformMakeTranslation(0, 0);
                  self.facebookButton.transform = CGAffineTransformMakeTranslation(0, 0);
                  self.twitterButton.transform = CGAffineTransformMakeTranslation(0, 0);
              }
            }
            completion:^(BOOL finished) {
              self.didTransform = NO;
            }];
    } else {
        [UIView animateWithDuration:0.25
            delay:0.0
            options:UIViewAnimationOptionCurveEaseInOut
            animations:^{
              if (IS_IPHONE_5) {
                  self.view.transform = CGAffineTransformMakeTranslation(0, -116);
              } else if (IS_IPHONE_6) {
                  self.socialLabel.transform = CGAffineTransformMakeTranslation(0, -20);
                  self.facebookButton.transform = CGAffineTransformMakeTranslation(0, -20);
                  self.twitterButton.transform = CGAffineTransformMakeTranslation(0, -20);
              }
            }
            completion:^(BOOL finished) {
              self.didTransform = YES;
            }];
    }
}

#pragma mark - Validators

- (BOOL)validEmail:(NSString *)emailString {

    if ([emailString length] == 0) {
        return NO;
    }

    NSString *regExPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";

    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:emailString options:0 range:NSMakeRange(0, [emailString length])];

    if (regExMatches == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isValidUsername:(NSString *)username {
    NSCharacterSet *allowedSet = [NSCharacterSet characterSetWithCharactersInString:validUsernameChars];
    NSCharacterSet *disallowedSet = [allowedSet invertedSet];
    return ([username rangeOfCharacterFromSet:disallowedSet].location == NSNotFound);
}

#pragma mark - Animation

- (void)animateTextFieldError:(UITextField *)textField {

    CGFloat duration = 0.1;

    /* SHAKE */

    [UIView animateWithDuration:duration
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{

          textField.transform = CGAffineTransformMakeTranslation(-7.5, 0);

        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:duration
              delay:0.0
              options:UIViewAnimationOptionCurveEaseInOut
              animations:^{

                textField.transform = CGAffineTransformMakeTranslation(5, 0);

              }
              completion:^(BOOL finished) {
                [UIView animateWithDuration:duration
                    delay:0.0
                    options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{

                      textField.transform = CGAffineTransformMakeTranslation(-2.5, 0);

                    }
                    completion:^(BOOL finished) {
                      [UIView animateWithDuration:duration
                          delay:0.0
                          options:UIViewAnimationOptionCurveEaseInOut
                          animations:^{

                            textField.transform = CGAffineTransformMakeTranslation(2.5, 0);

                          }
                          completion:^(BOOL finished) {
                            [UIView animateWithDuration:duration
                                                  delay:0.0
                                                options:UIViewAnimationOptionCurveEaseInOut
                                             animations:^{

                                               textField.transform = CGAffineTransformMakeTranslation(0, 0);

                                             }
                                             completion:nil];
                          }];
                    }];
              }];
        }];
}

- (void)prepareForAnimation {

    self.backButton.alpha = 0;
    self.backButton.transform = CGAffineTransformMakeTranslation(20, 0);
    self.backButton.enabled = NO;

    self.userField.alpha = 0;
    self.userField.transform = CGAffineTransformMakeTranslation(50, 0);

    self.usernameHighlightLine.alpha = 0;
    self.usernameHighlightLine.transform = CGAffineTransformMakeTranslation(50, 0);

    self.passwordField.alpha = 0;
    self.passwordField.transform = CGAffineTransformMakeTranslation(50, 0);

    self.passwordHighlightLine.alpha = 0;
    self.passwordHighlightLine.transform = CGAffineTransformMakeTranslation(50, 0);

    self.loginButton.alpha = 0;
    self.loginButton.transform = CGAffineTransformMakeTranslation(50, 0);

    self.socialLabel.transform = CGAffineTransformMakeTranslation(30, 0);
    self.socialLabel.alpha = 0;

    self.facebookButton.transform = CGAffineTransformMakeTranslation(20, 0);
    self.facebookButton.alpha = 0;

    self.twitterButton.transform = CGAffineTransformMakeTranslation(20, 0);
    self.twitterButton.alpha = 0;

    self.passwordHelpButton.alpha = 0;
}

- (void)animateIn {

    self.didAnimate = YES;

    [self prepareForAnimation];

    /* Transform and fade backButton xPos */
    [UIView animateWithDuration:0.6 / 2
                          delay:0.2 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.backButton.transform = CGAffineTransformMakeTranslation(0, 0);
                       self.backButton.alpha = 1;
                     }
                     completion:nil];

    /* Transform userField */
    [UIView animateWithDuration:0.5 / 2
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.userField.transform = CGAffineTransformMakeTranslation(-5, 0);
          self.userField.alpha = 1;
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.3 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.userField.transform = CGAffineTransformMakeTranslation(0, 0);
                           }
                           completion:nil];
        }];

    /* Transform and fade usernameHighlightLine */
    [UIView animateWithDuration:0.5 / 2
        delay:0.05 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.usernameHighlightLine.transform = CGAffineTransformMakeTranslation(-5, 0);
          self.usernameHighlightLine.alpha = 1;
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.3 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.usernameHighlightLine.transform = CGAffineTransformMakeTranslation(0, 0);
                           }
                           completion:nil];
        }];

    /* Transform and fade passwordField */
    [UIView animateWithDuration:0.5 / 2
        delay:0.1 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.passwordField.transform = CGAffineTransformMakeTranslation(-5, 0);
          self.passwordField.alpha = 1;
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.3 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.passwordField.transform = CGAffineTransformMakeTranslation(0, 0);
                           }
                           completion:nil];
        }];

    /* Transform and fade passwordHighlightLine */
    [UIView animateWithDuration:0.5 / 2
        delay:0.2 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.passwordHighlightLine.transform = CGAffineTransformMakeTranslation(-5, 0);
          self.passwordHighlightLine.alpha = 1;
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.3 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.passwordHighlightLine.transform = CGAffineTransformMakeTranslation(0, 0);
                           }
                           completion:nil];
        }];

    /* Transform and fade loginButton */
    [UIView animateWithDuration:0.5 / 2
        delay:0.25 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.loginButton.transform = CGAffineTransformMakeTranslation(-5, 0);
          self.loginButton.alpha = 1;
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.3 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.loginButton.transform = CGAffineTransformMakeTranslation(0, 0);
                           }
                           completion:nil];
        }];

    /* Transform and fade social line */

    [UIView animateWithDuration:0.7 / 2
                          delay:0.3 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.socialLabel.transform = CGAffineTransformMakeTranslation(0, 0);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.5 / 2
                          delay:0.3 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.socialLabel.alpha = 1;
                     }
                     completion:nil];

    [UIView animateWithDuration:1.0 / 2
                          delay:0.35 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.twitterButton.transform = CGAffineTransformMakeTranslation(0, 0);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.3 / 2
                          delay:0.35 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.twitterButton.alpha = 1;
                     }
                     completion:nil];

    [UIView animateWithDuration:1.0 / 2
                          delay:0.4 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.facebookButton.transform = CGAffineTransformMakeTranslation(0, 0);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.3 / 2
        delay:0.4 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.facebookButton.alpha = 1;
        }
        completion:^(BOOL finished) {
          self.backButton.enabled = YES;
        }];
}

- (void)animateOut {

    /* Transform backButton xPos */
    [UIView animateWithDuration:0.2 / 2
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.backButton.transform = CGAffineTransformMakeTranslation(5, 0);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.5 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.backButton.transform = CGAffineTransformMakeTranslation(-20, 0);
                             self.backButton.alpha = 0;
                           }
                           completion:nil];
        }];

    /* Transform userField */
    [UIView animateWithDuration:0.3 / 2
        delay:0.0
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.userField.transform = CGAffineTransformMakeTranslation(-5, 0);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.7 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.userField.transform = CGAffineTransformMakeTranslation(100, 0);
                           }
                           completion:nil];
        }];

    [UIView animateWithDuration:0.4 / 2
                          delay:0.4 / 2
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.userField.alpha = 0;
                     }
                     completion:nil];

    /* Transform usernameHighlightLine */
    [UIView animateWithDuration:0.3 / 2
        delay:0.05 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.usernameHighlightLine.transform = CGAffineTransformMakeTranslation(-5, 0);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.7 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.usernameHighlightLine.transform = CGAffineTransformMakeTranslation(100, 0);
                           }
                           completion:nil];
        }];

    [UIView animateWithDuration:0.4 / 2
                          delay:0.45 / 2
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.usernameHighlightLine.alpha = 0;
                     }
                     completion:nil];

    /* Transform passwordField and helpButton */
    [UIView animateWithDuration:0.3 / 2
        delay:0.1 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.passwordField.transform = CGAffineTransformMakeTranslation(-5, 0);
          self.passwordHelpButton.transform = CGAffineTransformMakeTranslation(-5, 0);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.7 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.passwordField.transform = CGAffineTransformMakeTranslation(100, 0);
                             self.passwordHelpButton.transform = CGAffineTransformMakeTranslation(100, 0);

                           }
                           completion:nil];
        }];

    [UIView animateWithDuration:0.4 / 2
                          delay:0.5 / 2
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.passwordField.alpha = 0;
                       self.passwordHelpButton.alpha = 0;
                     }
                     completion:nil];

    /* Transform passwordHighlightLine */
    [UIView animateWithDuration:0.3 / 2
        delay:0.15 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.passwordHighlightLine.transform = CGAffineTransformMakeTranslation(-5, 0);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.7 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.passwordHighlightLine.transform = CGAffineTransformMakeTranslation(100, 0);
                           }
                           completion:nil];
        }];

    [UIView animateWithDuration:0.4 / 2
                          delay:0.55 / 2
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.passwordHighlightLine.alpha = 0;
                     }
                     completion:nil];

    /* Transform loginButton */
    [UIView animateWithDuration:0.3 / 2
        delay:0.2 / 2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.loginButton.transform = CGAffineTransformMakeTranslation(-5, 0);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.7 / 2
                                delay:0.0
                              options:UIViewAnimationOptionCurveEaseInOut
                           animations:^{
                             self.loginButton.transform = CGAffineTransformMakeTranslation(100, 0);
                           }
                           completion:nil];
        }];

    [UIView animateWithDuration:0.4 / 2
                          delay:0.6 / 2
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.loginButton.alpha = 0;
                     }
                     completion:nil];

    /* Transform and fade social line */
    [UIView animateWithDuration:1.0 / 2
                          delay:0.5 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.facebookButton.transform = CGAffineTransformMakeTranslation(100, 0);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.3 / 2
                          delay:0.5 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.facebookButton.alpha = 0;
                     }
                     completion:nil];

    [UIView animateWithDuration:1.0 / 2
                          delay:0.55 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.twitterButton.transform = CGAffineTransformMakeTranslation(80, 0);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.3 / 2
                          delay:0.55 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.twitterButton.alpha = 0;
                     }
                     completion:nil];

    [UIView animateWithDuration:0.7 / 2
                          delay:0.6 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.socialLabel.transform = CGAffineTransformMakeTranslation(60, 0);
                     }
                     completion:nil];

    [UIView animateWithDuration:0.5 / 2
                          delay:0.6 / 2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       self.socialLabel.alpha = 0;
                     }
                     completion:nil];
}

@end

