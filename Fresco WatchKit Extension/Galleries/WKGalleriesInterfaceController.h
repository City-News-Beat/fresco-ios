//
//  FRSPostsInterfaceController.h
//  Fresco
//
//  Created by Fresco News on 3/26/15.
//  Copyright (c) 2015 Fresco News, Inc. All rights reserved.
//

@import WatchKit;
@import Foundation;

@interface WKGalleriesInterfaceController : WKInterfaceController

@property (nonatomic, strong) NSArray *galleries;

@property (weak, nonatomic) IBOutlet WKInterfaceTable *postTable;

@end
