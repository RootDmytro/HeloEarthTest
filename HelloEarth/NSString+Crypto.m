//
//  NSString+Crypto.m
//  HelloEarth
//
//  Created by Dmytro Yaropovetsky on 1/23/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import "NSString+Crypto.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSString (Additions)

- (NSArray<NSString *> *)componentsSeparatedBySpacer:(NSString *)spacer {
	NSMutableArray<NSString *> *tokens = [[self componentsSeparatedByString:spacer] mutableCopy];
	[tokens removeObject:@""];
	return tokens;
}

- (NSArray<NSString *> *)splitTokens {
	return [self componentsSeparatedBySpacer:@" "];
}

- (NSString *)nonemptyString {
	return self.length ? self : nil;
}

- (NSString *)trimmWhitespaces {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSRange)fullRange {
	return NSMakeRange(0, self.length);
}

- (NSArray<NSString *> *)matchesForPattern:(NSString *)pattern {
	return [self matchesForPattern:pattern options:NSRegularExpressionCaseInsensitive];
}

- (NSArray<NSString *> *)matchesForPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options {
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&error];
	NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:self options:0 range:self.fullRange];
	
	NSMutableArray<NSString *> *matchStrings = [NSMutableArray arrayWithCapacity:matches.count];
	for (NSTextCheckingResult *match in matches) {
		[matchStrings addObject:[self substringWithRange:match.range]];
	}
	return [NSArray arrayWithArray:matchStrings];
}

- (NSArray<NSArray<NSString *> *> *)capturesForPattern:(NSString *)pattern {
	return [self capturesForPattern:pattern options:NSRegularExpressionCaseInsensitive];
}

- (NSArray<NSArray<NSString *> *> *)capturesForPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options {
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&error];
	NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:self options:0 range:self.fullRange];
	
	NSMutableArray<NSArray<NSString *> *> *captureGroups = [NSMutableArray arrayWithCapacity:matches.count];
	for (NSTextCheckingResult *match in matches) {
		NSMutableArray<NSString *> *captureStrings = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
		for (NSUInteger i = 0; i < match.numberOfRanges; i++) {
			NSRange range = [match rangeAtIndex:i];
			if (range.location != NSNotFound) {
				[captureStrings addObject:[self substringWithRange:range]];
			}
		}
		[captureGroups addObject:[NSArray arrayWithArray:captureStrings]];
	}
	return [NSArray arrayWithArray:captureGroups];
}

- (NSArray<NSArray<NSString *> *> *)staticCapturesForPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options {
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&error];
	NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:self options:0 range:self.fullRange];
	
	NSMutableArray<NSArray<NSString *> *> *captureGroups = [NSMutableArray arrayWithCapacity:matches.count];
	for (NSTextCheckingResult *match in matches) {
		NSMutableArray<NSString *> *captureStrings = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
		for (NSUInteger i = 0; i < match.numberOfRanges; i++) {
			NSRange range = [match rangeAtIndex:i];
			[captureStrings addObject:range.location != NSNotFound ? [self substringWithRange:range] : (NSString *)[NSNull null]];
		}
		[captureGroups addObject:[NSArray arrayWithArray:captureStrings]];
	}
	return [NSArray arrayWithArray:captureGroups];
}

- (NSArray<NSValue *> *)rangesOfString:(NSString *)searchString options:(NSStringCompareOptions)mask {
	NSMutableArray<NSValue *> *ranges = [NSMutableArray new];
	NSRange fullRange = self.fullRange;
	while (fullRange.length > 0) {
		NSRange range = [self rangeOfString:searchString options:mask range:fullRange];
		if (range.location != NSNotFound) {
			[ranges addObject:[NSValue valueWithRange:range]];
			fullRange.location = NSMaxRange(range);
			if (self.length < fullRange.location) {
				break;
			}
			fullRange.length = self.length - fullRange.location;
		} else {
			break;
		}
	}
	return ranges.copy;
}

@end

@implementation NSString (Crypto)

- (NSString *)md5
{
	// Create pointer to the string as UTF8
	const char *ptr = [self UTF8String];
	
	// Create byte array of unsigned chars
	unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
	
	// Create 16 byte MD5 hash value, store in buffer
	CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
	
	// Convert MD5 value in the buffer to NSString of hex values
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
		[output appendFormat:@"%02x",md5Buffer[i]];
	}
	
	return output;
}

- (NSString *)sha256
{
	CC_SHA256_CTX context;
	unsigned char digest[CC_SHA256_DIGEST_LENGTH];
	
	CC_SHA256_Init(&context);
	memset(digest, 0, sizeof(digest));
	
	CC_SHA256_Update(&context, self.UTF8String, (CC_LONG)self.length);
	
	CC_SHA256_Final(digest, &context);
	
	NSMutableString *str = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
		[str appendFormat:@"%02x", digest[i]];
	}
	
	return [NSString stringWithString:str];
}

- (NSString *)sha512
{
	CC_SHA512_CTX context;
	unsigned char digest[CC_SHA512_DIGEST_LENGTH];
	
	CC_SHA512_Init(&context);
	memset(digest, 0, sizeof(digest));
	
	CC_SHA512_Update(&context, self.UTF8String, (CC_LONG)self.length);
	
	CC_SHA512_Final(digest, &context);
	
	NSMutableString *str = [NSMutableString stringWithCapacity:CC_SHA512_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_SHA512_DIGEST_LENGTH; i++) {
		[str appendFormat:@"%02x", digest[i]];
	}
	
	return [NSString stringWithString:str];
}

@end


@implementation NSString (AirportCode)

// technically pseudo ICAO codes can be up to 7 letters, but our system only supports up to 4 characters
- (BOOL)isValidAirportCode {
	NSUInteger length = self.trimmWhitespaces.length;
	return length > 1 && length <= 4 && ![self isEqualToString:@"ZZZZ"];
}

- (BOOL)isValidICAOCode {
	return self.isValidAirportCode && self.trimmWhitespaces.length == 4 && [self matchesForPattern:@"\\b[A-Z]{4}\\b"].count == 1;
}

@end
