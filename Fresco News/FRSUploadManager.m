//
//  FRSUploadManager.m
//  Fresco
//
//  Created by Philip Bernstein on 7/14/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSUploadManager.h"
#import "FRSAPIClient.h"
#import "Fresco.h"

@implementation FRSUploadManager

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)commonInit {
    _tasks = [[NSMutableArray alloc] init];
    _currentTasks = [[NSMutableArray alloc] init];
    _etags = [[NSMutableArray alloc] init];
    weakSelf = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"FRSRetryUpload" object:nil queue:nil usingBlock:^(NSNotification *notification) {
        totalBytesSent = 0;
        _tasks = [[NSMutableArray alloc] init];
        _currentTasks = [[NSMutableArray alloc] init];
        _etags = [[NSMutableArray alloc] init];

        if (_gallery) {
            [self startUploadProcess];
        }
    }];
    
    if (_gallery) {
        [self startUploadProcess];
    }
}

-(void)startUploadProcess {
    if (!_posts) {
        return;
    }
    
    for (int i = 0; i < _posts.count; i++) {
        PHAsset *currentAsset = _assets[i];
        NSDictionary *currentPost = _posts[i];
        
        if (currentAsset.mediaType == PHAssetMediaTypeVideo) {
            
            NSMutableArray *urls = [[NSMutableArray alloc] init];
            
            for (NSString *partURL in currentPost[@"urls"]) {
                [urls addObject:[NSURL URLWithString:partURL]];
            }
            
            [self addMultipartTaskForAsset:currentAsset urls:urls post:currentPost];
        }
        else {
            [self addTaskForImageAsset:currentAsset url:[NSURL URLWithString:currentPost[@"urls"][0]] post:currentPost];
        }
    }
}

-(void)addTask:(FRSUploadTask *)task {
    [_tasks addObject:task];
    
    if (_currentTasks.count == 0 && _tasks.count == 1) {
        [self start];
    }
}

-(void)start {
    if (_tasks.count == 0) {
        return;
    }
    
    FRSUploadTask *task = [_tasks firstObject];
    [task start];
}

-(void)uploadedData:(int64_t)bytes {
    totalBytesSent += bytes;
    NSLog(@"PROGRESS: %f", (totalBytesSent * 1.0) / (_contentSize * 1.0));
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FRSUploadUpdate" object:nil userInfo:@{@"type":@"progress", @"percentage":@((totalBytesSent * 1.0) / (_contentSize * 1.0))}];
}

-(void)addMultipartTaskForAsset:(PHAsset *)asset urls:(NSArray *)urls post:(NSDictionary *)post {
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    options.progressHandler =  ^(double progress,NSError *error,BOOL* stop, NSDictionary* dict) {
        NSLog(@"progress %lf",progress);  //never gets called
    };
    
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
        AVURLAsset* myAsset = (AVURLAsset*)avasset;
        
        FRSMultipartTask *multipartTask = [[FRSMultipartTask alloc] init];
        
        [multipartTask createUploadFromSource:myAsset.URL destinations:urls progress:^(id task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            [self uploadedData:bytesSent];
        } completion:^(id task, NSData *responseData, NSError *error, BOOL success, NSURLResponse *response) {
            if (success) {
                NSMutableDictionary *postCompletionDigest = [[NSMutableDictionary alloc] init];
                postCompletionDigest[@"eTags"] = multipartTask.eTags;
                postCompletionDigest[@"uploadId"] = post[@"uploadId"];
                postCompletionDigest[@"key"] = post[@"key"];
                [[FRSAPIClient sharedClient] completePost:post[@"post_id"] params:postCompletionDigest completion:^(id responseObject, NSError *error) {
                    
                    NSMutableDictionary *postCompletionDigest = [[NSMutableDictionary alloc] init];
                    postCompletionDigest[@"eTags"] = multipartTask.eTags;
                    postCompletionDigest[@"uploadId"] = post[@"uploadId"];
                    postCompletionDigest[@"key"] = post[@"key"];
                    
                    [[FRSAPIClient sharedClient] completePost:post[@"post_id"] params:postCompletionDigest completion:^(id responseObject, NSError *error) {
                        NSLog(@"POST COMPLETED: %@", (error == Nil) ? @"TRUE" : @"FALSE");
                        
                        if (!error) {
                            [self next:task];
                        }
                        else {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"FRSUploadUpdate" object:nil userInfo:@{@"type":@"failure"}];
                        }
                    }];
                }];
            }
            else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FRSUploadUpdate" object:nil userInfo:@{@"type":@"failure"}];
            }
        }];
        
        [self addTask:multipartTask];
    }];
}

-(void)addTaskForImageAsset:(PHAsset *)asset url:(NSURL *)url post:(NSDictionary *)post {
    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        
        FRSUploadTask *task = [[FRSUploadTask alloc] init];
        
        [task createUploadFromData:imageData destination:url progress:^(id task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            [self uploadedData:bytesSent];
        } completion:^(id task, NSData *responseData, NSError *error, BOOL success, NSURLResponse *response) {
            if (success) {
                if (success) {
                    NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
                    NSString *eTag = headers[@"Etag"];
                    
                    NSMutableDictionary *postCompletionDigest = [[NSMutableDictionary alloc] init];
                    postCompletionDigest[@"eTags"] = @[eTag];
                    postCompletionDigest[@"uploadId"] = post[@"uploadId"];
                    postCompletionDigest[@"key"] = post[@"key"];
                    [[FRSAPIClient sharedClient] completePost:post[@"post_id"] params:postCompletionDigest completion:^(id responseObject, NSError *error) {
                        NSLog(@"POST COMPLETED: %@", (error == Nil) ? @"TRUE" : @"FALSE");
                        
                        if (!error) {
                            [self next:task];
                        }
                        else {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"FRSUploadUpdate" object:nil userInfo:@{@"type":@"failure"}];
                        }
                    }];
                }
            }
            else {
                NSLog(@"%@", error);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FRSUploadUpdate" object:nil userInfo:@{@"type":@"failure"}];
            }
        }];
        
        [self addTask:task];
    }];
}

-(void)pause {
    
}

-(void)resume {
    
}

-(void)next:(FRSUploadTask *)task {
    
    [_tasks removeObject:task];
    [_currentTasks removeObject:task];
    
    if (_currentTasks.count < maxConcurrent && _tasks.count > 0) {
        FRSUploadTask *task = [_tasks firstObject];
        [task start];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FRSUploadUpdate" object:nil userInfo:@{@"type":@"completion"}];
        NSLog(@"GALLERY CREATION COMPLETE");
    }
}

-(instancetype)init {
    self = [super init];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

-(instancetype)initWithGallery:(NSDictionary *)gallery assets:(NSArray *)assets {
    self = [super init];
    
    if (self) {
        _assets = assets;
        _gallery = gallery;
        
        _posts = _gallery[@"posts"];
        [self commonInit];
    }
    
    return self;
}

@end
