//
//  InterfaceController.h
//  Fresco WatchKit Extension
//
//  Created by Fresco News on 3/10/15.
//  Copyright (c) 2015 Fresco News, Inc. All rights reserved.
//

@import WatchKit;
@import Foundation;

@interface FRSInterfaceController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceButton* highlights;

@property (weak, nonatomic) IBOutlet WKInterfaceButton* stories;

@end