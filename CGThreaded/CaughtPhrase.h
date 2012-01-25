/*
 File: CaughtPhrase.h
 Abstract: 
 The CaughtPhrase class manages the in-memory representation of information about a
 single CaughtPhrase.  
 */

#import <Foundation/Foundation.h>

@interface CaughtPhrase : NSObject {
    // Attributes
    NSString *text;
    NSString *mood;
    NSDate *tsCaught;
    NSNumber *tz;
    NSDate *tsPublished;
}

// The remaining attributes are copied rather than retained because they are value objects.
@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSString *mood;
@property (copy, nonatomic) NSDate *tsCaught;
@property (copy, nonatomic) NSNumber *tz;
@property (copy, nonatomic) NSDate *tsPublished;

@end

