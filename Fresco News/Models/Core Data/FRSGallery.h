//
//  FRSGallery.h
//  Fresco
//
//  Created by Daniel Sun on 12/21/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FRSCoreData.h"

@class FRSPost, FRSStory, FRSUser;

NS_ASSUME_NONNULL_BEGIN

@interface FRSGallery : NSManagedObject<FRSManagedObject>

// Insert code here to declare functionality of your managed object subclass
-(void)configureWithDictionary:(NSDictionary *)dict;

-(NSInteger)heightForGallery;

@end

NS_ASSUME_NONNULL_END

#import "FRSGallery+CoreDataProperties.h"
