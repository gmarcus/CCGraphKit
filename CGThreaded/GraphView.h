//
//  GraphView.h
//  CatchPhrase
//
//  Created by Glenn Marcus on 7/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    CPGraphStyleBar        = 0,       // the different types of graphs
    CPGraphStyleLine       = 1,
    CPGraphStylePie        = 2
} CPGraphStyle;



@interface GraphView : UIView 
{
    CPGraphStyle theGraphStyle;
    NSArray *dataset;
    bool _datasetIsNew;
    
    float minXValue;
    float maxXValue;
    float numOfXValues;

    float minYValue;
    float maxYValue;
    float numOfYValues;
    float sumOfYValues;
    NSArray *uniqueYValues;
    
    // the layer used to draw into
    CGLayerRef destLayer;
    
    // the temporary container used to hold the resulting output image pixel 
    // data, as it is being assembled.
    CGContextRef destContext;
}

// destImage property is specifically thread safe (i.e. no 'nonatomic' attribute) 
// because it is accessed off the main thread.
@property (retain) UIImage* destImage; 

- (id)initWithGraphStyle:(CPGraphStyle)aGraphStyle;    // initializes with frame as CGRectZero
- (void)setDataset:(NSArray*)newDataset;

@end
