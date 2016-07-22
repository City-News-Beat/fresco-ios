//
//  FRSDebitCardViewController.m
//  Fresco
//
//  Created by Omar Elfanek on 1/13/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSDebitCardViewController.h"
#import "FRSTableViewCell.h"
#import "UIColor+Fresco.h"
#import "UIView+Helpers.h"
#import "UIFont+Fresco.h"

@interface FRSDebitCardViewController()

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation FRSDebitCardViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor frescoBackgroundColorDark];
    [self configureView];
    self.title = @"DEBIT CARD";
    
    [self configureBackButtonAnimated:NO];
}


-(void)configureView{
    cardViewport = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2 - 44)];
    cardViewport.clipsToBounds = YES;
    [self.view addSubview:cardViewport];
    
    [cardViewport addSubview:[UIView lineAtPoint:CGPointMake(0, -0.5)]];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, cardViewport.frame.size.height, self.view.frame.size.width, 88)];
    container.backgroundColor = [UIColor colorWithWhite:1 alpha:.92];
    [self.view addSubview:container];
    
    UITextField *cardNumberTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    cardNumberTextField  = [[UITextField alloc] initWithFrame:CGRectMake(16, 0, [UIScreen mainScreen].bounds.size.width - (32), 44)];
    cardNumberTextField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
    cardNumberTextField.placeholder =  @"0000 0000 0000 0000";
    cardNumberTextField.textColor = [UIColor frescoDarkTextColor];
    cardNumberTextField.tintColor = [UIColor frescoBlueColor];
    [container addSubview:cardNumberTextField];
    
    cardNumberTextField.keyboardType = UIKeyboardTypeNumberPad;
    [cardNumberTextField setSecureTextEntry: YES];
    
    
    UITextField *expirationDateTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    expirationDateTextField  = [[UITextField alloc] initWithFrame:CGRectMake(16, 44, [UIScreen mainScreen].bounds.size.width/2, 44)];
    expirationDateTextField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
    expirationDateTextField.placeholder =  @"00 / 00";
    expirationDateTextField.textColor = [UIColor frescoDarkTextColor];
    expirationDateTextField.tintColor = [UIColor frescoBlueColor];
    [container addSubview:expirationDateTextField];
    
    expirationDateTextField.keyboardType = UIKeyboardTypeNumberPad;

    UITextField *securityCodeTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    securityCodeTextField  = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 , 44, [UIScreen mainScreen].bounds.size.width/2, 44)];
    securityCodeTextField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
    securityCodeTextField.placeholder =  @"CVV";
    securityCodeTextField.textColor = [UIColor frescoDarkTextColor];
    securityCodeTextField.tintColor = [UIColor frescoBlueColor];
    [container addSubview:securityCodeTextField];
    
    securityCodeTextField.keyboardType = UIKeyboardTypeNumberPad;
    
    cardNumberTextField.delegate = self;
    securityCodeTextField.delegate = self;
    expirationDateTextField.delegate = self;
    
    UIImageView *cardNumberCheckIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"acceptedNot"]];
    cardNumberCheckIV.frame = CGRectMake(self.view.frame.size.width - 30, 10, 24, 24);
    [container addSubview:cardNumberCheckIV];
    
    UIImageView *expirationDateCheckIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"acceptedNot"]];
    expirationDateCheckIV.frame = CGRectMake(self.view.frame.size.width/2 - 24 - 16, 54, 24, 24);
    [container addSubview:expirationDateCheckIV];
    
    UIImageView *CVVcheckIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"acceptedNot"]];
    CVVcheckIV.frame = CGRectMake(self.view.frame.size.width - 30, 54, 24, 24);
    [container addSubview:CVVcheckIV];
    
    UIView *top = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0.5)];
    top.alpha = 1;
    top.backgroundColor = [UIColor frescoLightTextColor];
    [container addSubview:top];
    
    UIView *middle = [[UIView alloc] initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, 0.5)];
    middle.alpha = 1;
    middle.backgroundColor = [UIColor frescoLightTextColor];
    [container addSubview:middle];
    
    UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(0, 88, self.view.bounds.size.width, 0.5)];
    bottom.alpha = 1;
    bottom.backgroundColor = [UIColor frescoLightTextColor];
    [container addSubview:bottom];
    
    UIButton *rightAlignedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightAlignedButton.frame =CGRectMake(self.view.frame.size.width - 105, cardViewport.frame.size.height + 88, 105, 44);
    [rightAlignedButton setTitle:@"SAVE CARD" forState:UIControlStateNormal];
    [rightAlignedButton.titleLabel setFont:[UIFont notaBoldWithSize:15]];
    [rightAlignedButton setTitleColor:[UIColor frescoLightTextColor] forState:UIControlStateNormal];
    
    [self.view addSubview:rightAlignedButton];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [CardIOUtilities preload];
    CardIOView *cardIOView = [[CardIOView alloc] initWithFrame:CGRectMake(0, -185, self.view.frame.size.width, self.view.frame.size.height)];
    cardIOView.delegate = self;
    
    [cardViewport addSubview:cardIOView];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)cardIOView:(CardIOView *)cardIOView didScanCard:(CardIOCreditCardInfo *)info {
    if (info) {
        // The full card number is available as info.cardNumber, but don't log that!
        NSLog(@"Received card info. Number: %@, expiry: %02i/%i, cvv: %@.", info.redactedCardNumber, info.expiryMonth, info.expiryYear, info.cvv);
        // Use the card info...
    }
    else {
        NSLog(@"User cancelled payment info");
        // Handle user cancellation here...
    }
    
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    return YES;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    [self.view endEditing:YES];
    return YES;
}


- (void)keyboardDidShow:(NSNotification *)notification
{    
    [UIView animateWithDuration:0.35 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.view setFrame:CGRectMake(0, 30, self.view.frame.size.width,self.view.frame.size.height)];
        
    } completion:nil];
}


-(void)keyboardDidHide:(NSNotification *)notification
{
    
    [UIView animateWithDuration:0.35 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self.view setFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
        
    } completion:nil];
}

@end