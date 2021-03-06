//
//  FRSPaymentManager.h
//  Fresco
//
//  Created by Maurice Wu on 1/29/17.
//  Copyright © 2017 Fresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRSBaseManager.h"

@interface FRSPaymentManager : FRSBaseManager

+ (instancetype)sharedInstance;

- (void)createPaymentWithToken:(NSString *)token completion:(FRSAPIDefaultCompletionBlock)completion;
- (void)fetchPayments:(FRSAPIDefaultCompletionBlock)completion;
- (void)deletePayment:(NSString *)paymentID completion:(FRSAPIDefaultCompletionBlock)completion;
- (void)makePaymentActive:(NSString *)paymentID completion:(FRSAPIDefaultCompletionBlock)completion;
- (void)updateIdentityWithDigestion:(NSDictionary *)digestion completion:(FRSAPIDefaultCompletionBlock)completion;
- (void)updateIdentityWithDigestion:(NSDictionary *)digestion andSsn:(NSString *)ssn completion:(FRSAPIDefaultCompletionBlock)completion;
- (void)uploadStateIDWithParameters:(NSData *)parameters completion:(FRSAPIDefaultCompletionBlock)completion;
- (void)updateTaxInfoWithFileID:(NSString *)fileID completion:(FRSAPIDefaultCompletionBlock)completion;

@end
