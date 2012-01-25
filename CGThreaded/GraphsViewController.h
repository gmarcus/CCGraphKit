//
//  GraphsViewController.h
//  CatchPhrase
//
//  Created by Glenn Marcus on 6/22/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaughtPhrase.h"



@interface GraphsViewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate> {
    UIScrollView *scrollView;
    UIPageControl *pageControl;
    UIBarButtonItem *rangeButton;
    
    UIActionSheet *dateRangePicker;
    NSMutableArray *viewControllers;
    
    // UI Model
    int currentDateRangeOption;
    int _currentPage;

    // Model
    NSMutableArray *_caughtPhrases;
    NSMutableArray *moodPieDataset;
    NSMutableArray *moodBarDataset;
    NSMutableArray *activityLineDataset;
    bool _graphDataIsStale;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *rangeButton;
@property (nonatomic, retain) UIActionSheet *dateRangePicker;
@property (nonatomic, retain) NSMutableArray *viewControllers;
@property (nonatomic, retain) NSMutableArray *caughtPhrases;

- (IBAction)refreshAction:(id)sender;

- (void)switchToPage:(int)page;
- (IBAction)changePage:(id)sender;
- (IBAction)changeRangeAction:(id)sender;

- (void)currentPageUpdated:(int)newPage;



@end