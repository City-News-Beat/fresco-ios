//
//  FRSUserStoryManager.h
//  Fresco
//
//  Created by Revanth Kumar Yarlagadda on 6/21/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import "FRSBaseManager.h"

@interface FRSUserStoryManager : FRSBaseManager

+ (instancetype)sharedInstance;

- (void)fetchUserStoriesWithLimit:(NSInteger)limit offsetStoryID:(NSString *)offset completion:(FRSAPIDefaultCompletionBlock)completion;

@end
