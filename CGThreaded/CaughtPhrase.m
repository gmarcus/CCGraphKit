/*
 File: CaughtPhrase.m
 Abstract: 
 The CaughtPhrase class manages the in-memory representation of information about a
 single CaughtPhrase.  
 */

#import "CaughtPhrase.h"

@implementation CaughtPhrase

@synthesize text;
@synthesize mood;
@synthesize tsCaught;
@synthesize tz;
@synthesize tsPublished;

- (NSString *)description
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterShortStyle];
    [df setTimeStyle:NSDateFormatterShortStyle];
    
    NSString *returnString = [[NSString alloc] initWithFormat:@"text:%@, mood:%@, tsCaught:%@, tz:%@, tsPublished:%@", 
                              self.text, self.mood, [df stringFromDate:self.tsCaught], self.tz, [df stringFromDate:self.tsPublished]];
    
    return returnString;
}

@end


