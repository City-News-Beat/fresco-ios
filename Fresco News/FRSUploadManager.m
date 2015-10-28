//
//  FRSUploadManager.m
//  Fresco
//
//  Created by Elmir Kouliev on 10/23/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

@import FBSDKCoreKit;
@import Photos;

#import "FRSUploadManager.h"
#import "FRSDataManager.h"
#import "FRSPost.h"
#import "FRSImage.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>

@interface FRSUploadManager()

+ (NSURLSessionConfiguration *)frescoSessionConfiguration;

@property (nonatomic, assign) NSInteger postCount;

@property (nonatomic, assign) NSInteger currentPostIndex;

@end

@implementation FRSUploadManager

#pragma mark - static methods

+ (FRSUploadManager *)sharedManager
{
    static FRSUploadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FRSUploadManager alloc] init];
        
    });
    return manager;
}

+ (NSURLSessionConfiguration *)frescoSessionConfiguration
{
    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    return configuration;
}

#pragma mark - object lifecycle

- (id)init
{
    NSURL *baseURL = [NSURL URLWithString:BASE_API];
    
    if (self = [super initWithBaseURL:baseURL sessionConfiguration:[[self class] frescoSessionConfiguration]]) {
        
        [[self responseSerializer] setAcceptableContentTypes:nil];
        
    }
    return self;
}

#pragma mark Upload Methods

- (void)uploadGallery:(FRSGallery *)gallery withAssignment:(FRSAssignment *)assignment withResponseBlock:(FRSAPISuccessBlock)responseBlock{
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    __block NSProgress *progress = nil;
    
    //Form the request
    FRSPost *post = gallery.posts[0];
    
    self.postCount = gallery.posts.count;
    self.currentPostIndex = 1;
    
    NSString *filename = [NSString stringWithFormat:@"file%@", @(0)];
    
    NSDictionary *parameters = @{ @"owner" : [FRSDataManager sharedManager].currentUser.userID,
                                  @"caption" : gallery.caption ?: [NSNull null],
                                  @"posts" : [post constructPostMetaDataWithFileName:filename],
                                  @"assignment" : assignment.assignmentId ?: [NSNull null] };
    
    
    //Send request for image data
    [post dataForPostWithResponseBlock:^(NSData *data, NSError *error) {
        
        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer]
                                        multipartFormRequestWithMethod:@"POST"
                                        URLString:[[FRSDataManager sharedManager] endpointForPath:@"gallery/assemble"]
                                        parameters:parameters
                                        constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                            
                                            FRSPost *post = gallery.posts[0];
                                            
                                            NSString *mimeType = post.image.asset.mediaType == PHAssetMediaTypeImage ? @"image/jpeg" : @"video/mp4";
                                            
                                            [formData appendPartWithFileData:data
                                                                        name:filename
                                                                    fileName:filename
                                                                    mimeType:mimeType];
                                            
                                            
                                        } error:nil];
        
        [request setValue:[FRSDataManager sharedManager].frescoAPIToken forHTTPHeaderField:@"authtoken"];
        
        NSURLSessionUploadTask *uploadTask = [manager
                                              uploadTaskWithStreamedRequest:request
                                              progress:&progress
                                              completionHandler:^(NSURLResponse *response, id responseObject, NSError *uploadError) {
                                                  
                                                  //Check if we have a valid response
                                                  if(responseObject[@"data"] != nil && !uploadError){
                                                      
                                                      NSString *galleryId = responseObject[@"data"][@"_id"];
                                                      
                                                      if(galleryId){
                                                          
                                                          dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
                                                          
                                                          dispatch_group_t postUploadGroup = dispatch_group_create();
                                                          
                                                          //Upload the rest of the posts
                                                          for (NSInteger i = 1; i < gallery.posts.count; i++) {
                                                              
                                                              dispatch_group_enter(postUploadGroup);
                                                              
                                                              dispatch_async(queue, ^{
                                                                  
                                                                  [self uploadPost:gallery.posts[i] withGalleryId:galleryId withAssignment:assignment withResponseBlock:^(BOOL sucess, NSError *error) {
                                                                      
                                                                      dispatch_group_leave(postUploadGroup); // 3
                                                                      
                                                                  }];
                                                                  
                                                              });
                                                              
                                                          }
                                                          
                                                          dispatch_group_notify(postUploadGroup, dispatch_get_main_queue(), ^{
                                                              NSLog(@"Done");
                                                          });
                                                          
                                                      }
                                                      
                                                  }
                                                  else{
                                                      
                                                      //Handle error
                                                      //NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:ErrorUploadFail userInfo:@{}];
                                                      
                                                  }
                                                  
                                              }];
        
        [uploadTask resume];
        
        //Send response block back to caller
        if(responseBlock)
            responseBlock(YES, nil);
        
        [progress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
        
    }];
}


- (void)uploadPost:(FRSPost *)post withGalleryId:(NSString *)galleryId withAssignment:(FRSAssignment *)assignment withResponseBlock:(FRSAPISuccessBlock)responseBlock{
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    self.currentPostIndex++;
    
    __block NSProgress *progress = nil;
    
    NSString *filename = [NSString stringWithFormat:@"file%@", @(self.currentPostIndex-1)];
    
    NSDictionary *parameters = @{
                                 @"gallery" : galleryId,
                                 @"posts" : [post constructPostMetaDataWithFileName:filename]
                                 };
    
    //Request image data
    [post dataForPostWithResponseBlock:^(NSData *data, NSError *error) {
    
        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer]
                                        multipartFormRequestWithMethod:@"POST"
                                        URLString:[[FRSDataManager sharedManager] endpointForPath:@"gallery/addpost"]
                                        parameters:parameters
                                        constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                            
                                            NSString *mimeType = post.image.asset.mediaType == PHAssetMediaTypeImage ? @"image/jpeg" : @"video/mp4";
                                            
                                            [formData appendPartWithFileData:data
                                                                        name:filename
                                                                    fileName:filename
                                                                    mimeType:mimeType];
                                            
                                            
                                        } error:nil];
        
        [request setValue:[FRSDataManager sharedManager].frescoAPIToken forHTTPHeaderField:@"authtoken"];
        
        NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *uploadError) {
            
            if(responseBlock)
                responseBlock(uploadError == nil ? YES : NO, uploadError);
            
        }];
        
        [uploadTask resume];

        [progress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    
    
    }];

}


#pragma mark - Social Upload Methods

- (void)postToTwitter:(NSString *)string {
    
    string = [NSString stringWithFormat:@"status=%@", string];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    NSMutableURLRequest *tweetRequest = [NSMutableURLRequest requestWithURL:url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    tweetRequest.HTTPMethod = @"POST";
    tweetRequest.HTTPBody = [[string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]] dataUsingEncoding:NSUTF8StringEncoding];
    [[PFTwitterUtils twitter] signRequest:tweetRequest];
    
    [NSURLConnection sendAsynchronousRequest:tweetRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            // TODO: Notify the user
            NSLog(@"Error crossposting to Twitter: %@", connectionError);
        }
        else {
            NSLog(@"Success crossposting to Twitter: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
    }];
}

- (void)postToFacebook:(NSString *)string{

    // TODO: Fix [[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"] ) {
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me/feed"
                                       parameters: @{@"message" : string}
                                       HTTPMethod:@"POST"] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error) {
            // TODO: Notify the user
            NSLog(@"Error crossposting to Facebook");
        }
        else {
            NSLog(@"Success crossposting to Facebook: Post id: %@", result[@"id"]);
        }
    }];

}

#pragma mark - User Defaults Management

- (void)resetDraftGalleryPost
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:UD_CAPTION_STRING_IN_PROGRESS];
    [defaults setObject:nil forKey:UD_DEFAULT_ASSIGNMENT_ID];
    [defaults setObject:nil forKey:UD_SELECTED_ASSETS];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"fractionCompleted"]) {
        
        NSProgress *progress = (NSProgress *)object;
        
        NSNumber *fractionCompleted = [NSNumber numberWithDouble:((progress.fractionCompleted + (float)self.currentPostIndex) / self.postCount)];
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:NOTIF_UPLOAD_PROGRESS
         object:nil
         userInfo:@{
                    @"fractionCompleted" : fractionCompleted
                    }];
        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


@end