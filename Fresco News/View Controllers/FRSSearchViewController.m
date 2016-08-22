//
//  FRSSearchViewController.m
//  Fresco
//
//  Created by Omar Elfanek on 1/18/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSSearchViewController.h"
#import "FRSTableViewCell.h"
#import "FRSGallery.h"
#import "FRSGalleryCell.h"
#import "FRSGalleryExpandedViewController.h"
#import "FRSScrollingViewController.h"
#import "FRSUser.h"
#import "FRSProfileViewController.h"
#import "FRSStoryDetailViewController.h"
//#import <MagicalRecord/MagicalRecord.h>

@interface FRSSearchViewController() <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UITextField *searchTextField;
@property (strong, nonatomic) UIButton *clearButton;

@property (strong, nonatomic) UIButton *backTapButton;
@property BOOL userExtended;
@property BOOL storyExtended;

@end

@implementation FRSSearchViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self configureNavigationBar];
    [self configureTableView];
    [self.navigationController setNavigationBarHidden:NO];
    
    userIndex = 0;
    storyIndex = 1;
    galleryIndex = 2;
    
    [self.searchTextField becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.searchTextField resignFirstResponder];
}

-(void)dismiss{
    [self.navigationController popViewControllerAnimated:YES];
    [self.backTapButton removeFromSuperview];
}

-(void)clear{
    self.searchTextField.text = @"";
    [self hideClearButton];
    [self.searchTextField resignFirstResponder];
}

#pragma mark - UI
-(void)configureNavigationBar {

    UIImage *backButtonImage = [UIImage imageNamed:@"back-arrow-light"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    [container addSubview:backButton];
    
    backButton.tintColor = [UIColor whiteColor];
//    backButton.backgroundColor = [UIColor redColor];
    backButton.frame = CGRectMake(-15, -12, 48, 48);
    backButton.imageView.frame = CGRectMake(-12, 0, 48, 48); //this doesnt change anything
//    backButton.imageView.backgroundColor = [UIColor greenColor];
    [backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [backButton setImage:backButtonImage forState:UIControlStateNormal];
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:container];

    
    self.backTapButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 44, 44)];
    [self.backTapButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
//    self.backTapButton.backgroundColor = [UIColor blueColor];
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.backTapButton];
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
//    [view addGestureRecognizer:tap];
    
    self.navigationItem.leftBarButtonItem = backBarButtonItem;
    
    
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    self.navigationItem.titleView = titleView;
    
    self.searchTextField = [[UITextField alloc] initWithFrame:CGRectMake(19, 17, self.view.frame.size.width - 80, 30)];
    self.searchTextField.tintColor = [UIColor whiteColor];
    self.searchTextField.textColor = [UIColor whiteColor];
    self.searchTextField.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    self.searchTextField.delegate = self;
    self.searchTextField.returnKeyType = UIReturnKeySearch;
    self.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.3], NSFontAttributeName : [UIFont systemFontOfSize:17 weight:UIFontWeightMedium] }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.searchTextField];
    
    [titleView addSubview:self.searchTextField];
    
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.clearButton.frame = CGRectMake(self.view.frame.size.width - 80, 20, 24, 24);
    [self.clearButton setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    self.clearButton.tintColor = [UIColor whiteColor];
    [self.clearButton addTarget:self action:@selector(clear) forControlEvents:UIControlEventTouchUpInside];
    self.clearButton.alpha = 0;
    
    [titleView addSubview:self.clearButton];

}

-(void)showClearButton {
    
    //Scale clearButton up with a little jiggle
    [UIView animateWithDuration:0.1 delay:0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
        self.clearButton.transform = CGAffineTransformMakeScale(1.15, 1.15);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 delay:0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
            self.clearButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    }];
    
    //Fade in clearButton over total duration of scale
    [UIView animateWithDuration:0.2 delay:0.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        self.clearButton.alpha = 1;
    } completion:nil];
}

-(void)hideClearButton {
    
    //Scale clearButton down with anticipation
    [UIView animateWithDuration:0.1 delay:0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
        self.clearButton.transform = CGAffineTransformMakeScale(1.15, 1.15);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
            self.clearButton.transform = CGAffineTransformMakeScale(0.0001, 0.0001); //iOS does not scale to (0,0) for some reason :(
            self.clearButton.alpha = 0;
        } completion:nil];
    }];
}

#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidChange:(NSNotification *)notification {
    if ((![self.searchTextField.text isEqual: @""]) && (self.clearButton.alpha == 0)) {
        [self showClearButton];
    } else if ([self.searchTextField.text isEqual:@""]){
        [self hideClearButton];
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (![self.searchTextField.text isEqualToString: @""]) {
        [self showClearButton];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [self hideClearButton];
    
    if (textField.text) {
        [self performSearchWithQuery:textField.text];
    }
}

-(void)performSearchWithQuery:(NSString *)query {
    self.users = @[];
    self.galleries = @[];
    self.stories = @[];
    [self reloadData];
    
    [[FRSAPIClient sharedClient] searchWithQuery:query completion:^(id responseObject, NSError *error) {
        if (error || !responseObject) {
            [self searchError:error];
            return;
        }

        NSDictionary *storyObject = responseObject[@"stories"];
        NSDictionary *galleryObject = responseObject[@"galleries"];
        NSDictionary *userObject = responseObject[@"users"];
        self.users = storyObject[@"results"];
        self.galleries = [[FRSAPIClient sharedClient] parsedObjectsFromAPIResponse:galleryObject[@"results"] cache:NO];
        self.users = userObject[@"results"];
        self.stories = storyObject[@"results"];
        [self reloadData];
    }];
}

-(void)reloadData {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
-(void)searchError:(NSError *)error {
    NSLog(@"SEARCH ERROR: %@", error);
}

#pragma mark - UITableView Datasource

-(void)configureTableView{
    self.title = @"";
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64-44) style:UITableViewStyleGrouped];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.bounces = YES;
    self.tableView.backgroundColor = [UIColor frescoBackgroundColorDark];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    self.tableView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    int numberOfSections = 0;
    if (_users && ![_users isEqual:[NSNull null]]) {
        numberOfSections++;
    }
    if (_stories && ![_stories isEqual:[NSNull null]]) {
        numberOfSections++;
    }
    if (_galleries && ![_galleries isEqual:[NSNull null]]) {
        numberOfSections++;
    }
    return numberOfSections;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    NSLog(@"stories.count = %lu", self.stories.count);
    NSLog(@"users.count = %lu", self.users.count);
    
    if (section == userIndex) {
        
        if (_users.count == 0) {
            return 0;
        }
        
        if (_userExtended) {
            return _users.count;
        }
        
        if (_users.count == 0) {
            return 0;
        }
        
        if (_users.count > 5) {
            return 7;
        }
        else {
            return _users.count;
        }
        
        return _users.count + 2;
    }
    if (section == storyIndex) {
        
        if (_stories.count == 0) {
            return 0;
        }
        
        if (_storyExtended) {
            return _stories.count;
        }
        if (_stories.count == 0) {
            return 0;
        }
        
        if (_stories.count < 5) {
            return _stories.count;
        }
        return 5 + 2;
    }
    if (section == galleryIndex) {
        return self.galleries.count;
    }
    
    return 0;
}

-(BOOL)isNoData {
    return TRUE;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == storyIndex) {
        if (indexPath.row == 5 && !_storyExtended) {
            return 44;
        }
        if (indexPath.row == self.stories.count + 1) {
            return 12;
        }
        return 56;
    }
    else if (indexPath.section == userIndex) {
        if (indexPath.row == 5 && !_userExtended) {
            return 44;
        }
        
        if (indexPath.row == 6) { //The 6th row will be the empty space cell
            return 0;
        }
        
        return 56;
    }
    else {
        // galleries
        
        if (self.galleries.count <= 0) {
            return 0;
        }
        
        FRSGallery *gallery = [self.galleries objectAtIndex:indexPath.row];
        return [gallery heightForGallery];
    }

    return 0;
}

-(void)pushStoryView:(NSString *)storyID {
    NSManagedObjectContext *context = [[FRSAPIClient sharedClient] managedObjectContext];
    FRSStory *story = [NSEntityDescription insertNewObjectForEntityForName:@"FRSStory" inManagedObjectContext:context];

    story.uid = storyID;
    FRSStoryDetailViewController *detailView = [self detailViewControllerWithStory:story];
    [self.navigationController pushViewController:detailView animated:YES];

}

-(FRSStoryDetailViewController *)detailViewControllerWithStory:(FRSStory *)story {
    FRSStoryDetailViewController *detailView = [[FRSStoryDetailViewController alloc] initWithNibName:@"FRSStoryDetailViewController" bundle:[NSBundle mainBundle]];
    detailView.story = story;
    [detailView reloadData];
    return detailView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ((section == userIndex && self.users.count > 0 && self.users)) {
        return 30;
    }
    
    if ((section == storyIndex && self.stories.count > 0)) {
        return 30;
    }
    
    return 0;
}


-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
//    if (section == userIndex && self.users.count == 0) {
//        return [UIView new];
//    }
//    if (section == storyIndex && self.stories == 0) {
//        return [UIView new];
//    }
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 47)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, tableView.frame.size.width -32, 17)];
    [label setFont:[UIFont notaBoldWithSize:15]];
    [label setTextColor:[UIColor frescoMediumTextColor]];
    NSString *title = @"";
    
    if (section == userIndex && self.users.count > 0) {
        title = @"USERS";
    }
    else if (section == storyIndex && self.stories.count > 0) {
        title = @"STORIES";
    }


    [label setText:title];
    [view addSubview:label];
    [view setBackgroundColor:[UIColor frescoBackgroundColorDark]];
    return view;
}

-(UITableViewCell *)tableView:(FRSTableViewCell *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *galleryIdentifier;
    NSString *cellIdentifier;
    
    FRSTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[FRSTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
   
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if (indexPath.section == userIndex) {
        
        if (indexPath.row == 5 && !_userExtended) {
            [cell configureSearchSeeAllCellWithTitle:@"SEE ALL USERS"];
            return cell;
        }
        
        if ((indexPath.row == self.users.count + 1) || (indexPath.row == 6 && !_userExtended) || (self.users.count < 5 && indexPath.row == self.users.count)) {
            [cell configureEmptyCellSpace:NO];
            return cell;
        }
        
        // users
        NSDictionary *user = self.users[indexPath.row];
        NSString *avatarURL;
        if ([user objectForKey:@"avatar"] || ![[user objectForKey:@"avatar"] isEqual:[NSNull null]]) {
            avatarURL = user[@"avatar"];
        }
        
        NSURL *avatarURLObject;
        ;
        
        if (avatarURL && ![avatarURL isEqual:[NSNull null]]) {
            avatarURLObject = [NSURL URLWithString:avatarURL];
        }
        
        NSString *firstname = @" ";
        if (user[@"full_name"] || ![user[@"full_name"] isEqual:[NSNull null]]) {
            firstname = user[@"full_name"];
        }
        
        NSString *username = @" ";
        if (user[@"username"] || ![user[@"username"] isEqual:[NSNull null]]) {
            username = user[@"username"];
        }
        
        [cell configureSearchUserCellWithProfilePhoto:avatarURLObject fullName:firstname userName:username isFollowing:[user[@"following"] boolValue]];
        return cell;
    }
    else if (indexPath.section == storyIndex) {
        
        if (indexPath.row == self.stories.count) {
            [cell configureSearchSeeAllCellWithTitle:@"SEE ALL STORIES"];
            return cell;
        }
        
        if (indexPath.row == self.stories.count + 1) {
            [cell configureEmptyCellSpace:NO];
            return cell;
        }
        
        NSDictionary *story = self.stories[0];
        NSURL *photo;
        
        if ([story[@"thumbnails"] count] > 0) {
            photo = [NSURL URLWithString:story[@"thumbnails"][0][@"image"]];
        }
        
        NSString *title = @" ";
        if (story[@"title"] && ![story[@"title"] isEqual:[NSNull null]]) {
            title = story[@"title"];
        }
        
        [cell configureSearchStoryCellWithStoryPhoto:photo storyName:title];
        return cell;
    }
    
    if (indexPath.section == galleryIndex) {
        FRSGalleryCell *cell = [self.tableView dequeueReusableCellWithIdentifier:galleryIdentifier];
        if (!cell) {
            cell = [[FRSGalleryCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:galleryIdentifier];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.gallery = self.galleries[indexPath.row];
        
        __weak typeof(self) weakSelf = self;
        
        cell.shareBlock = ^void(NSArray *sharedContent) {
            [weakSelf showShareSheetWithContent:sharedContent];
        };
        
        cell.readMoreBlock = ^void(NSArray *sharedContent) {
            [self readMore:indexPath];
        };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell clearCell];
            [cell configureCell];
        });
        UITableViewCell *cellToReturn = (UITableViewCell *)cell;
        return cellToReturn;
    }

    return Nil;
}

-(void)showShareSheetWithContent:(NSArray *)content {
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:content applicationActivities:nil];
    [[[self.view window] rootViewController] presentViewController:activityController animated:YES completion:nil];
}

-(void)readMore:(NSIndexPath *)indexPath {
    FRSGalleryExpandedViewController *vc = [[FRSGalleryExpandedViewController alloc] initWithGallery:[self.galleries objectAtIndex:indexPath.row]];
    vc.shouldHaveBackButton = YES;
    
    self.navigationItem.title = @"";
    
    [self.navigationController pushViewController:vc animated:YES];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    [self hideTabBarAnimated:YES];
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(FRSTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    if (indexPath.section == userIndex) {
        if (indexPath.row >= self.users.count) {
            return;
        }
        
        NSDictionary *user = self.users[indexPath.row];
        FRSUser *userObject = [FRSUser nonSavedUserWithProperties:user context:[[FRSAPIClient sharedClient] managedObjectContext]];
        FRSProfileViewController *controller = [[FRSProfileViewController alloc] initWithUser:userObject];
        [self.navigationController pushViewController:controller animated:TRUE];
    }
    
    if (indexPath.section == storyIndex) {
        NSDictionary *story = self.stories[indexPath.row];
        [self pushStoryView:story[@"id"]];
    }
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.searchTextField resignFirstResponder];
}

#pragma mark - dealloc
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end