//
//  FRSStoryTableViewCell.h
//  Fresco
//
//  Created by Omar Elfanek on 1/20/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRSStoryView.h"

@class FRSStory;

@interface FRSStoryCell : UITableViewCell <FRSStoryViewDelegate>

@property (strong, nonatomic) FRSStoryView *storyView;
@property (strong, nonatomic) FRSStory *story;
@property (strong, nonatomic) ActionButtonBlock actionBlock;
@property (strong, nonatomic) StoryImageBlock imageBlock;
@property (strong, nonatomic) ShareSheetBlock shareBlock;
@property (strong, nonatomic) ShareSheetBlock readMoreBlock;

-(void)clearCell;
-(void)configureCell;
-(void)play;
-(void)pause;
@end
