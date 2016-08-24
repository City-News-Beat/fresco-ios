//
//  FRSComment.m
//  Fresco
//
//  Created by Philip Bernstein on 8/24/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSComment.h"
#import "FRSAppDelegate.h"

@implementation FRSComment

-(instancetype)initWithDictionary:(NSDictionary *)commentDictionary {
    self = [super init];
    
    if (self) {
        [self configureWithGallery:commentDictionary];
    }
    
    return self;
}

-(void)configureWithGallery:(NSDictionary *)dictionary {
    FRSAppDelegate *delegate = (FRSAppDelegate *)[[UIApplication sharedApplication] delegate];
    _comment = dictionary[@"comment"];
    _user = [FRSUser nonSavedUserWithProperties:dictionary[@"user"] context:[delegate managedObjectContext]];
    
    NSLog(@"%@", _user);
    _entities = dictionary[@"entities"];
    _imageURL = dictionary[@"user"][@"avatar"];
    _updatedAt = dictionary[@"updated_at"];
    _createdAt = dictionary[@"created_at"];
    [self createAttributedText];
}

-(void)createAttributedText {

}

-(NSInteger)calculateHeightForCell:(FRSCommentCell *)cell {
    CGRect labelRect = [self.comment
                        boundingRectWithSize:cell.commentTextField.frame.size
                        options:NSStringDrawingUsesLineFragmentOrigin
                        attributes:@{
                                     NSFontAttributeName : [UIFont systemFontOfSize:15]
                                     }
                        context:nil];
    
    return labelRect.size.height;
}
@end
