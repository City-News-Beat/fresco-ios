//
//  FRSStoriesViewController.m
//  Fresco
//
//  Created by Omar Elfanek on 1/18/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSStoriesViewController.h"
#import "FRSSearchViewController.h"

#import "FRSStoryCell.h"
#import "FRSDataManager.h"

#import <MagicalRecord/MagicalRecord.h>

@interface FRSStoriesViewController() <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) NSArray *stories;
@property (strong, nonatomic) NSArray *dataSource;

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *searchButton;
@property (strong, nonatomic) UITextField *searchTextField;

@property (strong, nonatomic) UITableView *tableView;

@end

@implementation FRSStoriesViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [self configureUI];
}


#pragma mark - Configure UI

-(void)configureUI{
    self.view.backgroundColor = [UIColor frescoBackgroundColorLight];
    [self configureTableView];
//    [self configureDataSource];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self configureNavigationBar];
}

#pragma mark -  UI

-(void)configureNavigationBar{
    
    UIView *navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    navBar.backgroundColor = [UIColor frescoOrangeColor];
    [self.view addSubview:navBar];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 35, self.view.frame.size.width, 19)];
    self.titleLabel.text = @"STORIES";
    self.titleLabel.font = [UIFont notaBoldWithSize:17];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [navBar addSubview:self.titleLabel];
    
    self.searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.searchButton.frame = CGRectMake(self.view.frame.size.width - 48, 19.5, 48, 44);
    self.searchButton.tintColor = [UIColor whiteColor];
    [self.searchButton setImage:[UIImage imageNamed:@"search-icon"] forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(searchStories) forControlEvents:UIControlEventTouchUpInside];
    [navBar addSubview:self.searchButton];
    
    self.searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(self.view.frame.size.width, navBar.frame.size.height - 38, self.view.frame.size.width - 60, 30)];
    self.searchTextField.tintColor = [UIColor whiteColor];
    self.searchTextField.alpha = 0;
    self.searchTextField.delegate = self;
    self.searchTextField.textColor = [UIColor whiteColor];
    self.searchTextField.returnKeyType = UIReturnKeySearch;
    [navBar addSubview:self.searchTextField];
}

-(void)searchStories{
    //    [self animateSearch];
    
    FRSSearchViewController *searchVC = [[FRSSearchViewController alloc] init];
    [self presentViewController:searchVC animated:YES completion:nil];
}

-(void)animateSearch{
    [UIView animateWithDuration:0.35 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        self.searchButton.transform = CGAffineTransformMakeTranslation((-self.view.frame.size.width) + 45, 0);
        self.searchTextField.transform = CGAffineTransformMakeTranslation((-self.view.frame.size.width) +40, 0);
        self.searchTextField.alpha = 1;
        
    } completion:nil];
    
    [UIView animateWithDuration:0.25 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        self.titleLabel.alpha = 0;
    } completion:^(BOOL finished) {
        [self.searchTextField becomeFirstResponder];
    }];
}

-(void)hideSearch{
    [UIView animateWithDuration:0.35 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        self.searchButton.transform = CGAffineTransformMakeTranslation(0, 0);
        self.searchTextField.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
        self.searchTextField.alpha = 0;
    } completion:^(BOOL finished) {
        self.searchTextField.text = @"";
    }];
    
    [UIView animateWithDuration:0.25 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        self.titleLabel.alpha = 1;
    } completion:nil];
}

-(void)configureTableView{

    self.tableView = [[UITableView alloc] init];
    self.tableView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor frescoBackgroundColorDark];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.view addSubview:self.tableView];
}



-(void)configureDataSource{
    [[FRSDataManager sharedManager] getGalleries:@{@"offset" : @0, @"hide" : @2, @"stories" : @"true"} shouldRefresh:YES withResponseBlock:^(NSArray* responseObject, NSError *error) {
        if (!responseObject.count){
            return;
        }
        
        NSMutableArray *mArr = [NSMutableArray new];
        
        NSArray *galleries = responseObject;
        for (NSDictionary *dict in galleries){
            FRSGallery *gallery = [FRSGallery MR_createEntity];
            [gallery configureWithDictionary:dict];
            [mArr addObject:gallery];
        }
        
        self.stories = [mArr copy];
        self.dataSource = [self.stories copy];
        [self.tableView reloadData];
    }];
}


#pragma mark - UITableView DataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//    return self.dataSource.count;
    return 4;
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self heightForItemAtDataSourceIndex:indexPath.row];
}



-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    FRSStoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"story-cell"];
    if (!cell){
        cell = [[FRSStoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"story-cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

-(NSInteger)heightForItemAtDataSourceIndex:(NSInteger)index{
    FRSGallery *story = self.dataSource[index];
//    return [self heightForCellForStory:story];
    return [story heightForGallery];
    
    //CHECK FOR RELEASE this probably needs to be refactored.
}

-(NSInteger)heightForCellForStory:(FRSGallery *)gallery{
    
//    NSInteger totalHeight = 0;
    
    //    for (FRSPost *post in gallery.posts){
    //        NSInteger rawHeight = [post.meta[@"image_height"] integerValue];
    //        NSInteger rawWidth = [post.meta[@"image_width"] integerValue];
    //
    //        if (rawHeight == 0 || rawWidth == 0){
    //            totalHeight += [UIScreen mainScreen].bounds.size.width;
    //        }
    //        else {
    //            NSInteger scaledHeight = rawHeight * ([UIScreen mainScreen].bounds.size.width/rawWidth);
    //            totalHeight += scaledHeight;
    //        }
    //    }
    
//    NSInteger averageHeight = totalHeight/gallery.posts.count;
    
//    averageHeight = MIN(averageHeight, [UIScreen mainScreen].bounds.size.width * 4/3);
//    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 32, 0)];
//    
//    label.font = [UIFont systemFontOfSize:15 weight:-1];
//    label.text = gallery.caption;
//    label.numberOfLines = 6;
//    [label sizeToFit];
//
//    averageHeight += label.frame.size.height + 12 + 44 + 20;
//    
//    label.backgroundColor = [UIColor redColor];
//    return averageHeight;
    
    if (IS_IPHONE_5) {
        return 193;
    } else {
        return 241;
    }
}

#pragma mark UITableView Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(FRSStoryCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
//    [cell clearCell];
    
//    cell.story = self.dataSource[indexPath.row];
    
//    [cell configureCell];
    
}























@end
