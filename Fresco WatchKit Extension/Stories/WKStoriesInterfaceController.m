//
//  FRSStoriesInterfaceController.m
//  Fresco
//
//  Created by Fresco News on 3/26/15.
//  Copyright (c) 2015 Fresco News, Inc. All rights reserved.
//

#import "WKStoriesInterfaceController.h"
#import "WKStoryRowController.h"
#import "WKGalleryDetailController.h"
#import "WKRelativeDate.h"
#import "WKImagePath.h"
#import <AFNetworking/AFNetworking.h>

@implementation WKStoriesInterfaceController

- (void)awakeWithContext:(id)context {
    
    [super awakeWithContext:context];
    
    // Configure interface objects here.
    
    NSURL *baseURL = [NSURL URLWithString:@"https://api.fresconews.com/v1/"];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager GET:@"story/recent?limit=4" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *stories = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil][@"data"];
        
        self.stories = stories;
        
        if(self.stories != nil){
            
            [self populateStories];
        
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
    
}

- (void)populateStories{

    [self.storyTable setNumberOfRows:[_stories count] withRowType:@"storyRow"];
    
    for (NSInteger i = 0; i < _stories.count; i++) {
        
        WKStoryRowController* row = [self.storyTable rowControllerAtIndex:i];
        
        [row.storyTitle setText:self.stories[i][@"title"]];
        
        [row.storyLocation setText:self.stories[i][@"thumbnails"][0][@"location"][@"address"]];
                
        NSDate *date = [[NSDate date] initWithTimeIntervalSince1970:([(NSNumber *)self.stories[i][@"time_edited"] integerValue] / 1000)];
        
        [row.storyTime setText:[WKRelativeDate relativeDateString:date]];
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            //Background Thread
            
            if([((NSArray *)self.stories[i][@"thumbnails"]) count] > 0){

                [row.storyImage1 setImageData:[NSData dataWithContentsOfURL:[WKImagePath
                                                                             CDNImageURL:self.stories[i][@"thumbnails"][0][@"image"]
                                                                             withSize:SmallImageSize]]];
            }
            if([((NSArray *)self.stories[i][@"thumbnails"]) count] > 1)
                
                 [row.storyImage2 setImageData:[NSData dataWithContentsOfURL:[WKImagePath
                                                                              CDNImageURL:self.stories[i][@"thumbnails"][1][@"image"]
                                                                              withSize:SmallImageSize]]];
            
        });
        
        
    }

}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex{
    
    NSString *storyId = [self.stories objectAtIndex:rowIndex][@"_id"];
    
    [self pushControllerWithName:@"galleries" context:storyId];
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}


@end



