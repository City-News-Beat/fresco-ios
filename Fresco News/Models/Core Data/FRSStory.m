//
//  FRSStory.m
//  Fresco
//
//  Created by Daniel Sun on 12/21/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import "FRSStory.h"
#import "FRSGallery.h"
#import "FRSUser.h"
#import "FRSCoreData.h"
#import "FRSDateFormatter.h"
#import "MagicalRecord.h"
#import "FRSUserManager.h"
#import "NSString+Fresco.h"

@import UIKit;

@implementation FRSStory
@synthesize galleryCount = _galleryCount, sourceUser = _sourceUser, creator = _creator, curatorDict = _curatorDict;

// Insert code here to add functionality to your managed object subclass

- (NSDictionary *)curatorDict {
    return _curatorDict;
}

- (void)setCuratorDict:(NSDictionary *)curatorDict {
    _curatorDict = curatorDict;
}

- (void)configureWithDictionary:(NSDictionary *)dict {

    self.caption = dict[@"caption"];
    
    if ([dict valueForKey:@"created_at"] != nil && ![[dict valueForKey:@"created_at"] isEqual:[NSNull null]]) {
        self.createdDate = [NSString dateFromString:dict[@"created_at"]];
    }

    if (dict[@"updated_at"] && ![dict[@"updated_at"] isEqual:[NSNull null]]) {
        self.editedDate = [NSString dateFromString:dict[@"updated_at"]];
    }

    self.title = dict[@"title"];
    self.uid = dict[@"id"];
    self.imageURLs = [self imagesURLsFromThumbnails:dict[@"thumbnails"]];
    self.galleryCount = dict[@"galleries"];

    if ([[dict valueForKey:@"reposted"] boolValue]) {
        [self setValue:@(TRUE) forKey:@"reposted"];
    } else {
        [self setValue:@(FALSE) forKey:@"reposted"];
    }

    if ([[dict valueForKey:@"liked"] boolValue]) {
        [self setValue:@(TRUE) forKey:@"liked"];

    } else {
        [self setValue:@(FALSE) forKey:@"liked"];
    }

    NSNumber *reposts = [dict valueForKey:@"reposts"];
    [self setValue:reposts forKey:@"reposts"];

    NSNumber *likes = [dict valueForKey:@"likes"];
    [self setValue:likes forKey:@"likes"];

    if (![dict[@"curator"] isEqual:[NSNull null]]) {
        self.curatorDict = dict[@"curator"];
    }

    NSString *repostedBy = [dict valueForKey:@"reposted_by"];

    if (repostedBy != Nil && ![repostedBy isEqual:[NSNull null]]) {
        [self setValue:repostedBy forKey:@"reposted_by"];

        NSArray *sources = (NSArray *)dict[@"sources"];
        if ([[sources class] isSubclassOfClass:[NSArray class]] && sources.count > 0) {

            NSString *repostedBy = dict[@"reposted_by"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", repostedBy];
            NSArray *results = [sources filteredArrayUsingPredicate:predicate];
            NSDictionary *source = (NSDictionary *)[results firstObject];
            NSString *userID = source[@"user_id"];

            [[FRSUserManager sharedInstance] getUserWithUID:userID
                                                 completion:^(id responseObject, NSError *error) {
                                                   FRSUser *user = [FRSUser nonSavedUserWithProperties:responseObject context:[[FRSUserManager sharedInstance] managedObjectContext]];
                                                   self.sourceUser = user;
                                                 }];
        }
    }
}

- (NSInteger)heightForStory {

    NSInteger imageViewHeight = IS_IPHONE_5 ? 192 : 240;

    if (self.caption.length == 0) {
        imageViewHeight = imageViewHeight - 12;
    }

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - 32, 0)];
    label.text = self.caption;
    label.numberOfLines = 6;
    label.font = [UIFont systemFontOfSize:15 weight:-1];
    [label sizeToFit];

    // 44 is tab bar, 11 is top padding, 13 is bottom padding
    imageViewHeight += label.frame.size.height + 44 + 11 + 13;
    return imageViewHeight;
}

- (NSArray *)imagesURLsFromThumbnails:(NSArray *)thumbnails {
    NSMutableArray *mArr = [NSMutableArray new];

    for (NSDictionary *thumb in thumbnails) {
        NSString *stringURL = thumb[@"image"];
        if (!stringURL)
            continue;
        NSURL *url = [NSURL URLWithString:stringURL];

        if (url) {
            [mArr addObject:url];
        }
    }

    return [mArr copy];
}

+ (instancetype)initWithProperties:(NSDictionary *)properties context:(NSManagedObjectContext *)context {
    FRSStory *story = [NSEntityDescription insertNewObjectForEntityForName:@"FRSStory" inManagedObjectContext:context];
    [story configureWithDictionary:properties];
    return story;
}

- (NSDictionary *)jsonObject {
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];

    return jsonObject;
}
@end
