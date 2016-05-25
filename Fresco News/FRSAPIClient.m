//
//  FRSAPIClient.m
//  Fresco
//
//  Created by Daniel Sun on 1/11/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSAPIClient.h"
#import "Fresco.h"
#import "FRSPost.h"
#import "FRSFileUploadManager.h" // temp patch

@implementation FRSAPIClient

/*
 Singleton
 */

+(instancetype)sharedClient {
    static FRSAPIClient *client = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        client = [[FRSAPIClient alloc] init];
    });
    
    return client;
}

-(id)init {
    self = [super init];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLocationUpdate:)
                                                     name:FRSLocationUpdateNotification
                                                   object:nil];
    }
    
    return self;
}

-(void)handleError:(NSError *)error {
    switch (error.code/100) {
        case 5:
            // server error
            break;
        case 4:
            // client error
            switch (error.code) {
                case 401:
                    
                    break;
                case 403:
                    
                    break;
                case 404:
                    
                    break;
                case 405:
                    
                    break;
                default:
                    break;
            }
            break;
        
        case 3:
            // redirection
            break;
            
        case 2:
            // prolly not an error
            break;
            
        default:
            break;
    }
}

-(void)signIn:(NSString *)user password:(NSString *)password completion:(FRSAPIDefaultCompletionBlock)completion {
    [self post:loginEndpoint withParameters:@{@"username":user, @"password":password} completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
        if (!error) {
            [self handleUserLogin:responseObject];
        }
    }];
}

/*
    Sign in: all expect user to have an account, either returns a token, a challenge (i.e. 'create an account') or incorrect details
 */
-(void)signInWithTwitter:(TWTRSession *)session completion:(FRSAPIDefaultCompletionBlock)completion {
    NSString *twitterAccessToken = session.authToken;
    NSString *twitterAccessTokenSecret = session.authTokenSecret;
    NSDictionary *authDictionary = @{@"platform" : @"twitter", @"token" : twitterAccessToken, @"secret" : twitterAccessTokenSecret};
    
    [self post:socialLoginEndpoint withParameters:authDictionary completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
        // handle cacheing of authentication
        if (!error) {
            [self handleUserLogin:responseObject];
        }
        
        NSLog(@"%@ %@", error, responseObject);
    }];
}

-(void)signInWithFacebook:(FBSDKAccessToken *)token completion:(FRSAPIDefaultCompletionBlock)completion {
    NSString *facebookAccessToken = token.tokenString;
    NSDictionary *authDictionary = @{@"platform" : @"facebook", @"token" : facebookAccessToken};

    [self post:socialLoginEndpoint withParameters:authDictionary completion:^(id responseObject, NSError *error) {
        completion(responseObject, error); // burden of error handling falls on sender
        
        // handle internal cacheing of authentication
        if (!error) {
            [self handleUserLogin:responseObject];
        }
    }];
}

-(void)registerWithUserDigestion:(NSDictionary *)digestion completion:(FRSAPIDefaultCompletionBlock)completion {
    // email
    // username
    // password
    // twitter_handle
    // social_links
    // installation
    
    
    [self post:signUpEndpoint withParameters:digestion completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
}

-(void)checkEmail:(NSString *)email completion:(FRSAPIDefaultCompletionBlock)completion {
    [self check:email completion:completion];
}
-(void)checkUsername:(NSString *)username completion:(FRSAPIDefaultCompletionBlock)completion {
    [self check:username completion:completion];
}

-(void)check:(NSString *)check completion:(FRSAPIDefaultCompletionBlock)completion {
    NSString *checkEndpoint = [userEndpoint stringByAppendingString:check];
    
    [self get:checkEndpoint withParameters:Nil completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
}

-(void)updateUserWithDigestion:(NSDictionary *)digestion completion:(FRSAPIDefaultCompletionBlock)completion {
    
    // ** WARNING ** Don't update users info just to update it, update it only if new (i.e. changing email to identical email has resulted in issues with api v1)
    // full_name: User's full name
    // bio: User's profile bio
    // avatar: User's avatar URL
    // installation
    // social links
    
    [self post:updateUserEndpoint withParameters:digestion completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
    
}

-(FRSUser *)authenticatedUser {
    
    // predicate searching for users in store w/ loggedIn as TRUE/1
    NSPredicate *signedInPredicate = [NSPredicate predicateWithFormat:@"%K like %@", @"isLoggedIn", @(TRUE)];
    NSFetchRequest *signedInRequest = [NSFetchRequest fetchRequestWithEntityName:@"FRSUser"];
    signedInRequest.predicate = signedInPredicate;
    
    // get context from app deleegate (hate this dependency but no need to re-write rn to move up)
    NSManagedObjectContext *context = [FRSFileUploadManager uploaderContext]; // temp (replace with internal or above method
    
    // no need to sort response, because theoretically there is 1
    NSError *userFetchError;
    NSArray *authenticatedUsers = [context executeFetchRequest:signedInRequest error:&userFetchError];
    
    // no authenticated user, or we had trouble accessing data store
    if (userFetchError || [authenticatedUsers count] < 1) {
        return Nil;
    }
    
    // if we have multiple "authenticated" users in data store, we probs messed up big time
    if ([authenticatedUsers count] > 1) {
        NSLog(@"**WARNING**: Indication of multiple authenciated users: %@", authenticatedUsers);
        @throw [NSException exceptionWithName:@"FRSMultiAuth" reason:@"Multiple users" userInfo:@{@"users":authenticatedUsers}];
    }
    
    return [authenticatedUsers firstObject];
}


// all the info needed for "social_links" field of registration/signin
-(NSDictionary *)socialDigestionWithTwitter:(TWTRSession *)twitterSession facebook:(FBSDKAccessToken *)facebookToken {
    // side note, twitter_handle is outside social links, needs to be handled outside this method
    NSMutableDictionary *socialDigestion = [[NSMutableDictionary alloc] init];
    
    if (twitterSession) {
        // add twitter to digestion
        if (twitterSession.authToken && twitterSession.authTokenSecret) {
            NSDictionary *twitterDigestion = @{@"token":twitterSession.authToken, @"secret": twitterSession.authTokenSecret};
            [socialDigestion setObject:twitterDigestion forKey:@"twitter"];
        }
    }
    
    if (facebookToken) {
        // add facebook to digestion
        if (facebookToken.tokenString) {
            NSDictionary *facebookDigestion = @{@"token":facebookToken.tokenString};
            [socialDigestion setObject:facebookDigestion forKey:@"facebook"];
        }
    }
    
    return socialDigestion;
}


// all info needed for "installation" field of registration/signin
-(NSDictionary *)currentInstallation {
    
    NSMutableDictionary *currentInstallation = [[NSMutableDictionary alloc] init];
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"deviceToken"];
    
    if (deviceToken) {
        currentInstallation[@"device_token"] = deviceToken;
    }
    else {
        return Nil; // no installation without push info, apparently
    }
    
    currentInstallation[@"platform"] = @"ios";
    
    NSString *appVersion = [NSString stringWithFormat:@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    if (appVersion) {
        currentInstallation[@"app_version"] = appVersion;
    }

    
    /*
     If we ever choose to move towards a UTC+X approach in timezones, as opposed to the unix timestamp that includes the current timezone, this is how we would do it.
     
    NSInteger secondsFromGMT = [[NSTimeZone localTimeZone] secondsFromGMT];
    NSInteger hoursFromGMT = secondsFromGMT / 60; // GMT = UTC
    NSString *timeZone = [NSString stringWithFormat:@"UTC+%d", (int)hoursFromGMT]; 
    */
    
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

-(void)handleUserLogin:(id)responseObject {
    if ([responseObject objectForKey:@"token"] && ![responseObject objectForKey:@"err"]) {
        [self saveToken:[responseObject objectForKey:@"token"] forUser:clientAuthorization];
    }
    
    [self reevaluateAuthorization];
    [self updateLocalUser];
}

-(void)updateLocalUser {
    if (![self isAuthenticated]) {
        return;
    }
    
    [self get:authenticatedUserEndpoint withParameters:Nil completion:^(id responseObject, NSError *error) {
        if (error) {
            return;
        }
        
        // set up FRSUser object with this info, set authenticated to true
    }];
}

-(void)fetchGalleriesForUser:(FRSUser *)user completion:(FRSAPIDefaultCompletionBlock)completion {
 
}

-(void)pingLocation:(NSDictionary *)location completion:(FRSAPIDefaultCompletionBlock)completion {
    if (![self isAuthenticated]) {
        return;
    }
    
    [self post:locationEndpoint withParameters:location completion:^(id responseObject, NSError *error) {
        
    }];
}

-(void)handleLocationUpdate:(NSNotification *)userInfo {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUserLocation:userInfo.userInfo completion:^(NSDictionary *response, NSError *error) {
            if (!error) {
                NSLog(@"Sent Location");
            }
            else {
                NSLog(@"Location Error: %@", error);
            }
        }];
    });
}

/*
 
 Fetch assignments w/in radius of user location, calls generic method w/ parameters & endpoint
 
 */
-(void)getAssignmentsWithinRadius:(float)radius ofLocation:(NSArray *)location withCompletion:(FRSAPIDefaultCompletionBlock)completion{

    NSMutableDictionary *geoData = [[NSMutableDictionary alloc] init];
    [geoData setObject:@"Point" forKey:@"type"];
    [geoData setObject:location forKey:@"coordinates"];
    NSLog(@"%@", geoData);
    
    NSDictionary *params = @{
                             @"geo" : geoData,
                             @"radius" : @(radius),
                            };
    
    NSLog(@"%@", params);
    
    [self get:assignmentsEndpoint withParameters:params completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
    
}

#pragma mark - Gallery Fetch

/*
 
 Fetch galleries w/ limit, calls generic method w/ parameters & endpoint
 
 */

-(void)fetchGalleriesWithLimit:(NSInteger)limit offsetGalleryID:(NSString *)offset completion:(void(^)(NSArray *galleries, NSError *error))completion {
    
    NSDictionary *params = @{
                        @"limit" : [NSNumber numberWithInteger:limit],
                        @"last" : (offset != Nil) ? offset : @"",
                    };
    
    if (!offset) {
        params = @{
                   @"limit" : [NSNumber numberWithInteger:limit],
                   };
    }
    
    [self get:highlightsEndpoint withParameters:params completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
}

-(void)fetchGalleriesInStory:(NSString *)storyID completion:(void(^)(NSArray *galleries, NSError *error))completion {
    
    NSString *endpoint = [storyGalleriesEndpoint stringByAppendingString:storyID];
    
    [self get:endpoint withParameters:Nil completion:^(id responseObject, NSError *error) {
        NSLog(@"%@", responseObject);
        
        completion(responseObject, error);
    }];
}

-(void)getRecentGalleriesFromLastGalleryID:(NSString *)galleryID completion:(void(^)(NSArray *galleries, NSError *error))completion {
    
}

-(void)fetchStoriesWithLimit:(NSInteger)limit lastStoryID:(NSString *)offsetID completion:(void(^)(NSArray *stories, NSError *error))completion {
    
    NSDictionary *params = @{
                             @"limit" : [NSNumber numberWithInteger:limit],
                             @"last" : (offsetID != Nil) ? offsetID : @""
                            };
    
    if (!offsetID) {
        params = @{
                    @"limit" : [NSNumber numberWithInteger:limit],
                };
    }
    
    [self get:storiesEndpoint withParameters:params completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
}

-(void)startLocator {
    [FRSLocator sharedLocator];
}

-(void)updateUserLocation:(NSDictionary *)inputParams completion:(void(^)(NSDictionary *response, NSError *error))completion
{
    if (![self isAuthenticated]) {
        return;
    }
    
    [self post:@"user/locate" withParameters:inputParams completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
        
}

-(void)fetchFollowing:(void(^)(NSArray *galleries, NSError *error))completion {
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"following" ofType:@"json"]];
    NSError *jsonError;
    NSDictionary *fakeData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    completion(fakeData[@"data"], jsonError);
}


-(AFHTTPRequestOperationManager *)managerWithFrescoConfigurations {
    
    if (!self.requestManager) {
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:baseURL]];
        self.requestManager = manager;
        [self.requestManager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        self.requestManager.responseSerializer = [[FRSJSONResponseSerializer alloc] init];
    }
    
    [self reevaluateAuthorization];
    
    return self.requestManager;
}

-(void)createGallery:(FRSGallery *)gallery completion:(FRSAPIDefaultCompletionBlock)completion {
    
    NSArray *posts = [gallery.posts allObjects];
    NSMutableDictionary *galleryDigest = [[NSMutableDictionary alloc] init];
    NSMutableArray *postsToSend = [[NSMutableArray alloc] init];

    for (FRSPost *post in posts) {
        NSMutableDictionary *currentPost = [[NSMutableDictionary alloc] init];
        currentPost[@"address"] = (post.address) ? post.address : @"";
        currentPost[@"lat"] = @(post.location.coordinate.latitude);
        currentPost[@"lng"] = @(post.location.coordinate.longitude);
        currentPost[@"contentType"] = (post.contentType) ? post.contentType : @"image/jpeg";
        
        if (post.videoUrl) {
            currentPost[@"fileSize"] = [self fileSizeForURL:[NSURL fileURLWithPath:post.videoUrl]];
            currentPost[@"chunkSize"] = @(5242880); // 5mb in bytes
        }
        
        [postsToSend addObject:currentPost];
    }
    
    galleryDigest[@"caption"] = (gallery.caption) ? gallery.caption : @"";
    galleryDigest[@"posts"] = posts;
    
    [self post:createGalleryEndpoint withParameters:galleryDigest completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
}

-(void)addTwitter:(TWTRSession *)twitterSession completion:(FRSAPIDefaultCompletionBlock)completion {
    NSMutableDictionary *twitterDictionary = [[NSMutableDictionary alloc] init];
    [twitterDictionary setObject:@"Twitter" forKey:@"platform"];
    
    if (twitterSession.authToken && twitterSession.authTokenSecret) {
        [twitterDictionary setObject:twitterSession.authToken forKey:@"token"];
        [twitterDictionary setObject:twitterSession.authTokenSecret forKey:@"secret"];
    }
    else {
        completion(Nil, [NSError errorWithDomain:@"com.fresconews.Fresco" code:401 userInfo:Nil]);
        return;
    }
    
    [self post:addSocialEndpoint withParameters:twitterDictionary completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
}

-(void)addFacebook:(FBSDKAccessToken *)facebookToken completion:(FRSAPIDefaultCompletionBlock)completion {
    NSString *tokenString = facebookToken.tokenString;
    if (!tokenString) {
        completion(Nil, [NSError errorWithDomain:@"com.fresconews.Fresco" code:401 userInfo:Nil]);
        return;
    }
    
    NSDictionary *facebookDictionary = @{@"platform":@"Facebook", @"token":tokenString};
    
    [self post:addSocialEndpoint withParameters:facebookDictionary completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
}

/*
    Keychain-Based interaction & authentication
 */

// user/me
-(void)refreshCurrentUser:(FRSAPIDefaultCompletionBlock)completion {
    
    if (![self isAuthenticated]) {
        completion(Nil, [NSError errorWithDomain:@"com.fresconews.fresco" code:404 userInfo:Nil]); // no authenticated user, 404
        return;
    }
    
    [self reevaluateAuthorization]; // specific check on bearer
    
    // authenticated request to user/me (essentially user/ozetadev w/ more fields)
    [self get:authenticatedUserEndpoint withParameters:Nil completion:^(id responseObject, NSError *error) {
        completion(responseObject, error);
    }];
}

-(void)reevaluateAuthorization {
    
    if (![self isAuthenticated]) {
        // set client token
        [self.requestManager.requestSerializer setValue:[self clientAuthorization] forHTTPHeaderField:@"Authorization"];
    }
    else { // set bearer token if we haven't already
        // set bearer client token
        NSString *currentBearerToken = [self authenticationToken];
        if (currentBearerToken) {
            currentBearerToken = [NSString stringWithFormat:@"Bearer %@", currentBearerToken];
            [self.requestManager.requestSerializer setValue:currentBearerToken forHTTPHeaderField:@"Authorization"];
            [self startLocator];
        }
        else { // something went wrong here (maybe pass to error handler)
            [self.requestManager.requestSerializer setValue:[self clientAuthorization] forHTTPHeaderField:@"Authorization"];
        }
    }
    _managerAuthenticated = TRUE;
}

-(NSString *)authenticationToken {
    
    NSArray *allAccounts = [SSKeychain accountsForService:serviceName];
    
    if ([allAccounts count] == 0) {
        return Nil;
    }
    
    NSDictionary *credentialsDictionary = [allAccounts firstObject];
    NSString *accountName = credentialsDictionary[kSSKeychainAccountKey];
    
    return [SSKeychain passwordForService:serviceName account:accountName];
}

-(void)saveToken:(NSString *)token forUser:(NSString *)userName {
    [SSKeychain setPasswordData:[token dataUsingEncoding:NSUTF8StringEncoding] forService:serviceName account:userName];
}

-(NSString *)tokenForUser:(NSString *)userName {
    return [SSKeychain passwordForService:serviceName account:userName];
}

-(BOOL)isAuthenticated {
    if ([[SSKeychain accountsForService:serviceName] count] > 0) {
        return TRUE;
    }
    
    return FALSE;
}

-(NSString *)clientAuthorization {
    return [NSString stringWithFormat:@"Basic %@", clientAuthorization];
}

/*
    Generic HTTP methods for use within class
 */
-(void)get:(NSString *)endPoint withParameters:(NSDictionary *)parameters completion:(FRSAPIDefaultCompletionBlock)completion {
    
    AFHTTPRequestOperationManager *manager = [self managerWithFrescoConfigurations];
    
    [manager GET:endPoint parameters:parameters success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        completion(responseObject, Nil);
        
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        completion(Nil, error);
        [self handleError:error];
    }];
}

-(void)post:(NSString *)endPoint withParameters:(NSDictionary *)parameters completion:(FRSAPIDefaultCompletionBlock)completion
{
    
    AFHTTPRequestOperationManager *manager = [self managerWithFrescoConfigurations];
    
    [manager POST:endPoint parameters:parameters success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        
        completion(responseObject, Nil);
        
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        completion(Nil, error);
        [self handleError:error];
    }];
}


/*
    One-off tools for use within class
 */

-(NSNumber *)fileSizeForURL:(NSURL *)url {
    NSNumber *fileSizeValue = nil;
    NSError *fileSizeError = nil;
    [url getResourceValue:&fileSizeValue
                   forKey:NSURLFileSizeKey
                    error:&fileSizeError];
    
    return fileSizeValue;
}


@end
