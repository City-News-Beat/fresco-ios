//
//  FRSAssignmentPickerTableViewCell.h
//  Fresco
//
//  Created by Omar Elfanek on 5/5/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRSAssignment.h"

@interface FRSAssignmentPickerTableViewCell : UITableViewCell

@property (strong, nonatomic) NSArray *assignment;
@property (nonatomic) BOOL isSelectedAssignment;

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier assignment:(FRSAssignment *)assignment;

-(void)configureCell;
-(void)toggleImage;

@end
