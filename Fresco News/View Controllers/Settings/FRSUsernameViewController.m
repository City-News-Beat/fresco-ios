//
//  FRSUsernameTableViewController.m
//  Fresco
//
//  Created by Omar Elfanek on 1/11/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSUsernameViewController.h"
#import "FRSTableViewCell.h"
#import "UIColor+Fresco.h"
#import "FRSAlertView.h"
#import "FRSUserManager.h"
#import "NSString+Validation.h"
#import <UXCam/UXCam.h>

@interface FRSUsernameViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, FRSAlertViewDelegate>

@property (strong, nonatomic) FRSTableViewCell *cell;
@property (strong, nonatomic) FRSAlertView *alert;
@property (strong, nonatomic) UIImageView *usernameCheckIV;
@property (strong, nonatomic) UIImageView *errorImageView;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSTimer *usernameTimer;
@property (strong, nonatomic) UITextField *passwordTextField;

@property (nonatomic) BOOL usernameTaken;

@end

@implementation FRSUsernameViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureTableView];
    [self configureBackButtonAnimated:NO];

    [self hideSensitiveViews];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self stopUsernameTimer];
}

- (void)configureTableView {
    self.title = @"USERNAME";
    self.automaticallyAdjustsScrollViewInsets = NO;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height - 64;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.bounces = NO;
    self.tableView.backgroundColor = [UIColor frescoBackgroundColorDark];
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (FRSTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *cellIdentifier;
    self.cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    self.cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;

    if (self.cell == nil) {
        self.cell = [[FRSTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if ([self.cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([self.cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [self.cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([self.cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.cell setLayoutMargins:UIEdgeInsetsZero];
    }

    return self.cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(FRSTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    cell = self.cell;

    switch (indexPath.row) {
    case 0:
        switch (indexPath.section) {
        case 0:
            [cell configureEditableCellWithDefaultText:@"New username" withTopSeperator:YES withBottomSeperator:NO isSecure:NO withKeyboardType:UIKeyboardTypeDefault];
            cell.textField.delegate = self;
            cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.textField.returnKeyType = UIReturnKeyNext;
            [cell.textField addTarget:self action:@selector(textField:shouldChangeCharactersInRange:replacementString:) forControlEvents:UIControlEventEditingChanged];

            self.usernameCheckIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check-green"]];
            self.usernameCheckIV.frame = CGRectMake(cell.textField.frame.size.width - 24, 10, 24, 24);
            self.usernameCheckIV.alpha = 0;
            [cell.textField addSubview:self.usernameCheckIV];

            break;
        default:
            break;
        }
        break;
    case 1:
        [cell configureEditableCellWithDefaultText:@"Password" withTopSeperator:YES withBottomSeperator:YES isSecure:YES withKeyboardType:UIKeyboardTypeDefault];
        cell.textField.delegate = self;
        cell.textField.returnKeyType = UIReturnKeyDone;
        [cell.textField addTarget:self action:@selector(textField:shouldChangeCharactersInRange:replacementString:) forControlEvents:UIControlEventEditingChanged];
        self.passwordTextField = cell.textField;
        break;
    case 2:
        [cell configureCellWithRightAlignedButtonTitle:@"SAVE USERNAME" withWidth:142 withColor:[UIColor frescoLightTextColor]];
        [cell.rightAlignedButton addTarget:self action:@selector(saveUsername) forControlEvents:UIControlEventTouchUpInside];
        break;

        break;

    default:
        break;
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark - UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(nonnull NSString *)string {
    if ([self.password isValidPassword] && self.usernameTaken) {
        [self.cell.rightAlignedButton setTitleColor:[UIColor frescoBlueColor] forState:UIControlStateNormal];
        self.cell.rightAlignedButton.userInteractionEnabled = YES;
    }

    if (textField.isSecureTextEntry) {
        self.password = textField.text;
        return YES;
    }

    if ([textField.text isEqualToString:@""] || textField.text == nil) {
        self.usernameCheckIV.alpha = 0;
        [self.cell.rightAlignedButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
        self.cell.rightAlignedButton.userInteractionEnabled = NO;
        self.usernameCheckIV.image = [UIImage imageNamed:@"check-red"];
    }

    self.username = textField.text;
    if ([self.username isValidUsername]) {
        [self checkUsername];
    } else {
        [self.cell.rightAlignedButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
        self.cell.rightAlignedButton.userInteractionEnabled = NO;
        self.usernameCheckIV.image = [UIImage imageNamed:@"check-red"];
    }

    //Set max length to 40
    if (range.length + range.location > textField.text.length) {
        return NO;
    }
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 40;

    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField.isSecureTextEntry) {
        if (self.errorImageView) {
            textField.text = 0;
            self.errorImageView.alpha = 0;
            self.errorImageView = nil;
            [self.errorImageView removeFromSuperview];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    FRSTableViewCell *currentCell = (FRSTableViewCell *)textField.superview.superview;
    NSIndexPath *currentIndexPath = [self.tableView indexPathForCell:currentCell];
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:0];
    FRSTableViewCell *nextCell = (FRSTableViewCell *)[self.tableView cellForRowAtIndexPath:nextIndexPath];
    [nextCell.textField becomeFirstResponder];

    if (textField == self.passwordTextField) {
        [self.view resignFirstResponder];
        [self saveUsername];
    }

    return NO;
}

- (void)addErrorToView {

    if (!self.errorImageView) {
        self.errorImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check-red"]];
        self.errorImageView.frame = CGRectMake(self.view.frame.size.width - 34, 55, 24, 24);
        self.errorImageView.alpha = 1; // 0 when animating
        [self.view addSubview:self.errorImageView];

        [self.cell.rightAlignedButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
        self.cell.rightAlignedButton.userInteractionEnabled = NO;
    }
}

#pragma mark - Actions

- (void)saveUsername {

    [self.view endEditing:YES];
    self.username = [self.username stringByReplacingOccurrencesOfString:@"@" withString:@""];

    NSDictionary *digestion = @{ @"username" : self.username,
                                 @"verify_password" : self.password };

    [[FRSUserManager sharedInstance] updateUserWithDigestion:digestion
                                                  completion:^(id responseObject, NSError *error) {
                                                    [[FRSUserManager sharedInstance] reloadUser];

                                                    if (!error) {
                                                        [self popViewController];
                                                        return;
                                                    }

                                                    if (error.code == -1009) {
                                                        if (!self.alert) {
                                                            self.alert = [[FRSAlertView alloc] initNoConnectionBannerWithBackButton:YES];
                                                            [self.alert show];
                                                        }
                                                        return;
                                                    }

                                                    NSHTTPURLResponse *response = error.userInfo[@"com.alamofire.serialization.response.error.response"];
                                                    NSInteger responseCode = response.statusCode;

                                                    if (responseCode == 403 || responseCode == 401) { //incorrect
                                                        if (!self.errorImageView) {
                                                            [self addErrorToView];
                                                            return;
                                                        }
                                                    } else {
                                                        [self presentGenericError];
                                                    }
                                                  }];

    FRSUser *userToUpdate = [[FRSUserManager sharedInstance] authenticatedUser];
    userToUpdate.username = self.username;
    [[[FRSUserManager sharedInstance] managedObjectContext] save:Nil];
}

- (void)checkUsername {
    if (![self.username isValidUsername]) {
        return;
    }

    NSRange whiteSpaceRange = [self.username rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([self.username isEqualToString:@""] || self.username == nil || whiteSpaceRange.location != NSNotFound || [self.username stringContainsEmoji]) {
        self.usernameCheckIV.alpha = 0;
        return;
    }

    [self startUsernameTimer];
}

- (void)animateUsernameCheckImageView:(UIImageView *)imageView animateIn:(BOOL)animateIn success:(BOOL)success {
    if ([self.username isEqualToString:@""] || self.username == nil) {
        [self.cell.rightAlignedButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
        self.cell.rightAlignedButton.userInteractionEnabled = NO;
        self.usernameCheckIV.alpha = 0;
        return;
    }

    if (!success) {
        self.usernameCheckIV.image = [UIImage imageNamed:@"check-green"];
    } else {
        self.usernameCheckIV.image = [UIImage imageNamed:@"check-red"];
    }

    if (animateIn) {
        if (self.usernameCheckIV.alpha == 0) {
            self.usernameCheckIV.transform = CGAffineTransformMakeScale(0.001, 0.001);
            self.usernameCheckIV.alpha = 0;
            self.usernameCheckIV.alpha = 1;
            self.usernameCheckIV.transform = CGAffineTransformMakeScale(1.05, 1.05);
            self.usernameCheckIV.transform = CGAffineTransformMakeScale(1, 1);
        }
    } else {
        self.usernameCheckIV.transform = CGAffineTransformMakeScale(1.1, 1.1);
        self.usernameCheckIV.transform = CGAffineTransformMakeScale(0.001, 0.001);
        self.usernameCheckIV.alpha = 0;
    }
}

#pragma mark - Username Timer

- (void)startUsernameTimer {
    if (!self.usernameTimer) {
        self.usernameTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(usernameTimerFired) userInfo:nil repeats:YES];
    }
}

- (void)stopUsernameTimer {
    if ([self.usernameTimer isValid]) {
        [self.usernameTimer invalidate];
    }

    self.usernameTimer = nil;
}

- (void)usernameTimerFired {
    if (![self.username isValidUsername]) {
        return;
    }

    NSRange whiteSpaceRange = [self.username rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];

    if ([self.username isEqualToString:@""] || self.username == nil || whiteSpaceRange.location != NSNotFound || [self.username stringContainsEmoji]) {
        self.usernameCheckIV.alpha = 0;
        return;
    }

    // Check for emoji and error
    if ([[self.cell.textField.text substringFromIndex:1] stringContainsEmoji]) {
        [self animateUsernameCheckImageView:self.usernameCheckIV animateIn:YES success:NO];
        return;
    }

    if (![self.cell.textField.text stringContainsEmoji]) {
        if ((![self.cell.textField.text isEqualToString:@""])) {
            [[FRSUserManager sharedInstance] checkUsername:self.username
                                                completion:^(id responseObject, NSError *error) {
                                                  //Return if no internet
                                                  if (error) {
                                                      if (error.code == -1009) {
                                                          if (!self.alert) {
                                                              self.alert = [[FRSAlertView alloc] initNoConnectionBannerWithBackButton:YES];
                                                              [self.alert show];
                                                          }
                                                          return;
                                                      }
                                                      [self animateUsernameCheckImageView:self.usernameCheckIV animateIn:YES success:NO];
                                                      self.usernameTaken = YES;
                                                      [self stopUsernameTimer];
                                                  } else {
                                                      BOOL available = [responseObject[@"available"] boolValue];
                                                      if (available) {
                                                          [self animateUsernameCheckImageView:self.usernameCheckIV animateIn:YES success:YES];
                                                          self.usernameTaken = NO;
                                                          [self stopUsernameTimer];
                                                          [self.cell.rightAlignedButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
                                                          self.cell.rightAlignedButton.userInteractionEnabled = NO;
                                                      } else {
                                                          [self animateUsernameCheckImageView:self.usernameCheckIV animateIn:YES success:NO];
                                                          self.usernameTaken = YES;
                                                          [self stopUsernameTimer];
                                                      }
                                                  }
                                                }];
        }
    }
}

#pragma mark - Validators

- (void)checkPassword {
    if ([self.password isValidPassword]) {
        [self.cell.rightAlignedButton setTitleColor:[UIColor frescoBlueColor] forState:UIControlStateNormal];
        self.cell.rightAlignedButton.userInteractionEnabled = YES;
    }
}

#pragma mark - FRSAlertView Delegate

- (void)didPressButtonAtIndex:(NSInteger)index {
    if (index == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark - UXCam

- (void)hideSensitiveViews {
    [UXCam occludeSensitiveView:self.passwordTextField];
}

@end
