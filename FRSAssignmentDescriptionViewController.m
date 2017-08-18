//
//  FRSAssignmentDescriptionViewController.m
//  Fresco
//
//  Created by Omar Elfanek on 7/12/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import "FRSAssignmentDescriptionViewController.h"
#import "UIView+Helpers.h"
#import "FRSRadiusViewController.h"

@interface FRSAssignmentDescriptionViewController () <UITextViewDelegate>

@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) NSString *formattedTitle;

@end

@implementation FRSAssignmentDescriptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureNavigationBar];
    [self configureTextField];
    [self configureSpinner];
    
    self.view.backgroundColor = [UIColor frescoBackgroundColorDark];
    
}

- (void)configureNavigationBar {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
    label.text = @"DESCRIPTION";
    label.font = [UIFont notaBoldWithSize:17];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    
    [self configureBackButtonAnimated:YES];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationItem setTitleView:label];
}


- (void)configureTextField {
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - (self.view.frame.size.height/2))];
    containerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:containerView];
    [containerView addSubview:[UIView lineAtPoint:CGPointMake(0, containerView.frame.size.height)]];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(16, 16, self.view.frame.size.width - 32, containerView.frame.size.height -32)];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.font = [UIFont systemFontOfSize:15];
    [self.textView becomeFirstResponder];
    self.textView.tintColor = [UIColor frescoBlueColor];
    self.textView.delegate = self;
    self.textView.returnKeyType = UIReturnKeyNext;
    
    
    [containerView addSubview:self.textView];
    
    
    
//    if ([self.assignment[@"rating"] isEqual:@0]) {
    
        //this triggers method. dirty. sorry. v tired.
        NSString *string = [self formattedTextForAssignmentType:self.assignmentType];
        
//    } else {
//        self.textView.text = self.assignment[@"caption"];
//    }
    
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    nextButton.tintColor = [UIColor frescoBlueColor];
    [nextButton setTitle:@"NEXT" forState:UIControlStateNormal];
    [nextButton.titleLabel setFont:[UIFont notaBoldWithSize:17]];
    nextButton.frame = CGRectMake(self.view.frame.size.width -100, self.textView.frame.size.height +36, 100, 56);
    [self.view addSubview:nextButton];
    
}

- (void) next {
    NSMutableDictionary *mutableDict = [self.assignment mutableCopy];
    [mutableDict setObject:self.textView.text forKey:@"caption"];
    [mutableDict setObject:self.formattedTitle forKey:@"title"];
    
    self.assignment = [mutableDict mutableCopy];
    
    FRSRadiusViewController *locvc = [[FRSRadiusViewController alloc] init];
    locvc.assignment = self.assignment;
    [self.navigationController pushViewController:locvc animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        
        [self next];
        
        return NO;
    }
    
    return YES;
}

- (NSString *)formattedTextForAssignmentType:(AssignmentTypes)assignmentType {
    
    NSString *description = @"";
    NSString *title = @"";
    
    switch (assignmentType) {
            
        case TYPE_ACCIDENT:
            description = @"{OUTLET} seeks steady videos (must be a minimum of 3 videos in the 30 to 60 seconds range) of an accident at {ADDRESS} in {CITY, ST}. Capture the scene from a variety of angles, getting wide, medium, and tight shots, but please do not get in the way of police or medical professionals. Contact us through the Ask Us Anything function in the app if you have any questions about this or the price per photo/video earnings.";
            
            title = @"Major Accident in {CITY, ST}";
            break;
        case TYPE_BROLL:
            description = @"{OUTLET} is looking for supplemental footage (must be a minimum of 3 videos in the 30 to 60 seconds range), or b-roll, of {???} in {CITY, ST}. Capture wide, medium, tight, and steady shots from a variety of angles. Contact us through the Ask Us Anything function in the app if you have any questions about this or the price per photo/video earnings.";
            
            title = @"Video Needed! B-Roll of {NAME} in {CITY, ST}";
            break;
        case TYPE_BANK:
            description = @"There are reports of a robbery at {NAME} at {ADDRESS} in {CITY, ST}. Please be alert, maintain caution, and follow any evacuation instructions from authorities. If you have captured any content from the scene, we will accept it after you have reached a location of safety. You will be notified and paid if your content is used by a news partner.";
            
            title = @"Alert! Bank Robbery in {CITY, ST}";
            break;
        case TYPE_BOMB:
            description = @"There are reports of a bomb threat at {ADDRESS} in {CITY, ST}. Please be alert, maintain caution, and follow any evacuation instructions from authorities. If you have captured any content from the scene, we will accept it after you have reached a location of safety. You will be notified and paid if your content is used by a news partner.";
            
            title = @"Alert! Bomb Threat in {CITY, ST}";
            break;
        case TYPE_BUILDING_COLLAPSE:
            description = @"{OUTLET} seeks steady videos (must be a minimum of 3 videos in the 30 to 60 seconds range) of a building collapse scene at {ADDRESS} in {CITY, ST}. It is unclear if the structure is still unstable, so maintain safe distance. Do not put yourself in danger to capture content. Capture shots of any damage to the building, including debris on the scene, from a variety of angles. Please do not get in the way of authorities. You will be notified and paid if your content is used by a news partner.";
            
            title = @"Building Collapse in {CITY, ST}";
            break;
        case TYPE_EVENT:
            description = @"{OUTLET} seeks steady videos (must be a minimum of 3 videos in the 30 to 60 seconds range) of {EVENT} at {ADDRESS} in {CITY, ST}. The event starts at {START} {a.m./p.m.} and ends at {END} {a.m./p.m.} Capture shots of the event and any related activities. Capture wide, medium, and tight shots from a variety of angles. Contact us through the Ask Us Anything function in the app if you have any questions about this or the price per photo/video earnings.";
            
            title = @"{EVENT} @ {START} {a.m./p.m.} in {CITY, ST}";
            break;
        case TYPE_FIRE:
            description = @"{OUTLET} seeks steady videos (must be a minimum of 3 videos in the 30 to 60 seconds range) of a fire at {ADDRESS} in {CITY, ST}. Capture shots of the damage caused by the fire as well as any emergency response activity from a variety of angles, getting wide, medium, and tight shots. Please do not get in the way of any police, firefighters, or medical professionals. Contact us through the Ask Us Anything function in the app if you have any questions about this or the price per photo/video earnings.";
            
            title = @"Alert! Fire in {CITY, ST}";
            break;
        case TYPE_HAZ_SUSPICIOUS:
            description = @"It appears that {???} in {CITY, ST}. If you are in the area, please be alert, maintain caution, and follow any evacuation instructions from authorities. If you have captured any content from the scene, we will accept it after you have reached a location of safety. You will be notified and paid if your content is used by a news partner.";
            
            title = @"Alert! {EVENT} in {CITY, ST}";
            
            break;
        case TYPE_HIGH_SPEED_CHASE:
            description = @"There are reports of police chasing down a suspect {ON FOOT/IN A CAR} in the {LOCATION} of {CITY, ST}. If you are in the area, please be alert, maintain caution, and follow an evacuation instructions from authorities. If you have captured any content from the scene, we will accept it after you have reached a location of safety. You will be notified and paid if your content is used by a news partner.";
            
            title = @"Alert! Police Pursue Suspect in {CITY, ST}";
            
            break;
        case TYPE_SHOOTING_STABBING:
            description = @"There are reports of a {SHOOTING or STABBING} at {ADDRESS} in {CITY, ST}. If you are in the area, please be alert, maintain caution, and follow any evacuation instructions from authorities. If you have captured any content from the scene, we will accept it after you have reached a location of safety. You will be notified and paid if your content is used by a news partner.";
            
            title = @"Alert! Shooting in {CITY, ST}";
            
            break;
        case TYPE_RESCUE:
            description = @"{OUTLET} seeks steady videos (must be a minimum of 3 videos in the 30 to 60 seconds range) of a technical rescue underway at {ADDRESS} in {CITY, ST}. Capture content from a variety of angles. Please do not get in the way of authorities or medical professionals. Contact us through the Ask Us Anything function in the app if you have any questions about this or the price per photo/video earnings.";
            
            title = @"Technical Rescue in {CITY, ST}";
            
            break;
        case TYPE_TRAUMA:
            description = @"{OUTLET} seeks steady videos (must be a minimum of 3 videos in the 30 to 60 seconds range) of police activity and emergency crews responding to a trauma alert issued at {ADDRESS} in {CITY, ST}. Please do not get in the way of police or medical professionals. Contact us through the Ask Us Anything function in the app if you have any questions about this or the price per photo/video earnings.";
            
            title = @"Police Response to {EVENT} in {CITY, ST}";
            
            break;
        case TYPE_WEATHER:
            description = @"{OUTLET} seeks steady phone camera, DSLR, drone, and 360 degree camera videos (must be a minimum of 3 videos in the 30 to 60 seconds range) of the weather in {CITY, ST}. Capture content anywhere within the set radius. Take shots from a variety of angles, getting wide, medium, and tight shots. Contact us through the Ask Us Anything function in the app if you have any questions about this or the price per photo/video earnings.";
            
            title = @"Weather in {CITY, ST}";
            
            break;
            
        default:
            break;
    }
    
    NSString *appendedString = [NSString stringWithFormat:@"%@\n\n---\n\n%@", self.assignment[@"caption"], description];
    
    NSString *outletString = [appendedString stringByReplacingOccurrencesOfString:@"{OUTLET}" withString:[self.assignment[@"outlets"] objectAtIndex:0][@"title"]];
    
    CLGeocoder *ceo = [[CLGeocoder alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.assignment[@"location"][@"coordinates"][1] doubleValue] longitude:[self.assignment[@"location"][@"coordinates"][0] doubleValue]];
    [ceo reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error){
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        
        NSString *addressString = [outletString stringByReplacingOccurrencesOfString:@"{ADDRESS}" withString:placemark.name];
        NSString *cityStateString = [addressString stringByReplacingOccurrencesOfString:@"{CITY, ST}" withString:[NSString stringWithFormat:@"%@, %@", placemark.locality ? placemark.locality : placemark.subLocality, placemark.administrativeArea]];
        
        self.formattedTitle = [title stringByReplacingOccurrencesOfString:@"{CITY, ST}" withString:[NSString stringWithFormat:@"%@, %@", placemark.locality ? placemark.locality : placemark.subLocality, placemark.administrativeArea]];
        
        [self updateTextFieldWithString:cityStateString];
        [self removeSpinner];
    }];
    
    return outletString;
}

- (void)updateTextFieldWithString:(NSString *)string {
    
    if ([self.assignment[@"rating"] isEqual:@0]) {
        self.textView.attributedText = [FRSAssignmentDescriptionViewController formattedAttributedStringFromString:string];
    } else {
        self.textView.text = self.assignment[@"caption"];
    }
}

// PULL THIS OUT INTO IT'S OWN CLASS PLS

+ (NSAttributedString *)formattedAttributedStringFromString:(NSString *)text {
    
    // TODO: Fix this. Should detect between { }. Way too much room for error this way.
    
    NSRange range1 = [text rangeOfString:@"{ADDRESS}"];
    NSRange range2 = [text rangeOfString:@"{CITY, ST}"];
    NSRange range3 = [text rangeOfString:@"{???}"];
    NSRange range4 = [text rangeOfString:@"{NAME}"];
    NSRange range5 = [text rangeOfString:@"{EVENT}"];
    NSRange range6 = [text rangeOfString:@"{START} {a.m./p.m.}"];
    NSRange range7 = [text rangeOfString:@"{ON FOOT/IN A CAR}"];
    NSRange range8 = [text rangeOfString:@"{LOCATION}"];
    NSRange range9 = [text rangeOfString:@"{SHOOTING or STABBING}"];
    NSRange range10 = [text rangeOfString:@"{END} {a.m./p.m.}"];
    
    
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.lineHeightMultiple = 1.2;
    
    
    NSDictionary *attribs = @{
                              NSForegroundColorAttributeName : [[UIColor blackColor] colorWithAlphaComponent:0.87],
                              NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightRegular],
                              NSParagraphStyleAttributeName : paragraphStyle
                              };
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:attribs];
    UIFont *font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    NSDictionary *dictBoldText = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [UIColor redColor], NSForegroundColorAttributeName, nil];
    
    [attributedText setAttributes:dictBoldText range:range1];
    [attributedText setAttributes:dictBoldText range:range2];
    [attributedText setAttributes:dictBoldText range:range3];
    [attributedText setAttributes:dictBoldText range:range4];
    [attributedText setAttributes:dictBoldText range:range5];
    [attributedText setAttributes:dictBoldText range:range6];
    [attributedText setAttributes:dictBoldText range:range7];
    [attributedText setAttributes:dictBoldText range:range8];
    [attributedText setAttributes:dictBoldText range:range9];
    [attributedText setAttributes:dictBoldText range:range10];
    
    return attributedText;
}

- (void)configureSpinner {
    self.textView.userInteractionEnabled = NO;
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.textView addSubview:activityIndicator];
    activityIndicator.tag = 999;
    activityIndicator.frame = CGRectMake(self.textView.frame.size.width/2 - 12, self.textView.frame.size.height/2 - 12, 24, 24);
    [activityIndicator startAnimating];
}

- (void)removeSpinner {
    self.textView.userInteractionEnabled = YES;
    UIView *removeView;
    while((removeView = [self.view viewWithTag:999]) != nil) {
        [removeView removeFromSuperview];
    }
}

@end