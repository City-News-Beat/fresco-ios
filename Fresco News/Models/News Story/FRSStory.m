//
//  FRSStory.m
//  Fresco
//
//  Created by Fresco News on 3/11/2015.
//  Copyright (c) 2015 TapMedia LLC. All rights reserved.
//

#import "FRSStory.h"
#import "MTLModel+Additions.h"
#import "FRSUser.h"
#import "FRSArticle.h"

@implementation FRSStory

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"storyID": @"_id",
             @"curator" : @"curator",
             @"title" : @"title",
             @"caption" : @"caption",
             @"tags" : @"tags",
             @"galleryIds" : @"galleries",
             @"articleIds" : @"articles",
             @"thumbnails" : @"thumbnails",
             @"date" : @"time_created"
             };
}

+ (NSValueTransformer *)articlesJSONTransformer
{
    return [MTLModel sourcesJSONTransformer];
}

- (NSString *)caption
{
    return [_caption length] ? _caption : NSLocalizedString(@"No Caption", nil);
}

+ (NSValueTransformer *)curatorJSONTransformer
{
    return [MTLModel userJSONTransformer];
}

+ (NSValueTransformer *)thumbnailsJSONTransformer
{
    return [MTLModel postsJSONTransformer];
}
@end