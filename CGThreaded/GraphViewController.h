//
//  GraphViewController.h
//  CatchPhrase
//
//  Created by Glenn Marcus on 6/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphView;

typedef enum {
    CPGraphMoods        = 0,       // the different available of graphs
    CPGraphMoodTotals   = 1,
    CPGraphActivity     = 2
} CPGraphType;

typedef enum {
    CPDateRangeOptionToday      = 0,
    CPDateRangeOptionPastWeek   = 1,
    CPDateRangeOptionPastMonth  = 2,
    CPDateRangeOptionAllTime    = 3
} CPDateRangeOption;

    
    
@interface GraphViewController : UIViewController {
    GraphView *graphView;

    CPGraphType theGraphType;
    CPDateRangeOption theDateRange;
}

@property (nonatomic, retain) GraphView *graphView;

- (id)initWithGraphType:(CPGraphType)aGraphType dateRangeOption:(CPDateRangeOption)aDateRangeOption;

- (CPDateRangeOption)dateRangeOption;
- (void)setDateRangeOption:(CPDateRangeOption)aDateRangeOption;


@end