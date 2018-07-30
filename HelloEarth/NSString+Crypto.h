//
//  NSString+Hello.h
//  HelloEarth
//
//  Created by Dmytro Yaropovetsky on 1/23/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Additions)

- (NSArray<NSString *> *)componentsSeparatedBySpacer:(NSString *)spacer;
- (NSArray<NSString *> *)splitTokens;

- (NSString *)nonemptyString;
- (NSString *)trimmWhitespaces;

/// @return NSRange with @c .length member equal to receiver's length
- (NSRange)fullRange;

- (NSArray<NSString *> *)matchesForPattern:(NSString *)pattern;
- (NSArray<NSString *> *)matchesForPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options;

- (NSArray<NSArray<NSString *> *> *)capturesForPattern:(NSString *)pattern;
- (NSArray<NSArray<NSString *> *> *)capturesForPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options;
- (NSArray<NSArray<NSString *> *> *)staticCapturesForPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options;

- (NSArray<NSValue *> *)rangesOfString:(NSString *)searchString options:(NSStringCompareOptions)mask;

@end


@interface NSString (Crypto)

- (NSString *)md5;
- (NSString *)sha256;
- (NSString *)sha512;

@end


@interface NSString (AirportCode)

- (BOOL)isValidAirportCode;
- (BOOL)isValidICAOCode;

@end
