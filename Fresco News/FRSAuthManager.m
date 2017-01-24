//
//  FRSAuthManager.m
//  Fresco
//
//  Created by User on 1/3/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import "FRSAuthManager.h"
#import "FRSUserManager.h"
#import "EndpointManager.h"
#import "NSString+Fresco.h"

@implementation FRSAuthManager

+ (instancetype)sharedInstance {
    static FRSAuthManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[FRSAuthManager alloc] init];
    });
    return instance;
}

- (BOOL)isAuthenticated {
    if ([[SAMKeychain accountsForService:serviceName] count] > 0) {
        return TRUE;
    }
    return FALSE;
}

- (NSString *)authenticationToken {
    NSArray *allAccounts = [SAMKeychain accountsForService:serviceName];

    if ([allAccounts count] == 0) {
        return Nil;
    }

    NSDictionary *credentialsDictionary = [allAccounts firstObject];
    NSString *accountName = credentialsDictionary[kSAMKeychainAccountKey];

    return [SAMKeychain passwordForService:serviceName account:accountName];
}

- (void)handleUserLogin:(id)responseObject {
    if ([responseObject objectForKey:@"token"]) {
        [self saveToken:[responseObject objectForKey:@"token"] forUser:[EndpointManager sharedInstance].currentEndpoint.frescoClientId];
    }

    FRSUser *authenticatedUser = [[FRSUserManager sharedInstance] authenticatedUser];

    if (!authenticatedUser) {
        authenticatedUser = [NSEntityDescription insertNewObjectForEntityForName:@"FRSUser" inManagedObjectContext:[self managedObjectContext]];
    }

    [[FRSAPIClient sharedClient] reevaluateAuthorization];
    [[FRSUserManager sharedInstance] updateLocalUser];

    NSDictionary *currentInstallation = [self currentInstallation];

    if ([currentInstallation objectForKey:@"device_token"]) {
        NSDictionary *update = @{ @"installation" : currentInstallation };
        [[FRSUserManager sharedInstance] updateUserWithDigestion:update
                                                      completion:^(id responseObject, NSError *error){
                                                      }];
    }
}

- (void)registerWithUserDigestion:(NSDictionary *)digestion completion:(FRSAPIDefaultCompletionBlock)completion {
    // email
    // username
    // password
    // twitter_handle
    // social_links
    // installation

    if (digestion[@"password"]) {
        self.passwordUsed = digestion[@"password"];
    } else {
        self.socialUsed = digestion[@"social_links"];
    }

    [[FRSAPIClient sharedClient] post:signUpEndpoint
                       withParameters:digestion
                           completion:^(id responseObject, NSError *error) {

                             if ([responseObject objectForKey:@"token"] && ![responseObject objectForKey:@"err"]) {
                                 // [self saveToken:[responseObject objectForKey:@"token"] forUser:clientAuthorization];
                                 [self handleUserLogin:responseObject];
                             }

                             completion(responseObject, error);
                           }];
}

- (void)updateLegacyUserWithDigestion:(NSDictionary *)digestion completion:(FRSAPIDefaultCompletionBlock)completion {
    NSMutableDictionary *mutableDigestion = [digestion mutableCopy];

    if (self.passwordUsed) {
        [mutableDigestion setObject:self.passwordUsed forKey:@"verify_password"];
    } else if (self.socialUsed && !self.passwordUsed) {
        [mutableDigestion addEntriesFromDictionary:self.socialUsed];
    }

    [[FRSUserManager sharedInstance] updateUserWithDigestion:mutableDigestion completion:completion];
}

- (void)logout {
    NSArray *allAccounts = [SAMKeychain allAccounts];

    for (NSDictionary *account in allAccounts) {
        NSString *accountName = account[kSAMKeychainAccountKey];
        [SAMKeychain deletePasswordForService:serviceName account:accountName];
    }
}

- (NSString *)tokenForUser:(NSString *)userName {
    return [SAMKeychain passwordForService:serviceName account:userName];
}

- (void)saveToken:(NSString *)token forUser:(NSString *)userName {
    [SAMKeychain setPasswordData:[token dataUsingEncoding:NSUTF8StringEncoding] forService:serviceName account:userName];
}

// all info needed for "installation" field of registration/signin
- (NSDictionary *)currentInstallation {

    NSMutableDictionary *currentInstallation = [[NSMutableDictionary alloc] init];
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceToken"];

    if (deviceToken != Nil || [deviceToken isEqual:[NSNull null]]) {
        currentInstallation[@"device_token"] = deviceToken;
    } else {
    }

    NSString *sessionID = [[NSUserDefaults standardUserDefaults] objectForKey:@"SESSION_ID"];

    if (sessionID) {
        currentInstallation[@"device_id"] = sessionID;
    } else {
        sessionID = [NSString randomString];
        currentInstallation[@"device_id"] = sessionID;
        [[NSUserDefaults standardUserDefaults] setObject:sessionID forKey:@"SESSION_ID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    currentInstallation[@"platform"] = @"ios";

    NSString *appVersion = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];

    if (appVersion) {
        currentInstallation[@"app_version"] = appVersion;
    }

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    NSString *timeZone = [dateFormat stringFromDate:[NSDate date]];

    if (timeZone) {
        currentInstallation[@"timezone"] = timeZone;
    }

    NSString *localeString = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];

    if (localeString) {
        currentInstallation[@"locale_identifier"] = localeString;
    }

    return currentInstallation;
}

- (void)signIn:(NSString *)user password:(NSString *)password completion:(FRSAPIDefaultCompletionBlock)completion {
    self.passwordUsed = password;

    NSDictionary *params = @{ @"username" : user,
                              @"password" : password };

    [[FRSAPIClient sharedClient] post:loginEndpoint
                       withParameters:params
                           completion:^(id responseObject, NSError *error) {

                             completion(responseObject, error);
                             if (!error) {
                                 [self handleUserLogin:responseObject];
                             }
                           }];
}

/*
 Sign in: all expect user to have an account, either returns a token, a challenge (i.e. 'create an account') or incorrect details
 */
- (void)signInWithTwitter:(TWTRSession *)session completion:(FRSAPIDefaultCompletionBlock)completion {
    NSString *twitterAccessToken = session.authToken;
    NSString *twitterAccessTokenSecret = session.authTokenSecret;
    NSDictionary *authDictionary = @{ @"platform" : @"twitter",
                                      @"token" : twitterAccessToken,
                                      @"secret" : twitterAccessTokenSecret };
    self.socialUsed = authDictionary;

    [[FRSAPIClient sharedClient] post:socialLoginEndpoint
                       withParameters:authDictionary
                           completion:^(id responseObject, NSError *error) {
                             completion(responseObject, error);
                             // handle cacheing of authentication
                             if (!error) {
                                 [self handleUserLogin:responseObject];
                             }

                           }];
}

- (void)signInWithFacebook:(FBSDKAccessToken *)token completion:(FRSAPIDefaultCompletionBlock)completion {
    NSString *facebookAccessToken = token.tokenString;
    NSDictionary *authDictionary = @{ @"platform" : @"facebook",
                                      @"token" : facebookAccessToken };
    self.socialUsed = authDictionary;

    [[FRSAPIClient sharedClient] post:socialLoginEndpoint
                       withParameters:authDictionary
                           completion:^(id responseObject, NSError *error) {
                             completion(responseObject, error); // burden of error handling falls on sender

                             // handle internal cacheing of authentication
                             if (!error) {
                                 [self handleUserLogin:responseObject];
                             }
                           }];
}

@end
