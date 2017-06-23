//
//  FRSFileSourcePickerTableViewCell.m
//  Fresco
//
//  Created by Revanth Kumar Yarlagadda on 5/12/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import "FRSFileSourcePickerTableViewCell.h"

@interface FRSFileSourcePickerTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;

@property (strong, nonatomic) FRSFileSourcePickerViewModel *viewModel;

@end

@implementation FRSFileSourcePickerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.backgroundColor = [UIColor frescoBackgroundColorLight];
}

- (void)updateWithViewModel:(FRSFileSourcePickerViewModel *)viewModel {
    self.viewModel = viewModel;
    [self configureTitle];
    [self configureCheckMarkImageView];
}

-(void)configureCheckMarkImageView {
    self.checkmarkImageView.image = self.viewModel.isSelected ? self.viewModel.selectedImage : self.viewModel.unSelectedImage;
}

-(void)configureTitle {
    self.titleLabel.text = self.viewModel.name;
    self.titleLabel.font = self.viewModel.isSelected ? self.viewModel.selectedTitleFont : self.viewModel.unSelectedTitleFont;
}

@end