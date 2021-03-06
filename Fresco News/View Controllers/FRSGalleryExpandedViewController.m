//
//  FRSGalleryExpandedViewController.m
//  Fresco
//
//  Created by Daniel Sun on 1/12/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSGalleryExpandedViewController.h"
#import "FRSGallery.h"
#import "FRSArticle.h"
#import "FRSComment.h"
#import "PeekPopArticleViewController.h"
#import "Haneke.h"
#import "FRSAlertView.h"
#import "FRSGalleryDetailView.h"
#import "FRSUserManager.h"
#import "FRSAuthManager.h"
#import "FRSModerationManager.h"
#import "FRSGalleryManager.h"
#import "FRSModerationAlertView.h"

@interface FRSGalleryExpandedViewController () <UIScrollViewDelegate, UIViewControllerPreviewingDelegate, FRSAlertViewDelegate, UITextFieldDelegate, FRSGalleryDetailViewDelegate>

@property (nonatomic) BOOL touchEnabled;

@property (strong, nonatomic) UILabel *titleLabel;

@property (strong, nonatomic) FRSModerationAlertView *galleryReportAlertView;
@property (strong, nonatomic) FRSModerationAlertView *reportUserAlertView;
@property (strong, nonatomic) FRSAlertView *errorAlertView;

@property (strong, nonatomic) NSString *reportReasonString;
@property (strong, nonatomic) NSString *galleryID;

@property BOOL didDisplayReport;
@property BOOL didDisplayBlock;
@property BOOL didBlockUser;
@property BOOL isReportingComment;
@property BOOL isBlockingFromComment;

@property (strong, nonatomic) NSDictionary *currentCommentUserDictionary;

@end

@implementation FRSGalleryExpandedViewController {
    FRSGalleryDetailView *galleryDetailView;
}

static NSString *reusableCommentIdentifier = @"commentIdentifier";

- (instancetype)initWithGallery:(FRSGallery *)gallery {
    self = [super init];
    if (self) {
        self.gallery = gallery; //Remove after tested
        galleryDetailView.gallery = gallery;
        galleryDetailView.delegate = self;
        galleryDetailView.navigationController = self.navigationController;

        if (gallery.uid) {
            self.galleryID = gallery.uid;
        }
        self.hiddenTabBar = YES;
        self.touchEnabled = NO;
        [galleryDetailView fetchCommentsWithID:gallery.uid];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureNavigationBar];
    [self configureNIBDetailView];

    [self.view updateConstraints];
    [self.view layoutSubviews];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard:(UITapGestureRecognizer *)tap {
    [galleryDetailView.commentTextField resignFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self register3DTouch];

    [FRSTracker screen:@"Gallery Detail"];

    dateEntered = [NSDate date];

    // Access followingButton and update icon when view appears
    [galleryDetailView.galleryView.galleryFooterView.userView.followingButton updateIconForFollowing:[self.gallery.creator.following boolValue]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.navigationItem.titleView = self.titleLabel;
    [self hideTabBarAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.navigationItem.titleView = self.titleLabel;
    [self showTabBarAnimated:NO];

    [self trackSession];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureNIBDetailView {
    galleryDetailView = [[[NSBundle mainBundle] loadNibNamed:@"FRSGalleryDetailView" owner:self options:nil] objectAtIndex:0];
    galleryDetailView.delegate = self;
    galleryDetailView.navigationController = self.navigationController;
    [self.view addSubview:galleryDetailView];

    galleryDetailView.frame = self.view.frame;
    galleryDetailView.parentVC = self;
    galleryDetailView.trackedScreen = self.trackedScreen;

    [galleryDetailView loadGalleryDetailViewWithGallery:self.gallery parentVC:self];
}

- (void)configureNavigationBar {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"GALLERY";
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont notaBoldWithSize:17];
    [self.titleLabel sizeToFit];
    self.titleLabel.center = self.view.center;
    self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, 0, self.titleLabel.frame.size.width, 44);

    self.navigationItem.titleView = self.titleLabel;
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];

    UIBarButtonItem *dots = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dots"] style:UIBarButtonItemStylePlain target:self action:@selector(presentReportGallerySheet)];

    dots.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];

    self.navigationItem.rightBarButtonItems = @[ dots ];

    if ([[[self.gallery creator] uid] isEqualToString:[[FRSUserManager sharedInstance] authenticatedUser].uid]) {
        self.navigationItem.rightBarButtonItems = nil;
    }
}

- (void)popViewController {
    [super popViewController];
    [self showTabBarAnimated:YES];
}

- (void)presentReportGallerySheet {

    NSString *username = @"user";

    if (self.gallery.creator.username) {
        username = self.gallery.creator.username;
    } else if (self.gallery.creator.firstName) {
        username = self.gallery.creator.firstName;
    } else if (self.gallery.byline) {
        username = self.gallery.byline;
    }

    UIAlertController *view = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *block = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Block %@", username]
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {

                                                    [self blockUser:self.gallery.creator];

                                                    [view dismissViewControllerAnimated:YES completion:nil];
                                                  }];

    UIAlertAction *unblock = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Unblock %@", username]
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {

                                                      [self unblockUser:self.gallery.creator.uid];

                                                      [view dismissViewControllerAnimated:YES completion:nil];
                                                    }];

    UIAlertAction *reportGallery = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Report this gallery"]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {

                                                            self.galleryReportAlertView = [[FRSModerationAlertView alloc] initGalleryReportDelegate:self];
                                                            self.galleryReportAlertView.delegate = self;
                                                            [self.galleryReportAlertView show];

                                                            [view dismissViewControllerAnimated:YES completion:nil];
                                                          }];

    UIAlertAction *report = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Report %@", username]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {

                                                     self.reportUserAlertView = [[FRSModerationAlertView alloc] initUserReportWithUsername:[NSString stringWithFormat:@"%@", username] delegate:self];
                                                     self.reportUserAlertView.delegate = self;
                                                     self.didDisplayReport = YES;
                                                     [self.reportUserAlertView show];

                                                     [view dismissViewControllerAnimated:YES completion:nil];
                                                   }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction *action) {

                                                     [view dismissViewControllerAnimated:YES completion:nil];
                                                   }];

    [view addAction:reportGallery];

    if (![[[self.gallery creator] uid] isEqualToString:@""] && [self.gallery creator] != nil) {
        if ([[FRSAuthManager sharedInstance] isAuthenticated]) {
            [view addAction:report];
        }
        if ([[[FRSUserManager sharedInstance] authenticatedUser] blocking] || self.didBlockUser) {
            if ([[FRSAuthManager sharedInstance] isAuthenticated]) {
                [view addAction:unblock];
            }
        } else {
            if ([[FRSAuthManager sharedInstance] isAuthenticated]) {
                [view addAction:block];
            }
        }
    }
    [view addAction:cancel];

    [self presentViewController:view animated:YES completion:nil];
}

- (void)presentFlagCommentSheet:(FRSComment *)comment {
    UIAlertController *view = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    self.currentCommentUserDictionary = comment.userDictionary;

    NSLog(@"userDictionary: %@", comment.userDictionary);

    NSString *username;

    if (comment.userDictionary[@"username"] != [NSNull null] && (![comment.userDictionary[@"username"] isEqualToString:@"<null>"])) {
        username = [NSString stringWithFormat:@"@%@", comment.userDictionary[@"username"]];
    } else if (comment.userDictionary[@"full_name"] != [NSNull null] && (![comment.userDictionary[@"full_name"] isEqualToString:@"<null>"])) {
        username = comment.userDictionary[@"full_name"];
    } else {
        username = @"them";
    }

    UIAlertAction *block = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Block %@", username]
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *action) {

                                                    [[FRSModerationManager sharedInstance] blockUser:comment.userDictionary[@"id"]
                                                                                      withCompletion:^(id responseObject, NSError *error) {

                                                                                        if (responseObject) {
                                                                                            FRSAlertView *alert = [[FRSAlertView alloc] initWithTitle:@"BLOCKED" message:[NSString stringWithFormat:@"You won’t see posts from %@ anymore.", username] actionTitle:@"UNDO" cancelTitle:@"OK" cancelTitleColor:[UIColor frescoBlueColor] delegate:self];
                                                                                            self.didDisplayBlock = YES;
                                                                                            [alert show];
                                                                                            self.isBlockingFromComment = YES;

                                                                                        } else {
                                                                                            [self presentGenericError];
                                                                                        }
                                                                                      }];

                                                    [view dismissViewControllerAnimated:YES completion:nil];
                                                  }];

    UIAlertAction *unblock = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Unblock %@", username]
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {

                                                      [[FRSModerationManager sharedInstance] unblockUser:comment.userDictionary[@"id"]
                                                                                          withCompletion:^(id responseObject, NSError *error) {

                                                                                            if (responseObject) {

                                                                                            } else {
                                                                                                [self presentGenericError];
                                                                                            }
                                                                                          }];

                                                      [view dismissViewControllerAnimated:YES completion:nil];
                                                    }];

    UIAlertAction *report = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Report %@", username]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {

                                                     self.isReportingComment = YES;
                                                     self.reportUserAlertView = [[FRSModerationAlertView alloc] initUserReportWithUsername:[NSString stringWithFormat:@"%@", username] delegate:self];
                                                     self.reportUserAlertView.delegate = self;
                                                     self.didDisplayReport = YES;
                                                     [self.reportUserAlertView show];

                                                     [view dismissViewControllerAnimated:YES completion:nil];
                                                   }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction *action) {

                                                     [view dismissViewControllerAnimated:YES completion:nil];
                                                   }];

    [view addAction:report];

    if (![comment.userDictionary[@"blocked"] boolValue]) {
        [view addAction:block];
    } else {
        [view addAction:unblock];
    }

    [view addAction:cancel];

    [self presentViewController:view animated:YES completion:nil];
}

#pragma mark - 3D Touch

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self register3DTouch];
}

- (void)register3DTouch {
    if ((self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) && (self.touchEnabled == NO)) {
        self.touchEnabled = YES;
        [self registerForPreviewingWithDelegate:self sourceView:galleryDetailView.articlesTableView];
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {

    CGPoint cellPostion = [galleryDetailView.articlesTableView convertPoint:location fromView:galleryDetailView.articlesTableView];
    NSIndexPath *path = [galleryDetailView.articlesTableView indexPathForRowAtPoint:cellPostion];
    [previewingContext setSourceRect:[galleryDetailView.articlesTableView rectForRowAtIndexPath:path]];

    PeekPopArticleViewController *vc = [[PeekPopArticleViewController alloc] init];
    UIView *contentView = vc.view;

    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, contentView.frame.size.width, contentView.frame.size.height)];
    [contentView addSubview:webView];
    FRSArticle *article = [self.gallery.articles allObjects][path.row];
    NSString *urlString = article.articleStringURL;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    vc.title = urlString;

    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {

    NSURL *url = [NSURL URLWithString:viewControllerToCommit.title];

    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [FRSTracker track:articleOpens parameters:@{ @"article_url" : viewControllerToCommit.title }];
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark - FRSAlertViewDelegate

- (void)reportGalleryAlertAction {
    [[FRSModerationManager sharedInstance] reportGallery:self.gallery
        params:@{ @"reason" : self.reportReasonString,
                  @"message" : self.galleryReportAlertView.textView.text }
        completion:^(id responseObject, NSError *error) {
          if (error) {
              [self presentGenericError];
              return;
          }

          if (responseObject) {
              FRSAlertView *alert = [[FRSAlertView alloc] initWithTitle:@"REPORT SENT" message:@"Thanks for helping make Fresco a better community!" actionTitle:@"YOU’RE WELCOME" cancelTitle:@"" cancelTitleColor:nil delegate:nil];
              [alert show];
          }
        }];
}

- (void)reportUserAlertAction {
    NSString *username = @"";

    if ([self.gallery.creator.username class] != [NSNull null] && (![self.gallery.creator.username isEqualToString:@"<null>"])) {
        username = [NSString stringWithFormat:@"@%@", self.gallery.creator.username];
    } else if (self.currentCommentUserDictionary[@"full_name"] != [NSNull null] && (![self.gallery.creator.firstName isEqualToString:@"<null>"])) {
        username = self.gallery.creator.firstName;
    } else {
        username = @"them";
    }

    if (self.isReportingComment) {
        [self reportUser:self.currentCommentUserDictionary[@"id"]];
    } else {
        [self reportUser:self.gallery.creator.uid];
    }
}

- (void)didPressRadioButtonAtIndex:(NSInteger)index {
    if (self.reportUserAlertView || self.galleryReportAlertView) {
        switch (index) {
        case 0:
            self.reportReasonString = @"abuse";
            break;
        case 1:
            self.reportReasonString = @"spam";
            break;
        case 2:
            self.reportReasonString = @"stolen";
            break;
        case 3:
            self.reportReasonString = @"nsfw";
            break;
        default:
            break;
        }
    }
}

- (void)didPressButton:(FRSAlertView *)alertView atIndex:(NSInteger)index {
    if (self.didDisplayReport) {
        self.didDisplayReport = NO;
        self.reportUserAlertView = nil;
        if (index == 1) {
            NSString *username = @"";
            if (self.isReportingComment) {
                if (self.currentCommentUserDictionary[@"username"] != [NSNull null] && (![self.currentCommentUserDictionary[@"username"] isEqualToString:@"<null>"])) {
                    username = [NSString stringWithFormat:@"@%@", self.currentCommentUserDictionary[@"username"]];
                } else if (self.currentCommentUserDictionary[@"full_name"] != [NSNull null] && (![self.currentCommentUserDictionary[@"full_name"] isEqualToString:@"<null>"])) {
                    username = self.currentCommentUserDictionary[@"full_name"];
                } else {
                    username = @"them";
                }
            } else {
                if ([self.gallery.creator.username class] != [NSNull null] && (![self.gallery.creator.username isEqualToString:@"<null>"])) {
                    username = [NSString stringWithFormat:@"@%@", self.gallery.creator.username];
                } else if ([self.gallery.creator.firstName class] != [NSNull null] && (![self.gallery.creator.firstName isEqualToString:@"<null>"])) {
                    username = self.gallery.creator.firstName;
                } else {
                    username = @"them";
                }
            }

            FRSAlertView *alert = [[FRSAlertView alloc] initWithTitle:@"BLOCKED" message:[NSString stringWithFormat:@"You won’t see posts from %@ anymore.", username] actionTitle:@"UNDO" cancelTitle:@"OK" cancelTitleColor:[UIColor frescoBlueColor] delegate:self];
            self.isReportingComment = NO;
            [alert show];
        }
    } else if (self.didDisplayBlock) {
        self.didDisplayBlock = NO;
        if (index == 0) {
            if (self.isBlockingFromComment) {
                [self unblockUser:self.currentCommentUserDictionary[@"id"]];
            } else {
                [self unblockUser:self.gallery.creator.uid];
            }
        }
    } else if (self.errorAlertView) {
        if (index == 0) {
            [galleryDetailView.commentTextField resignFirstResponder];
            [galleryDetailView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        } else if (index == 1) {
            [galleryDetailView sendComment];
        }
    }
}

#pragma mark - Moderation

- (void)blockUser:(FRSUser *)user {
    [[FRSModerationManager sharedInstance] blockUser:user.uid
                                      withCompletion:^(id responseObject, NSError *error) {

                                        if (responseObject) {
                                            FRSAlertView *alert = [[FRSAlertView alloc] initWithTitle:@"BLOCKED" message:[NSString stringWithFormat:@"You won’t see posts from %@ anymore.", user.username] actionTitle:@"UNDO" cancelTitle:@"OK" cancelTitleColor:[UIColor frescoBlueColor] delegate:self];
                                            self.didDisplayBlock = YES;
                                            [alert show];
                                            self.didBlockUser = YES;
                                            self.isBlockingFromComment = NO;
                                        } else {
                                            [self presentGenericError];
                                        }
                                      }];
}

- (void)unblockUser:(NSString *)userID {
    [[FRSModerationManager sharedInstance] unblockUser:userID
                                        withCompletion:^(id responseObject, NSError *error) {

                                          if (responseObject) {
                                              self.didBlockUser = NO;
                                          }

                                          if (error) {
                                              [self presentGenericError];
                                          }
                                        }];
}

- (void)reportUser:(NSString *)userID {
    [[FRSModerationManager sharedInstance] reportUser:userID
        params:@{ @"reason" : self.reportReasonString,
                  @"message" : self.reportUserAlertView.textView.text }
        completion:^(id responseObject, NSError *error) {

          if (error) {
              [self presentGenericError];
              return;
          }

          if (responseObject) {

              NSString *username = @"";

              if (self.isReportingComment) {

                  if (self.currentCommentUserDictionary[@"username"] != [NSNull null] && (![self.currentCommentUserDictionary[@"username"] isEqualToString:@"<null>"])) {
                      username = [NSString stringWithFormat:@"@%@", self.currentCommentUserDictionary[@"username"]];
                  } else if (self.currentCommentUserDictionary[@"full_name"] != [NSNull null] && (![self.currentCommentUserDictionary[@"full_name"] isEqualToString:@"<null>"])) {
                      username = self.currentCommentUserDictionary[@"full_name"];
                  } else {
                      username = @"them";
                  }
              } else {

                  if ([self.gallery.creator.username class] != [NSNull null] && (![self.gallery.creator.username isEqualToString:@"<null>"])) {
                      username = [NSString stringWithFormat:@"@%@", self.gallery.creator.username];
                  } else if ([self.gallery.creator.firstName class] != [NSNull null] && (![self.gallery.creator.firstName isEqualToString:@"<null>"])) {
                      username = self.gallery.creator.firstName;
                  } else {
                      username = @"them";
                  }
              }

              FRSAlertView *alert = [[FRSAlertView alloc] initWithTitle:@"REPORT SENT" message:[NSString stringWithFormat:@"Thanks for helping make Fresco a better community! Would you like to block %@ as well?", username] actionTitle:@"CLOSE" cancelTitle:@"BLOCK USER" cancelTitleColor:[UIColor frescoBlueColor] delegate:self];
              [alert show];
          }
        }];
}

- (void)trackSession {
    NSTimeInterval timeInSession = -1 * [dateEntered timeIntervalSinceNow];
    NSString *galleryID = self.gallery.uid;
    NSString *authorID = self.gallery.creator.uid;

    if (!galleryID || [galleryID isEqual:[NSNull null]] || ![[galleryID class] isSubclassOfClass:[NSString class]]) {
        galleryID = @"";
    }

    if (!authorID || [authorID isEqual:[NSNull null]] || ![[authorID class] isSubclassOfClass:[NSString class]]) {
        authorID = @"";
    }

    if (!_openedFrom || [_openedFrom isEqual:[NSNull null]] || ![[_openedFrom class] isSubclassOfClass:[NSString class]]) {
        _openedFrom = @"";
    }

    NSDictionary *session = @{
        @"activity_duration" : @(timeInSession),
        @"gallery_id" : galleryID,
        @"scrolled_percent" : @(percentageScrolled * 100),
        @"author" : authorID,
        @"opened_from" : _openedFrom
    };

    [FRSTracker track:gallerySession parameters:session];
}


@end
