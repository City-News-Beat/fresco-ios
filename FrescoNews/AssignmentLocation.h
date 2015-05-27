//
//  AssignmentLocation.h
//  FrescoNews
//
//  Created by Elmir Kouliev on 5/22/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface AssignmentLocation : NSObject <MKAnnotation>

- (id)initWithName:(NSString*)name address:(NSString*)address assignmentIndex:(NSInteger)assignmentIndex coordinate:(CLLocationCoordinate2D)coordinate;


@property (nonatomic) NSInteger assignmentIndex;

@end