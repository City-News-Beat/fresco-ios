//
//  FRSAssignmentAnnotation.m
//  Fresco
//
//  Created by Daniel Sun on 1/19/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSAssignmentAnnotation.h"
#import "FRSAssignment.h"

@interface FRSAssignmentAnnotation ()

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSDate *assignmentExpirationDate;
@property (strong, nonatomic) NSDate *assignmentPostedDate;
@property (nonatomic) CLLocationCoordinate2D coordinate;

@end

@implementation FRSAssignmentAnnotation
@synthesize subtitle = _subtitle;

- (instancetype)initWithAssignment:(FRSAssignment *)assignment atIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        if ([assignment.title isKindOfClass:[NSString class]]) {
            self.name = assignment.title;
        } else {
            self.name = @"Assignment";
        }

        if ([assignment.caption isKindOfClass:[NSString class]]) {
            _subtitle = assignment.caption;
        } else {
            _subtitle = @"";
        }
        self.assignmentExpirationDate = assignment.expirationDate;
        self.assignmentPostedDate = assignment.createdDate;
        self.assignmentIndex = index;
        self.assignmentId = assignment.uid;
        self.address = assignment.address;
        self.coordinate = CLLocationCoordinate2DMake([assignment.latitude floatValue], [assignment.longitude floatValue]);

        self.isAcceptable = [assignment.acceptable boolValue];
        
        self.assignment = assignment;
    }
    return self;
}

- (NSString *)subtitle {
    return _subtitle;
}

- (NSString *)title {
    return self.name;
}

@end

