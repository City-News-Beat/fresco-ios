//
//  FRSUserStoryManager.m
//  Fresco
//
//  Created by Revanth Kumar Yarlagadda on 6/21/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import "FRSUserStoryManager.h"
#import "FRSAPIClient.h"

static NSString *const kUserStoryListEndpoint = @"story/list";

@implementation FRSUserStoryManager

+ (instancetype)sharedInstance {
    static FRSUserStoryManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FRSUserStoryManager alloc] init];
    });
    return instance;
}

- (void)fetchUserStoriesWithLimit:(NSInteger)limit offsetStoryID:(NSString *)offset completion:(FRSAPIDefaultCompletionBlock)completion {
    
    NSDictionary *params = @{
                             @"highlighted_before" : @"1497888728047",
                             @"rating" : @(2),
                             @"sortBy" : @"highlighted_at",
                             @"direction" : @"desc",
                             @"limit" : @(10),
                             @"expand" : @[@"posts[6]"]
                             };
    
    //the 'n' in posts[n] is number of posts per story we want to fetch.
    
//    if (!offset) {
//        params = @{ @"limit" : [NSNumber numberWithInteger:limit] };
//    }
    
    [[FRSAPIClient sharedClient] get:kUserStoryListEndpoint
                      withParameters:params
                          completion:^(id responseObject, NSError *error) {
                              completion(responseObject, error);
                          }];
}

@end