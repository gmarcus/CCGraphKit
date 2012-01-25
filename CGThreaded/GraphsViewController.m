//
//  GraphsViewController.m
//  CatchPhrase
//
//  Created by Glenn Marcus on 6/22/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GraphsViewController.h"
#import "GraphViewController.h"
#import "GraphView.h"
#import "AppDelegate.h"

static NSUInteger kNumberOfPages = 3;

static NSArray *dateRangeOptions = nil;
static NSArray *graphTitles = nil;
static NSArray *graphTitlesForLogging = nil;

@interface GraphsViewController()
- (void)loadScrollViewWithPage:(int)page;
- (void)scrollViewDidScroll:(UIScrollView *)sender;
- (void)calculateGraphData;

@end


@implementation GraphsViewController

@synthesize scrollView;
@synthesize pageControl;
@synthesize rangeButton;
@synthesize dateRangePicker;
@synthesize viewControllers;
@synthesize caughtPhrases = _caughtPhrases;


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"caughtPhrases"])
    {
        _graphDataIsStale = YES;
        return;
    }

    // be sure to call the super implementation
    // if the superclass implements it
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}


// If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad
{
    // Initialization code
    self.title = @"Graphs";
    
    self.caughtPhrases = [NSMutableArray array];
//    [self refreshAction:nil];
    
    // initialize some statics
    dateRangeOptions = [NSArray arrayWithObjects:@"Today", @"Past Week", @"Past Month", @"All Time", nil];
    graphTitles = [NSArray arrayWithObjects:@"Moods", @"Mood Totals", @"Activity", nil];   // 0=Moods, 1=Mood Totals, 2=Activity
    graphTitlesForLogging = [NSArray arrayWithObjects:@"ViewMoods", @"ViewMoodTotals", @"ViewActivity", nil];   // 0=Moods, 1=Mood Totals, 2=Activity
    
    // set the object properties
    currentDateRangeOption = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentDateRange"];   // 0=Today, 1=PastWeek, 2=Past Month, 3=All Time
    moodPieDataset = nil;
    moodBarDataset = nil;
    activityLineDataset = nil;
    _graphDataIsStale = YES;
    
    // register as an observer of CatchPhraseAppDelegate.caughtPhrases so we can mark the graph data as stale
    //        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //        [appDelegate addObserver:self forKeyPath:@"caughtPhrases" options:NSKeyValueObservingOptionOld context:nil];
    //        appDelegate = nil;
    
    // create a custom navigation bar button and set the date range by default
    NSString *dateRangeText = [dateRangeOptions objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"currentDateRange"]];
    self.rangeButton.title = dateRangeText;

    // create the date range picker
    dateRangePicker = [[UIActionSheet alloc] initWithTitle:@"Please select a date range."
                                                  delegate:self 
                                         cancelButtonTitle:nil
                                    destructiveButtonTitle:nil 
                                         otherButtonTitles:nil ];
    for (NSString *dateRangeOption in dateRangeOptions)
    {
        [dateRangePicker addButtonWithTitle:dateRangeOption];
    }
    [dateRangePicker addButtonWithTitle:@"Cancel"];
    dateRangePicker.cancelButtonIndex = dateRangeOptions.count;
    dateRangePicker.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    
    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < kNumberOfPages; i++) {
        [controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    
    // a page is the width of the scroll view
    scrollView.pagingEnabled = YES;
//    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * kNumberOfPages, scrollView.frame.size.height);
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * kNumberOfPages, scrollView.frame.size.height - 100.0f );
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = NO;
    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.delegate = self;
    
    pageControl.numberOfPages = kNumberOfPages;
    int page = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentGraphPosition"];
    pageControl.currentPage = page;
    
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
//    [self loadScrollViewWithPage:page - 1];
//    [self loadScrollViewWithPage:page];
//    [self loadScrollViewWithPage:page + 1];
    [self loadScrollViewWithPage:CPGraphMoods];
    [self loadScrollViewWithPage:CPGraphMoodTotals];
    [self loadScrollViewWithPage:CPGraphActivity];
    
    // scroll to the current page
    _currentPage = page;
    [self switchToPage:page];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self calculateGraphData];
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)viewDidDisappear:(BOOL)animated
{
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)loadScrollViewWithPage:(int)page {
    if (page < 0) return;
    if (page >= kNumberOfPages) return;
    
    // replace the placeholder if necessary
    UIViewController *controller = [viewControllers objectAtIndex:page];
    if (![controller isKindOfClass:[GraphViewController class]]) 
    {
        controller = [[GraphViewController alloc] initWithGraphType:page dateRangeOption:currentDateRangeOption];
        [viewControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    // add the controller's view to the scroll view
    if (nil == controller.view.superview) {
        CGRect frame = scrollView.frame;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        [scrollView addSubview:controller.view];
    }
}

- (IBAction)refreshAction:(id)sender;
{
    // Insert sample phrases into Phrases table
    NSArray *samplePhrases = [NSArray arrayWithObjects:
                              @"This damn computer!",
                              @"Woohoo!",
                              @"You never call.",
                              @"Now that's cool.",
                              @"Just one more...",
                              @"You're the best.",
                              @"Who's on the phone?",
                              @"Yummy.",
                              @"I need to go to the gym.",
                              @"I hate my job.",
                              nil];
    NSArray *samplePhraseMoods = [NSArray arrayWithObjects:
                                  @"Angry",
                                  @"Excited",
                                  @"Annoyed",
                                  @"Excited",
                                  @"Guilty",
                                  @"Loving",
                                  @"Jealous",
                                  @"Happy",
                                  @"Sad",
                                  @"Stressed",
                                  nil];

// a seconds * b minutes * c hours * d days * e weeks
//#define NUMBER_OF_CATCHES 80
//#define MAXHISTORY 60*60*24*7*8;
#define NUMBER_OF_CATCHES 1000
#define MAXHISTORY 60*60*24*7*20;
    // Create random catches
    srandom(time(NULL));
    for (int caughtCount=0; caughtCount < NUMBER_OF_CATCHES; caughtCount++)    
    {
        int maxHistory = MAXHISTORY;
        double past = random() % maxHistory;
        NSDate *randomDate = [NSDate dateWithTimeIntervalSinceNow:-past];
        
        int randomPhrase = random() % samplePhrases.count;
        CaughtPhrase *catchPhrase = [[CaughtPhrase alloc] init];
        catchPhrase.text = [samplePhrases objectAtIndex:randomPhrase];
        catchPhrase.mood = [samplePhraseMoods objectAtIndex:randomPhrase];
        catchPhrase.tsCaught = randomDate;
        catchPhrase.tz = 0;
        
        [self.caughtPhrases addObject:catchPhrase];
    }

    _graphDataIsStale = YES;
    [self performSelector:@selector(calculateGraphData) withObject:nil afterDelay:0.0f];

    for (UIViewController *vc in self.viewControllers)
        [vc.view setNeedsDisplay];
}


// 
// Should only be called once, to initialize the GraphViewController to a specific page
//
- (void)switchToPage:(int)page
{
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:NO];
    self.navigationItem.title = [graphTitles objectAtIndex:page];
    _currentPage = page;
}


- (void)currentPageUpdated:(int)newPage
{
    if (_currentPage == newPage)
        return;     // nothing to update
    
    _currentPage = pageControl.currentPage;
    
    [[NSUserDefaults standardUserDefaults] setInteger:_currentPage forKey:@"currentGraphPosition"];     // remember what page we are on
}


#pragma mark UIScrollView delegates

//
//  User changes the page by scrolling the scroll view
//
- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = page;
    self.navigationItem.title = [graphTitles objectAtIndex:page];
    
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];

    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// Invoked when done scrolling by touch
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self currentPageUpdated:pageControl.currentPage];
}

// Invoked when done scrolling by tapping on the page control
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self currentPageUpdated:pageControl.currentPage];
}

#pragma mark actions

//
//  User changes the page by tapping the page control
//
- (IBAction)changePage:(id)sender {
    int page = pageControl.currentPage;
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    // update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];

}

- (IBAction)changeRangeAction:(id)sender
{
    // raise an alert sheet to query user for a new date range
    [dateRangePicker showInView:[[UIApplication sharedApplication] keyWindow]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == dateRangeOptions.count)  // Cancel is the last button
        return; // do nothing
    
    if (buttonIndex == currentDateRangeOption)  // The user did not make a new selection
        return; // do nothing
    
    // record the user choice
    currentDateRangeOption = buttonIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:buttonIndex forKey:@"currentDateRange"];  // and store it as a user default
    
    // update the navigation bar to reflect the user choice
    NSString *dateRangeText = [dateRangeOptions objectAtIndex:buttonIndex];
    self.rangeButton.title = dateRangeText;
    
    _graphDataIsStale = YES;
    [self performSelector:@selector(calculateGraphData) withObject:nil afterDelay:0.0f];
}


- (void)calculateGraphData
{
    if (_graphDataIsStale == NO)
        return;     // nothing to do

    // A heavy calculation...show the activity HUD
//    AFDebug(@"GraphsViewController-calculateGraphData | showActivityHUD");
//    [appDelegate showActivityWithText:@"Generating..."];

    // Need to sort the array since the only time xPhrases gets sorted is if Caught Tab is visited
    // TODO: move this sorting into a ModelManager class and remove from viewWillAppear from PhraseDetailsViewController and CaughtViewController
    NSSortDescriptor *aSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"tsCaught"
                                                                    ascending:NO ];
    [self.caughtPhrases sortUsingDescriptors:[NSArray arrayWithObject:aSortDescriptor]];
    
    //
    // Determine lastReportingDate
    //
    NSDate *lastReportingDate = nil;
    NSDateComponents *rangeComps = [[NSDateComponents alloc] init];

    // get the start of today
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:[NSDate date]];
    NSDate *today= [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    switch (currentDateRangeOption) {
        case 0:     // Today
            lastReportingDate = today;
            break;
        case 1:     // Past Week
            [rangeComps setDay: -7];
            lastReportingDate = [[NSCalendar currentCalendar] dateByAddingComponents:rangeComps toDate:today options:0];
            break;
        case 2:     // Past Month
            [rangeComps setMonth: -1];
            lastReportingDate = [[NSCalendar currentCalendar] dateByAddingComponents:rangeComps toDate:today options:0];
            break;
        case 3:     // All Time
            if (self.caughtPhrases.count > 0)
            {
                CaughtPhrase *oldestDate = (CaughtPhrase*)[self.caughtPhrases lastObject];
                comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:oldestDate.tsCaught];
                lastReportingDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
            }
            else
            {
                lastReportingDate = [NSDate date];
            }
            break;
        default:
            lastReportingDate = [NSDate date];
            break;
    }
    
    
    //
    // Collect mood and phrase counts within the date range
    //
    NSMutableDictionary *moodCounts = [[NSMutableDictionary alloc] initWithCapacity:12];
    NSMutableDictionary *phraseCounts = [[NSMutableDictionary alloc] initWithCapacity:12];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle: kCFDateFormatterShortStyle];
    for (CaughtPhrase *caughtIter in self.caughtPhrases)
    {
        if ([caughtIter.tsCaught compare:lastReportingDate] == NSOrderedAscending)
            break;      // there are no more caught phrases in the specified date range

        // count moods
        int moodCount = 1;
        NSNumber *currentMoodCount = [moodCounts objectForKey:caughtIter.mood];
        if (currentMoodCount != nil)
            moodCount = moodCount + [currentMoodCount intValue];
        [moodCounts setObject:[NSNumber numberWithInt:moodCount] forKey:caughtIter.mood];

        // count phrases by day
        NSString *dayText = [df stringFromDate:caughtIter.tsCaught];
        int phraseCount = 1;
        NSNumber *currentPhraseCount = [phraseCounts objectForKey:dayText];
        if (currentPhraseCount != nil)
            phraseCount = phraseCount + [currentPhraseCount intValue];
        [phraseCounts setObject:[NSNumber numberWithInt:phraseCount] forKey:dayText];
    }

    //
    // Generate the 3 datasets for the graphs
    //
    
    // Generate the mood bar dataset (a descending array of mood labels and count)
    moodBarDataset = [[NSMutableArray alloc] initWithCapacity:moodCounts.count];
    NSArray *moodBarLabels = [moodCounts keysSortedByValueUsingSelector:@selector(compare:)];
    NSEnumerator *enumerator = [moodBarLabels reverseObjectEnumerator];     // walk the array backwards
    for (NSString *moodLabel in enumerator) 
    {
        NSMutableDictionary *anElement = [NSMutableDictionary dictionaryWithObjectsAndKeys: moodLabel, @"label",
                                           [moodCounts objectForKey:moodLabel], @"yvalue",
                                           nil];
        [moodBarDataset addObject:anElement];
    }

    // Generate the mood pie dataset (an array of mood labels and count, alternating between large and small counts)
    moodPieDataset = [[NSMutableArray alloc] initWithCapacity:moodCounts.count];
    NSArray *moodPieLabels = [moodCounts keysSortedByValueUsingSelector:@selector(compare:)];
    enumerator = [moodPieLabels reverseObjectEnumerator];     // walk the array backwards

    int start = 0;
    int end = moodPieLabels.count - 1;
    bool toggle = FALSE;
    int distributor = start;
    int startOffset = 0;
    int endOffset = 0;
    for (int d = start; d <= end; d++)
    {
        NSString *moodPieLabel = [moodPieLabels objectAtIndex:distributor];
        NSMutableDictionary *anElement = [NSMutableDictionary dictionaryWithObjectsAndKeys: moodPieLabel, @"label",
                                                                        [moodCounts objectForKey:moodPieLabel], @"yvalue",
                                                                        nil];
        [moodPieDataset addObject:anElement];
        
        distributor = toggle ? (start + startOffset) : (end - endOffset);
        
        if (startOffset <= endOffset)
            startOffset = startOffset + 1;
        else
            endOffset = endOffset + 1;
        
        toggle = !toggle;
        
    } 
    
    // Generate the activity line dataset (an array of dates and counts)
    activityLineDataset = [[NSMutableArray alloc] initWithCapacity:30];     // TODO: change to the number of days
    NSDate *firstReportingDate = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit
                                                                   fromDate:lastReportingDate
                                                                     toDate:firstReportingDate 
                                                                    options:0];
    int numDays = [components day];
    NSDateFormatter *activityLabelFormatter = [[NSDateFormatter alloc] init];
    [activityLabelFormatter setDateFormat:@"M/d"];
    NSDateFormatter *phraseCountLookupFormatter = [[NSDateFormatter alloc] init];
    [phraseCountLookupFormatter setDateStyle: kCFDateFormatterShortStyle];
    NSDateComponents *nextDayComps = [[NSDateComponents alloc] init];
    [nextDayComps setDay:1];
    for (int day = 0; day <= numDays; day++)
    {
        NSString *activityLabel = [activityLabelFormatter stringFromDate:lastReportingDate];
        NSString *phraseCountLookup = [phraseCountLookupFormatter stringFromDate:lastReportingDate];
        
        NSNumber *phraseCount = [phraseCounts objectForKey:phraseCountLookup];
        if (phraseCount == nil)
        {
            phraseCount = [NSNumber numberWithInt:0];
        }
        NSMutableDictionary *anElement = [NSMutableDictionary dictionaryWithObjectsAndKeys: activityLabel, @"label",
                                           phraseCount, @"yvalue",
                                           nil];
        [activityLineDataset addObject:anElement];
        
        lastReportingDate = [[NSCalendar currentCalendar] dateByAddingComponents:nextDayComps toDate:lastReportingDate  options:0];
    }

    
    GraphViewController *graphVC;

    graphVC = (GraphViewController *)[viewControllers objectAtIndex:CPGraphMoods];
    if ([graphVC isKindOfClass:[NSNull class]] == NO)
    {
        [graphVC.graphView setDataset:moodPieDataset];
    }

    graphVC = (GraphViewController *)[viewControllers objectAtIndex:CPGraphMoodTotals];
    if ([graphVC isKindOfClass:[NSNull class]] == NO)
    {   
        [graphVC.graphView setDataset:moodBarDataset];
    }

    graphVC = (GraphViewController *)[viewControllers objectAtIndex:CPGraphActivity];
    if ([graphVC isKindOfClass:[NSNull class]] == NO)
    {    
        [graphVC.graphView setDataset:activityLineDataset];
    }

//    for (UIViewController *vc in self.viewControllers)
//        [vc.view setNeedsDisplay];

    _graphDataIsStale = NO;
}

@end
