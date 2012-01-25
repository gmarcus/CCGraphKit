//
//  GraphViewController.m
//  CatchPhrase
//
//  Created by Glenn Marcus on 6/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GraphViewController.h"
#include "GraphView.h"

@implementation GraphViewController

@synthesize graphView;

- (id)initWithGraphType:(CPGraphType)aGraphType dateRangeOption:(CPDateRangeOption)aDateRangeOption;
{
    graphView = nil;
    theGraphType = aGraphType;
    theDateRange = aDateRangeOption;

    return self;
}

- (CPDateRangeOption)dateRangeOption
{
    return theDateRange;
}

- (void)setDateRangeOption:(CPDateRangeOption)aDateRangeOption
{
    theDateRange = aDateRangeOption;
}


// Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView 
{
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;

    // Create a graph view of the certain graph type
    switch (theGraphType) {
        case CPGraphMoods:
            graphView = [[GraphView alloc] initWithGraphStyle:CPGraphStylePie];
            break;
        case CPGraphMoodTotals:
            graphView = [[GraphView alloc] initWithGraphStyle:CPGraphStyleBar];
            break;
        case CPGraphActivity:
            graphView = [[GraphView alloc] initWithGraphStyle:CPGraphStyleLine];
            break;
        default:
            graphView = [[GraphView alloc] initWithGraphStyle:CPGraphStylePie];
            break;
    }
    
    graphView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth ;

    self.view = graphView;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}



@end
