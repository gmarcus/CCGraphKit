//
//  DetailViewController.h
//  CGThreaded
//
//  Created by Glenn Marcus on 1/22/12.
//  Copyright (c) 2012 CliqConsulting/SocialCliq/AppExtras. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
