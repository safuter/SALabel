//
//  NSString+Util.h
//  mathTest
//
//  Created by zhangz on 2025/3/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Util)
/**
 Returns a lowercase NSString for md5 hash.
 */
- (nullable NSString *)md5String;

/**
 Replaces occurrences of a regular expression pattern with a template string.

 @param pattern The regular expression pattern to search for.
 @param replacement The template string to replace with.
 @return A new string with all matches of the regular expression pattern replaced by the template string.
 */
- (nullable NSString *)stringByReplacingOccurrencesOfRegex:(NSString *)pattern withString:(NSString *)replacement;

- (NSString *)stringByTrim;
- (void)enumerateRegexMatches:(NSString *)regex
                      options:(NSRegularExpressionOptions)options
                   usingBlock:(void (^)(NSString *match, NSRange matchRange, BOOL *stop))block;

/// Get a string where internal characters that need escaping for HTML are escaped
///
///  For example, '&' become '&amp;'. This will only cover characters from table
///  A.2.2 of http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters
///  which is what you want for a unicode encoded webpage. If you have a ascii
///  or non-encoded webpage, please use stringByEscapingAsciiHTML which will
///  encode all characters.
///
/// For obvious reasons this call is only safe once.
///
///  Returns:
///    Autoreleased NSString
- (NSString *)gtm_stringByEscapingForHTML;

/// Get a string where internal characters that need escaping for HTML are escaped
///
///  For example, '&' become '&amp;'
///  All non-mapped characters (unicode that don't have a &keyword; mapping)
///  will be converted to the appropriate &#xxx; value. If your webpage is
///  unicode encoded (UTF16 or UTF8) use stringByEscapingHTML instead as it is
///  faster, and produces less bloated and more readable HTML (as long as you
///  are using a unicode compliant HTML reader).
///
/// For obvious reasons this call is only safe once.
///
///  Returns:
///    Autoreleased NSString
- (NSString *)gtm_stringByEscapingForAsciiHTML;

/// Get a string where internal characters that are escaped for HTML are unescaped
///
///  For example, '&amp;' becomes '&'
///  Handles &#32; and &#x32; cases as well
///
///  Returns:
///    Autoreleased NSString
- (NSString *)gtm_stringByUnescapingFromHTML;


@end

NS_ASSUME_NONNULL_END
