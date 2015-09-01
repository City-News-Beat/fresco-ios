//
//  FRSAppConstants.h
//  Fresco
//
//  Created by Nicolas Rizk on 8/3/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIColor+Additions.h"
#import "FRSAlertViewManager.h"

/*
 ** Add four spaces in between sections
*/


#pragma mark - Enums

enum FRSErrorCodes {
    ErrorSignupDuplicateEmail = 101,
    ErrorSignupCantCreateUser,
    ErrorSignupCantSaveUser,
    ErrorSignupCantGetUser,
    ErrorSignupNoUserOnServer,
    ErrorSignupNoUserFromParseUser,
} frsErrorCodes;




#pragma mark - Notification Strings

#define NOTIF_API_KEY_AVAILABLE             @"NotificationAPIKeyAvailable"
#define NOTIF_VIEW_DISMISS                  @"DismissNotificationsView"
#define NOTIF_BADGE_RESET                   @"ResetNotificationBadge"
#define NOTIF_IMAGE_SET                     @"UserProfileImageChanged"
#define NOTIF_REACHABILITY_MONITORING       @"ReachabilityManagerIsMonitoring"
#define NOTIF_ONBOARD                       @"Onboard"
#define NOTIF_PROFILE_PIC_RESET             @"ProfilePicReset"




#pragma mark - Keys Plist

#define KEYS_PLIST_PATH                     [[NSBundle mainBundle] pathForResource:@"Keys" ofType:@"plist"]
#define KEYS_DICTIONARY                     [NSDictionary dictionaryWithContentsOfFile:KEYS_PLIST_PATH]




#pragma mark - Base URL/API & Parse

#define ERROR_DOMAIN                        @"com.fresconews"

#define BASE_PATH                           @""

#ifdef DEBUG
    #define BASE_URL                        @"https://alpha.fresconews.com"
    #define BASE_API                        @"http://staging.fresconews.com/v1/"
    #define PARSE_APP_ID                    [KEYS_DICTIONARY objectForKey:@"StagingParseAppID"]
    #define PARSE_CLIENT_KEY                [KEYS_DICTIONARY objectForKey:@"StagingParseClientKey"]
#else
    #define BASE_URL                        @"https://fresconews.com"
    #define BASE_API                        @"https://api.fresconews.com/v1/"
    #define PARSE_APP_ID                    [KEYS_DICTIONARY objectForKey:@"ProductionParseAppID"]
    #define PARSE_CLIENT_KEY                [KEYS_DICTIONARY objectForKey:@"ProductionParseClientKey"]
#endif




#pragma mark - Twitter Auth

#define TWITTER_CONSUMER_KEY                [KEYS_DICTIONARY objectForKey:@"TwitterConsumerKey"]
#define TWITTER_CONSUMER_SECRET             [KEYS_DICTIONARY objectForKey:@"TwitterConsumerSecret"]
#define TWITTER_USERS_SHOW_URL              @"https://api.twitter.com/1.1/users/show.json?"
#define TWITTER_VERIFY_URL                  @"https://api.twitter.com/1.1/account/verify_credentials.json"




#pragma mark - Float/Int Values

#define MAX_VIDEO_LENGTH                    60.0f
#define MAX_ASSET_AGE                       -3600 * 6
#define LOCATION_UPDATE_INTERVAL            60




#pragma mark - User Defaults

#define UD_FIRSTNAME                        @"firstname"
#define UD_LASTNAME                         @"lastname"
#define UD_AVATAR                           @"avatar"
#define UD_TOKEN                            @"frescoAPIToken"
#define UD_NOTIF_SETTINGS                   @"notificationSetting"
#define UD_CAPTION_STRING_IN_PROGRESS       @"captionStringInProgress"
#define UD_DEFAULT_ASSIGNMENT_ID            @"defaultAssignmentID"
#define UD_SELECTED_ASSETS                  @"selectedAssets"
#define UD_NOTIFICATIONS_COUNT              @"notificationsCount"
#define UD_PREVIOUSLY_SELECTED_TAB          @"previouslySelectedTab"
#define UD_HAS_LAUNCHED_BEFORE              @"hasLaunchedBefore"
#define UD_ASSIGNMENTS_ONBOARDING           @"assignmentsOnboarding"
#define UD_UPDATE_PROFILE_HEADER            @"updateProfileHeader"
#define UD_UPDATE_PROFILE                   @"updateProfile"
#define UD_UPDATE_USER_GALLERIES            @"updateUserGalleries"




#pragma mark - Fonts

#define HELVETICA_NEUE_MEDIUM               @"HelveticaNeue-Medium"
#define HELVETICA_NEUE_LIGHT                @"HelveticaNeue-Light"
#define HELVETICA_NEUE_THIN                 @"HelveticaNeue-Thin"
#define HELVETICA_NEUE_REGULAR              @"HelveticaNeue"




#pragma mark - MapView Identifiers

#define ASSIGNMENT_IDENTIFIER               @"AssignmentAnnotation"
#define CLUSTER_IDENTIFIER                  @"ClusterAnnotation"
#define USER_IDENTIFIER                     @"currentLocation"
#define kMetersInAMile                      1609.34


#pragma mark - Segue Identifiers

#define SEG_SHOW_ACCT_INFO                  @"showAccountInfo"
#define SEG_REPLACE_WITH_SIGNUP             @"replaceWithSignUp"
#define SEG_SIGNUP_REPLACE_WITH_TOS         @"signup_replaceWithTOS"
#define SEG_SHOW_PERMISSIONS                @"showPermissions"
#define SEG_SHOW_RADIUS                     @"showRadius"
#define SEG_SETTINGS                        @"settingsSegue"
#define SEG_PRESENT_TOS                     @"presentTOS"



#pragma mark - Notification Categories/Actions

#define ASSIGNMENT_CATEGORY                 @"ASSIGNMENT_CATEGORY"
#define NAVIGATE_IDENTIFIER                 @"NAVIGATE_IDENTIFIER"



#pragma mark - User-facing Strings -



#pragma mark - Brand Names / Trademarks

#define FRESCO                              @"Fresco" // Not localizing name i.e. would be Fresh in Spanish
#define FACEBOOK                            @"Facebook"
#define TWITTER                             @"Twitter"


#pragma mark - Global Macros

#define OK                                  NSLocalizedString(@"OK", nil)
#define DISMISS                             NSLocalizedString(@"Dismiss", nil)
#define DISABLE                             NSLocalizedString(@"Disable", nil)
#define CANCEL                              NSLocalizedString(@"Cancel", nil)
#define ERROR                               NSLocalizedString(@"Error", nil)
#define SUCCESS                             NSLocalizedString(@"Success", nil)
#define DONE                                NSLocalizedString(@"Done", nil)
#define NEXT                                NSLocalizedString(@"Next", nil)
#define STR_TRY_AGAIN                       NSLocalizedString(@"Try Again", nil)
#define OFF                                 NSLocalizedString(@"Off", nil)
#define WARNING                             NSLocalizedString(@"Warning", nil)
#define WHATS_HAPPENING                     NSLocalizedString(@"What's happening?", nil)



#pragma mark - First Run Log in / Sign up

#define LOGIN                               NSLocalizedString(@"Login", nil)
#define LOGIN_ERROR                         NSLocalizedString(@"Login Error", nil)
#define LOGIN_PROMPT                        NSLocalizedString(@"Please enter a valid email and password", nil)

#define SIGNUP_ERROR                        NSLocalizedString(@"It seems there was an error signing you up. Please try again in a bit.", nil)

#define NAME_PROMPT                         NSLocalizedString(@"Please enter both first and last name", nil)
#define NAME_ERROR_MSG                      NSLocalizedString(@"We could not successfully save your first and last name", nil)

#define AVATAR_PROMPT                       NSLocalizedString(@"Choose a new avatar", nil)

#define NOTIF_RADIUS_ERROR_MSG              NSLocalizedString(@"Could not save notification radius", nil)

#define DISABLE_ACCT_TITLE                  NSLocalizedString(@"Are you sure? You can recover your account up to one year from today.", nil)
#define DISABLE_ACCT_ERROR                  NSLocalizedString(@"It seems we couldn't successfully disable your account. Please contact support@fresconews.com for help.", nil)

#define PROFILE_SAVE_ERROR                  NSLocalizedString(@"Could not save Profile settings", nil)

#define PASSWORD_ERROR_TITLE                NSLocalizedString(@"Passwords do not match", nil)
#define PASSWORD_ERROR_MESSAGE              NSLocalizedString(@"Please make sure your new passwords are equal", nil)

#define INVALID_CREDENTIALS                 NSLocalizedString(@"Invalid Credentials", nil)

#define TWITTER_ERROR                       NSLocalizedString(@"We ran into an error signing you in with Twitter", nil)
#define FACEBOOK_ERROR                      NSLocalizedString(@"We ran into an error signing you in with Facebook", nil)



#pragma mark - First Run Permissions

#define CAMERA_ENABLED                      NSLocalizedString(@"Camera Enabled", nil)
#define CAMERA_DISABLED                     NSLocalizedString(@"Camera Disabled", nil)

#define LOC_ENABLED                         NSLocalizedString(@"Location Enabled", nil)
#define LOC_DISABLED                        NSLocalizedString(@"Location Disabled", nil)

#define NOTIF_PENDING                       NSLocalizedString(@"Notifications Pending", nil)
#define NOTIF_ENABLED                       NSLocalizedString(@"Notifications Enabled", nil)

#define ENABLE_CAMERA_TITLE                 NSLocalizedString(@"Enable Camera", nil)
#define ENABLE_CAMERA_MSG                   NSLocalizedString(@"needs permission to access the camera to continue.", nil)

#define GO_TO_SETTINGS                      NSLocalizedString(@"It seems like your camera isn't enabled. Please go to settings for Fresco to enable the camera.", nil)

#pragma mark - First Run Radius

#define NOTIF_RADIUS_ERROR_MSG              NSLocalizedString(@"Could not save notification radius", nil)

#pragma mark - First Run TOS

#define T_O_S_UNAVAILABLE_MSG               NSLocalizedString(@"Terms of Service not available", nil)




#pragma mark - Profile Settings

#define AVATAR_PROMPT                       NSLocalizedString(@"Choose a new avatar", nil)

#define PROFILE_SAVE_ERROR                  NSLocalizedString(@"Could not save Profile settings", nil)

#define DISABLE_ACCT_TITLE                  NSLocalizedString(@"Are you sure? You can recover your account up to one year from today.", nil)
#define DISABLE_ACCT_ERROR                  NSLocalizedString(@"It seems we couldn't successfully disable your account. Please contact support@fresconews.com for help.", nil)
#define ACCT_WILL_BE_DISABLED               NSLocalizedString(@"Account will be disabled", nil)

#define WELL_MISS_YOU                       NSLocalizedString(@"We'll miss you!", nil)
#define YOU_CAN_LOGIN_FOR_ONE_YR            NSLocalizedString(@"You can log in any time in the next year to restore your account.", nil)

#define FB_LOGOUT_PROMPT                    NSLocalizedString(@"It seems like you logged in through Facebook. If you disconnect it, this would disable your account entirely!", nil)

#define NOTHING_HERE_YET                    NSLocalizedString(@"Nothing here yet!", nil)
#define OPEN_CAMERA                         NSLocalizedString(@"Open your camera to get started", nil)




#pragma mark - Unused

#define NAVIGATE_STR                        NSLocalizedString(@"Navigate", nil)
#define NAVIGATE_TO_ASSIGNMENT              NSLocalizedString(@"Navigate to the assignment", nil)



#pragma mark - Onboarding

#define MAIN_HEADER_1                       NSLocalizedString(@"Find breaking news around you", nil)
#define MAIN_HEADER_2                       NSLocalizedString(@"Submit your photos and videos", nil)
#define MAIN_HEADER_3                       NSLocalizedString(@"See your work in the news", nil)

#define SUB_HEADER_1                        NSLocalizedString(@"Keep an eye out, or use Fresco to view a map of nearby events being covered by news outlets", nil)
#define SUB_HEADER_2                        NSLocalizedString(@"Your media is visible not only to Fresco users, but to our news organization partners in need of visual coverage", nil)
#define SUB_HEADER_3                        NSLocalizedString(@"We notify you when your photos and videos are used, and you'll get paid if you took them for an assignment", nil)


#pragma mark - Highlights

#define HIGHLIGHTS                          NSLocalizedString(@"Highlights", nil)


#pragma mark - Stories

#define STORIES                             NSLocalizedString(@"Stories", nil)


#pragma mark - Notifications

#define VIEW                                NSLocalizedString(@"View", nil)
#define VIEW_ASSIGNMENT                     NSLocalizedString(@"View Assignment", nil)

#define ASSIGNMENT_EXPIRED_TITLE            NSLocalizedString(@"Assignment Expired", nil)
#define ASSIGNMENT_EXPIRED_MSG              NSLocalizedString(@"This assignment has expired already!", nil)

#define OPEN_IN_MAPS                        NSLocalizedString(@"Open in Maps", nil)
#define OPEN_IN_GOOG_MAPS                   NSLocalizedString(@"Open in Google Maps", nil)

#define GALLERY_UNAVAILABLE_TITLE           NSLocalizedString(@"Gallery Unavailable", nil)
#define GALLERY_UNAVAILABLE_MSG             NSLocalizedString(@"We couldn't find this gallery!", nil)




#pragma mark - Device Macros


#define IS_OS_8_OR_LATER                    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

#define IS_IPAD                             (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define IS_IPHONE                           (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#define IS_IPHONE_4S                       (IS_IPHONE && ([[UIScreen mainScreen] bounds].size.height < 568.0) && ((IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale) || !IS_OS_8_OR_LATER))

#define IS_IPHONE_5                         (IS_IPHONE && ([[UIScreen mainScreen] bounds].size.height == 568.0) && ((IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale) || !IS_OS_8_OR_LATER))

#define IS_STANDARD_IPHONE_6                (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0  && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale)

#define IS_ZOOMED_IPHONE_6                  (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale > [UIScreen mainScreen].scale)

#define IS_STANDARD_IPHONE_6_PLUS           (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0)

#define IS_ZOOMED_IPHONE_6_PLUS             (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale < [UIScreen mainScreen].scale)
