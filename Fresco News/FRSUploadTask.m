//
//  FRSUploadTask.m
//  Fresco
//
//  Created by Philip Bernstein on 4/25/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import "FRSUploadTask.h"
#import "Fresco.h"

@implementation FRSUploadTask
@synthesize uploadTask = _uploadTask;
// sets up architecture, start initializes request
-(void)createUploadFromSource:(NSURL *)asset destination:(NSURL *)destination progress:(TransferProgressBlock)progress completion:(TransferCompletionBlock)completion {
    
    self.assetURL = asset;
    self.destinationURL = destination;
    self.progressBlock = progress;
    self.completionBlock = completion;
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.fresconews.upload.background"];
    
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
}

-(void)stop {
    [_uploadTask suspend];
}

-(void)start {
    if (_uploadTask) {
        return; // FRSUploadTask are one off, no re-use
    }
    
    NSMutableURLRequest *uploadRequest;
    [self signRequest:uploadRequest];
    
    _uploadTask = [self.session uploadTaskWithRequest:uploadRequest fromFile:self.assetURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
            if (self.delegate) {
                [self.delegate uploadDidFail:self withError:error response:data];
            }
        }
        else {
            if (self.delegate) {
                [self.delegate uploadDidSucceed:self withResponse:data];
            }
        }
        
        if (self.completionBlock) {
            self.completionBlock(self, data, error, (error == Nil));
        }
        
    }];
    
    [_uploadTask resume]; // starts initial request
}

-(void)pause {
    [_uploadTask suspend];
}

-(void)resume {
    [_uploadTask resume];
}

-(void)signRequest:(NSMutableURLRequest *)request {
    NSString *authorizationString = [NSString stringWithFormat:@"Bearer: %@", [self authenticationToken]];
    [request setValue:authorizationString forHTTPHeaderField:@"Authorization"];
}

- (void)URLSession:(NSURLSession *)urlSession task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {

}

-(NSString *)authenticationToken {
    
    NSArray *allAccounts = [SSKeychain accountsForService:serviceName];
    
    if ([allAccounts count] == 0) {
        return clientAuthorization; // client as default
    }
    
    NSDictionary *credentialsDictionary = [allAccounts firstObject];
    NSString *accountName = credentialsDictionary[kSSKeychainAccountKey];
    
    return [SSKeychain passwordForService:serviceName account:accountName];
}

@end
