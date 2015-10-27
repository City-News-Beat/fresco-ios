//
//  MKMapView+LegalLabel.m
//  FrescoNews
//
//  Created by Fresco News on 4/29/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import "MKMapView+Additions.h"
#import "FRSDataManager.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "CALayer+Additions.h"

@implementation MKMapView (Additions)

#pragma mark - Zooming

- (void)zoomToCoordinates:(NSNumber*)lat lon:(NSNumber *)lon withRadius:(NSNumber *)radius withAnimation:(BOOL)animate
{
    // Span uses degrees, 1 degree = 69 miles
    MKCoordinateSpan span = MKCoordinateSpanMake(
                                                 ([radius floatValue] / 30),
                                                 ([radius floatValue] / 30)
                                                 );
    MKCoordinateRegion region = {CLLocationCoordinate2DMake([lat floatValue], [lon floatValue]), span};
    MKCoordinateRegion regionThatFits = [self regionThatFits:region];
    
    [self setRegion:regionThatFits animated:animate];
}

- (void)zoomToCurrentLocation{
    
    MKCoordinateSpan span = MKCoordinateSpanMake(0.0002f, 0.0002f);
    MKCoordinateRegion region = {self.userLocation.location.coordinate, span};
    MKCoordinateRegion regionThatFits = [self regionThatFits:region];
    
    [self setRegion:regionThatFits animated:YES];
}

+ (CGFloat)roundedValueForRadiusSlider:(UISlider *)slider
{
    CGFloat roundedValue;
    if (slider.value < 10)
        roundedValue = (int)slider.value;
    else
        roundedValue = ((int)slider.value / 10) * 10;
    
    return roundedValue;
}

#pragma mark - User Location

+ (FRSMKCircle *)userRadiusForMap:(MKMapView *)mapView withRadius:(NSNumber *)radius {
    
    MKUserLocation *userLocation = mapView.userLocation;
    
    FRSMKCircle *circle;

    if (radius) {
        
        circle = [FRSMKCircle circleWithCenterCoordinate:userLocation.coordinate radius:[radius doubleValue] * kMetersInAMile];
    
    } else { //Set the radius to the horizontal accuracy
        
       CGFloat accuracyRadius = (mapView.userLocation.location.horizontalAccuracy > 200) ? 100 : mapView.userLocation.location.horizontalAccuracy;
        
        circle = [FRSMKCircle circleWithCenterCoordinate:userLocation.coordinate radius:accuracyRadius];
        
    }
    
    circle.identifier = FRSUserCircle;
    
    return circle;
}

- (void)updateUserLocationCircleWithRadius:(CGFloat)radius
{
    CLLocationCoordinate2D coordinate = self.userLocation.location.coordinate;
    
    [self zoomToCoordinates:[NSNumber numberWithDouble:coordinate.latitude]
                                      lon:[NSNumber numberWithDouble:coordinate.longitude]
                               withRadius:[NSNumber numberWithDouble:radius] withAnimation:YES];
    
    [self userRadiusUpdated:[NSNumber numberWithDouble:radius]];
}

- (void)userRadiusUpdated:(NSNumber *)radius{

    for (id<MKOverlay>overlay in self.overlays) {
        
        if ([overlay isKindOfClass:[FRSMKCircle class]]) {
        
            //Remove the overlay from view
            [self removeOverlay:overlay];

        }
    }
    
    //Create new one with updated user location
    [self addOverlay:[MKMapView userRadiusForMap:self withRadius:radius]];
    
}

+ (DBImageColorPicker *)createDBImageColorPickerForUserWithImage:(UIImage *)image{
    
    //Check if the paramater is nil and if the user has an avatar
    if(!image && [[NSUserDefaults standardUserDefaults] stringForKey:UD_AVATAR]){
        
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:UD_AVATAR]]]];
    
    }

    //Check if image is set after first conidition, otherwise return nil
    if(image)
        return [[DBImageColorPicker alloc] initFromImage:image withBackgroundType:DBImageColorPickerBackgroundTypeDefault];
    else
        return nil;
}

#pragma mark - Circle Rendering

+ (MKCircleRenderer *)radiusRendererForOverlay:(id<MKOverlay>)overlay withImagePicker:(DBImageColorPicker *)picker{

    MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithOverlay:overlay];
    
    if ([overlay isKindOfClass:[FRSMKCircle class]]) {
        
        FRSMKCircle *circleForUserRadius = (FRSMKCircle *)overlay;
        
        if (circleForUserRadius.identifier == FRSUserCircle) { // making sure it's a user
            
            if (picker){ // if a picker is passed

                [circleView setFillColor:picker.secondaryTextColor];
                
            }
            else  // use default fresco blue
                [circleView setFillColor:[UIColor frescoBlueColor]];
        }
        
    }
    else // it's an assignment
        [circleView setFillColor:[UIColor radiusGoldColor]];
    
    circleView.alpha = .26;
    
    return circleView;

}

- (void)updateRadiusColor{
    
    for (id<MKOverlay>overlay in self.overlays) {
        if ([overlay isKindOfClass:[FRSMKCircle class]]) {
            FRSMKCircle *circle = (FRSMKCircle *)overlay;
            [self removeOverlay:circle];
            [self addOverlay:circle];
            break;
        }
    }
}

- (void)removeAllOverlaysButUser{
    
    for (id<MKOverlay>overlay in self.overlays)
        if (![overlay isKindOfClass:[FRSMKCircle class]])
            [self removeOverlay:overlay];
    
}

#pragma mark - Annotations

+ (UIButton *)caret {
    
    UIButton *caret = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    [caret setImage:[UIImage imageNamed:@"disclosure"] forState:UIControlStateNormal];
    
    caret.frame = CGRectMake(caret.frame.origin.x, caret.frame.origin.x, 10.0f, 15.0f);
    
    caret.contentMode = UIViewContentModeScaleAspectFit;
    
    return caret;
}

- (MKAnnotationView *)setupAssignmentPinForAnnotation:(id <MKAnnotation>)annotation withType:(FRSAnnotationType)type{
    
    NSString *identifier = (type == FRSAssignmentAnnotation) ? ASSIGNMENT_IDENTIFIER : CLUSTER_IDENTIFIER;
   
    MKAnnotationView *annotationView = (MKAnnotationView *)[self dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if (!annotationView) {
        
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        
        annotationView.centerOffset = CGPointMake(0, 1.5); // offset the shadow
        
        [annotationView setImage:[MKMapView imagePinViewForAnnotationType:FRSAssignmentAnnotation].image];
        
        annotationView.enabled = YES;
        
        if (type == FRSAssignmentAnnotation) {
            
            annotationView.canShowCallout = YES;
            
            annotationView.rightCalloutAccessoryView = [MKMapView caret];
            
        }
    }
    
    return annotationView;
}


- (MKAnnotationView *)setupUserPinForAnnotation:(id <MKAnnotation>)annotation {

    MKAnnotationView *annotationView = [self dequeueReusableAnnotationViewWithIdentifier:USER_IDENTIFIER];
    
    if (!annotationView) {
        
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:USER_IDENTIFIER];
        
        annotationView.centerOffset = CGPointMake(-14, -15 + 3); // math is account for 18 width and 5 x, 18 height and 3 y w, 3 pts shadow

        UIImageView *whiteLayerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dot-user-blank"]];
        
        UIImageView *profileImageView = [MKMapView imagePinViewForAnnotationType:FRSUserAnnotation];

        [profileImageView.layer addPulsingAnimation];
        
        [whiteLayerImageView addSubview:profileImageView];
        
        [annotationView addSubview:whiteLayerImageView];
    }
    
    return annotationView;
}


+ (UIImageView *)imagePinViewForAnnotationType: (FRSAnnotationType)type {
    
    UIImageView *customPinView = [[UIImageView alloc] init];
    
    CGRect frame = CGRectMake(5, 3, 18, 18);
    
    if (type == FRSAssignmentAnnotation || type == FRSClusterAnnotation) { // is Assignment annotation view
        
        [customPinView setImage:[UIImage imageNamed:@"dot-assignment"]];
        
    }
    else if (type == FRSUserAnnotation) { // is User annotation view
        
        if ([[NSUserDefaults standardUserDefaults] stringForKey:UD_AVATAR] != nil)
            [customPinView setImageWithURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:UD_AVATAR]]];
        
        else
            [customPinView setImage:[UIImage imageNamed:@"dot-user-fill"]];
    }
    
    customPinView.frame = frame;
    customPinView.layer.masksToBounds = YES;
    customPinView.layer.cornerRadius = customPinView.frame.size.width / 2;
    
    return customPinView;
}

- (void)updateUserPinViewForMapViewWithImage:(UIImage *)image {
    
    if (image != nil) {
        
        for (id<MKAnnotation> annotation in self.annotations){
            
            if (annotation == self.userLocation){
                
                MKAnnotationView *profileAnnotation = [self viewForAnnotation:annotation];
                
                if ([profileAnnotation.subviews count] > 0){
                    
                    if ([(UIImageView *)(((UIView *)profileAnnotation.subviews[0]).subviews[0]) isKindOfClass:[UIImageView class]]) {
                        
                        UIImageView *profileImageView = (UIImageView *)(((UIView *)profileAnnotation.subviews[0]).subviews[0]);
                        
                        [profileImageView setImage:image];
                        
                    }
                }
            }
        }
    }
}

@end