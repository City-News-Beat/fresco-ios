//
//  NSString+Validation.h
//  Fresco
//
//  Created by Fresco News on 8/5/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Validation)

- (BOOL)isValidEmail;
- (BOOL)isValidPassword;
- (BOOL)isValidUsername;
- (BOOL)stringContainsEmoji;
+ (NSString *)formatCreditCard:(NSString *)input;
+ (NSString *)formatCreditCardExpiry:(NSString *)input;

@end
