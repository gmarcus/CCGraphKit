//
//  GraphView.m
//  CatchPhrase
//
//  Created by Glenn Marcus on 7/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GraphView.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "AFDefines.h"



@interface GraphView() 
- (void)evaluateDataset;    // runs on background thread
- (void)prepareGraphImage;  // runs on background thread
- (void)refreshImage;       // runs on main thread

- (void)drawBackground:(CGContextRef)context rect:(CGRect)rect;
- (void)drawLabel:(CGContextRef)context rect:(CGRect)rect text:(NSString*)text fontName:(NSString*)fontName fontSize:(CGFloat)fontSize textAlignment:(CTTextAlignment)textAlignment textColor:(UIColor*)textColor;

- (void)drawUpdating:(CGContextRef)context rect:(CGRect)rect;
- (void)drawNoActivity:(CGContextRef)context rect:(CGRect)rect;
- (void)drawSingleActivity:(CGContextRef)context rect:(CGRect)rect;
- (void)drawPieGraph:(CGContextRef)context rect:(CGRect)rect;
- (void)drawBarGraph:(CGContextRef)context rect:(CGRect)rect;
- (void)drawLineGraph:(CGContextRef)context rect:(CGRect)rect;
@end

@implementation GraphView

@synthesize destImage;

- (id)initWithGraphStyle:(CPGraphStyle)aGraphStyle
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        theGraphStyle = aGraphStyle;
        dataset = nil; 
        _datasetIsNew = NO;
        uniqueYValues = nil;
        destLayer = NULL;
    }
    return self;
}

- (void)dealloc {
    CGLayerRelease(destLayer);
}

- (void)setDataset:(NSArray*)newDataset
{
    dataset = newDataset;
    _datasetIsNew = YES;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    // Create a layer once to reuse it
    if (destLayer == NULL)
    {
        CGFloat contentScale = [[UIScreen mainScreen] scale];
        CGSize layerSize = CGSizeMake(self.bounds.size.width * contentScale, self.bounds.size.height * contentScale);
        destLayer = CGLayerCreateWithContext(UIGraphicsGetCurrentContext(), layerSize, NULL);
        destContext = CGLayerGetContext(destLayer);
        if (destContext == NULL)
            AFDebug(@"destContext is NULL");
        // Set the scale
        CGContextScaleCTM(destContext, contentScale, contentScale);
    }
    
    if (_datasetIsNew)
    {
        [self drawBackground:UIGraphicsGetCurrentContext() rect:rect];
        [self drawUpdating:UIGraphicsGetCurrentContext() rect:rect];
        
        [self performSelectorInBackground:@selector(evaluateDataset) withObject:nil];
    }
    else
    {
        CGContextDrawLayerInRect(UIGraphicsGetCurrentContext(), rect, destLayer);
    }
}

- (void)refreshImage;
{
    [self setNeedsDisplay];
}

- (void)evaluateDataset;     // runs on a background thread
{
    @autoreleasepool {
        if (_datasetIsNew)
        {
            minXValue = 0.0;
            maxXValue = 0.0;
            numOfXValues = 0.0;
            
            //    minYValue = INFINITY;
            minYValue = 0.0;
            maxYValue = 0.0;
            numOfYValues = 0.0;
            sumOfYValues = 0.0;
            
            NSMutableDictionary* buckets = [[NSMutableDictionary alloc] initWithCapacity:dataset.count];
            
            for (NSDictionary *dataitem in dataset)
            {
                NSNumber *currentYNumber = [dataitem objectForKey:@"yvalue"];
                float currentYValue = [currentYNumber floatValue];
                
                maxXValue++;    // for now, xValues are labels, so all we need to do it count them to get the max
                numOfXValues++;
                
                if ( currentYValue < minYValue )
                {
                    minYValue = currentYValue;
                }
                
                if ( currentYValue > maxYValue )
                {
                    maxYValue = currentYValue;
                }
                
                numOfYValues++;
                
                sumOfYValues = sumOfYValues + currentYValue;
                
                if ([buckets objectForKey:[currentYNumber stringValue]] == nil)
                    [buckets setObject:currentYNumber forKey:[currentYNumber stringValue]];
                
            }
            
            uniqueYValues = [[buckets allValues] sortedArrayUsingSelector:@selector(compare:)];
            
            [self prepareGraphImage];
        }
    }
}

- (void)prepareGraphImage;  // runs on background thread
{
    @autoreleasepool {
        CGRect rect = self.bounds;

        // Start drawing into destination context
        [self drawBackground:destContext rect:rect];
        
        if ( (dataset.count == 0) || (maxYValue == 0) )
        {
            [self drawNoActivity:destContext rect:rect];
        }
        else
        {
            //
            // Draw the graph of a certain type
            //
            if (theGraphStyle == CPGraphStylePie)
            {
                [self drawPieGraph:destContext rect:rect];
            }
            
            if (theGraphStyle == CPGraphStyleBar)
            {
                [self drawBarGraph:destContext rect:rect];
            }
            
            if (theGraphStyle == CPGraphStyleLine)
            {
                if (dataset.count == 1)
                {
                    [self drawSingleActivity:destContext rect:rect];
                }
                else
                {
                    [self drawLineGraph:destContext rect:rect];
                }
                
            }
        }
        
    }

    _datasetIsNew = NO;

    [self performSelectorOnMainThread:@selector(refreshImage) withObject:nil waitUntilDone:NO];
    
}

#pragma -
#pragma Graph Primatives
#pragma -
- (void)drawBackground:(CGContextRef)context rect:(CGRect)rect;
{

    //
    // Draw the background gradient
    //
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGFloat colors[] =
    {
        29.0 / 255.0, 156.0 / 255.0, 215.0 / 255.0, 1.00,   // start color
        0.0 / 255.0,  50.0 / 255.0, 126.0 / 255.0, 1.00,    // end color
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, 2);
    CGColorSpaceRelease(rgb);
    
	// Clip to area to draw the gradient, and draw it. Since we are clipping, we save the graphics state
	// so that we can revert to the previous larger area.
	CGContextSaveGState(context);
	CGContextClipToRect(context, rect);
	
	// A linear gradient requires only a starting & ending point.
	// The colors of the gradient are linearly interpolated along the line segment connecting these two points
	// A gradient location of 0.0 means that color is expressed fully at the 'start' point
	// a location of 1.0 means that color is expressed fully at the 'end' point.
	// The gradient fills outwards perpendicular to the line segment connectiong start & end points
	// (which is why we need to clip the context, or the gradient would fill beyond where we want it to).
	// The gradient options (last) parameter determines what how to fill the clip area that is "before" and "after"
	// the line segment connecting start & end.
	CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
	CGPoint end = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
	CGContextDrawLinearGradient(context, gradient, start, end, 0);
	CGContextRestoreGState(context);

    // cleanup
    CGGradientRelease(gradient);
}


- (void) drawLabel:(CGContextRef)context rect:(CGRect)rect text:(NSString*)text fontName:(NSString*)fontName fontSize:(CGFloat)fontSize textAlignment:(CTTextAlignment)textAlignment textColor:(UIColor*)textColor;
{
	CGContextSaveGState(context);

    NSString *longText = text;
    
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
                                         initWithString:longText];
    
	// make a few words bold
	CTFontRef font = CTFontCreateWithName((__bridge CFStringRef) fontName, fontSize, NULL);
    
    // Align text
    //Setup paragraph Alignment Ref
    CTTextAlignment theAlignment = textAlignment;
    CFIndex theNumberOfSettings = 1;
    CTParagraphStyleSetting theSettings[1] = {{ kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &theAlignment }};
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, theNumberOfSettings);
    
    [string addAttribute:(id)kCTParagraphStyleAttributeName
                   value:(__bridge id)theParagraphRef 
                   range:NSMakeRange(0, [string length])];
    
    
    // Set the font
	[string addAttribute:(id)kCTFontAttributeName
                   value:(__bridge id)font
                   range:NSMakeRange(0, [string length])];
    
	// add some color
	[string addAttribute:(id)kCTForegroundColorAttributeName
                   value:(id)textColor.CGColor
                   range:NSMakeRange(0, [string length])];
    
	// layout master
	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(
                                                                           (__bridge CFAttributedStringRef)string);
    
	// left column form
	CGMutablePathRef leftColumnPath = CGPathCreateMutable();
    
	CGPathAddRect(leftColumnPath, NULL, 
                  CGRectMake(self.bounds.origin.x + rect.origin.x, 
                             self.bounds.size.height - rect.origin.y - rect.size.height,    // need to invert y and include label height
                             rect.size.width, 
                             rect.size.height));
    
	// left column frame
	CTFrameRef leftFrame = CTFramesetterCreateFrame(framesetter, 
                                                    CFRangeMake(0, 0),
                                                    leftColumnPath, NULL);
    
    
	// flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
    
	// draw
	CTFrameDraw(leftFrame, context);
    
	// cleanup
    CFRelease(font);
    CFRelease(theParagraphRef);
	CFRelease(leftFrame);
	CGPathRelease(leftColumnPath);
	CFRelease(framesetter);
    
    CGContextRestoreGState(context);
}

#pragma -
#pragma Graph States
#pragma -
- (void)drawUpdating:(CGContextRef)context rect:(CGRect)rect;
{
	CGContextSaveGState(context);

    [self drawLabel:context rect:CGRectMake(0.0f, 30.0f, rect.size.width, 80.0f) text:@"Updating" fontName:@"Arial" fontSize:60.0f textAlignment:kCTCenterTextAlignment textColor:[UIColor whiteColor]];

	CGContextRestoreGState(context);
}


- (void)drawNoActivity:(CGContextRef)context rect:(CGRect)rect;
{
	CGContextSaveGState(context);

    [self drawLabel:context rect:CGRectMake(0, 30, rect.size.width, 80.0) text:@"No Activity" fontName:@"Arial" fontSize:60.0f textAlignment:kCTCenterTextAlignment textColor:[UIColor whiteColor]];

    [self drawLabel:context rect:CGRectMake(50.0f, 130.0f, rect.size.width - 100.0f, rect.size.height - 130.0f) text:@"Go catch some phrases" fontName:@"Arial" fontSize:30.0f textAlignment:kCTCenterTextAlignment textColor:[UIColor colorWithRed:0.75f green:0.75f blue:0.75f alpha:1.0f]];

	CGContextRestoreGState(context);
}

- (void)drawSingleActivity:(CGContextRef)context rect:(CGRect)rect;
{
	CGContextSaveGState(context);
    
    NSNumber *count = [(NSDictionary*)[dataset objectAtIndex:0] objectForKey:@"yvalue"];
    NSString *titleText = [count stringValue];
    [self drawLabel:context rect:CGRectMake(0.0f, 60.0f, rect.size.width, 80.0f) text:titleText fontName:@"Arial" fontSize:60.0f textAlignment:kCTCenterTextAlignment textColor:[UIColor whiteColor]];
    
    [self drawLabel:context rect:CGRectMake(50.0f, 130.0f, rect.size.width - 100.0f, rect.size.height - 130.0f) text:@"Caught" fontName:@"Arial" fontSize:30.0f textAlignment:kCTCenterTextAlignment textColor:[UIColor colorWithRed:0.75f green:0.75f blue:0.75f alpha:1.0f]];
    
	CGContextRestoreGState(context);
}



//
// PIE GRAPH
//
- (void)drawPieGraph:(CGContextRef)context rect:(CGRect)rect;
{
    CGContextSaveGState(context);

    int count = dataset.count;
    float total = sumOfYValues;
    
    float maxEdgeLength = rect.size.width - 120;
    CGRect pieRect = CGRectMake( 60,
                                rect.origin.y + ((rect.size.height - maxEdgeLength) / 2.0f),
                                maxEdgeLength, 
                                maxEdgeLength);
    CGPoint center = CGPointMake(CGRectGetMidX(pieRect), CGRectGetMidY(pieRect));
    float radius = CGRectGetWidth(pieRect) / 2.0;

    // Setup drawing defaults
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(context, 2.0);
    
    //
    // Draw a shadow
    //
    CGContextSaveGState(context);
    CGSize  myShadowOffset = CGSizeMake (15,  -20);  // shadows
    CGContextSetShadow (context, myShadowOffset, 50);  // shadows
    // Add an ellipse circumscribed in the given rect to the current path, then stroke it
    CGContextAddEllipseInRect(context, pieRect);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextRestoreGState(context);  // shadows

    //
    // Draw the slices
    //
    float currentAngle = 0.0;
    for (int i=0; i<count; i++)
    {
        //
        // calculate start and end angles
        //
        NSDictionary *dataitem = [dataset objectAtIndex:i];
        float value = [(NSNumber*)[dataitem objectForKey:@"yvalue"] floatValue];
        float fraction =  value / total;
        float startAngle = currentAngle * M_PI * 2.0;
        float endAngle = (currentAngle + fraction) * M_PI * 2.0;
        float middleAngle = ( startAngle + endAngle ) / 2.0;
        
        //
        // DRAW A SLICE
        //
        // And draw with a progressing red tint
        float colorPercent = (100.0 / (float)(count + 2)) / 100.0;
        CGContextSetRGBFillColor(context, 1.0 - (colorPercent * i), 0.0, 0.0, 1.0);
        // Signal the start of a path
        CGContextBeginPath(context);
        if (count == 1)
        {
            // Draw a full circle with no inner lines
            CGContextAddArc(context, center.x, center.y, radius, startAngle - M_PI*0.5, endAngle - M_PI*0.5, false);
        }
        else
        {
            // Draw a slice with inner lines
            CGContextMoveToPoint(context, center.x, center.y);
            CGContextAddArc(context, center.x, center.y, radius, startAngle - M_PI*0.5, endAngle - M_PI*0.5, false);
        }
        // Complete the path closing the arc at the focal point
        CGContextClosePath(context);
        // Fill the path
        CGContextDrawPath(context, kCGPathFillStroke);
        
        //
        // ADD THE LABEL
        //
        float labelRadius = radius + 30;
        float normalizedAngle = middleAngle;
        if (normalizedAngle > M_PI*2) {
            normalizedAngle = normalizedAngle - M_PI*2;
        }
        else {
            if (normalizedAngle < 0) {
                normalizedAngle = normalizedAngle + M_PI*2;
            }
        }
        CGFloat labelX = center.x + sin(normalizedAngle) * labelRadius;
        CGFloat labelY = center.y - cos(normalizedAngle) * labelRadius;
        CGPoint labelPoint = CGPointMake(labelX, labelY);

        NSString *labelText = [dataitem objectForKey:@"label"];
        CGRect labelRect = CGRectMake(labelPoint.x-30.0, labelPoint.y - 16.0, 60.0, 16.0);
        NSString *percentText = [[NSString alloc] initWithFormat:@"%d%%", (int)round((fraction * 100))];
        CGRect percentRect = CGRectMake(labelPoint.x - 30.0, labelPoint.y, 60.0, 12.0);
        
        [self drawLabel:context rect:labelRect text:labelText fontName:@"Helvetica-Bold" fontSize:12.0f textAlignment:kCTCenterTextAlignment textColor:[UIColor whiteColor]];
        [self drawLabel:context rect:percentRect text:percentText fontName:@"Helvetica" fontSize:10.0f textAlignment:kCTCenterTextAlignment textColor:[UIColor whiteColor]];
        
        //
        // move to next position
        //
        currentAngle = currentAngle + fraction;
    }

    //
    // Draw an anchor if there are more than 2 segments
    //
    if (count > 2)
    {
        // Drawing an inner circle with white stroke and red center
        CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
        CGContextSetLineWidth(context, 2.0);
        CGContextSetRGBFillColor (context, 1.0, 0.0, 0.0, 1.0);   // draw labels white
        // Add an ellipse circumscribed in the given rect to the current path, then stroke it
        CGRect anchorRect = CGRectMake(center.x - 6.0, center.y - 6.0, 12.0, 12.0);
        CGContextAddEllipseInRect(context, anchorRect);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
}



//
// BAR GRAPH
//
- (void)drawBarGraph:(CGContextRef)context rect:(CGRect)rect;
{
    CGContextSaveGState(context);
    
    const int leftPadding = 15;
    const int rightPadding = 15;
    const int topPadding = 20;
    const int bottomPadding = 30;
    const float barWidthFillFraction = 0.75;
    
    CGRect barChartRect = CGRectMake(CGRectGetMinX(rect) + leftPadding, 
                                     CGRectGetMinY(rect) + topPadding, 
                                     CGRectGetWidth(rect) - leftPadding - rightPadding, 
                                     CGRectGetHeight(rect) - topPadding - bottomPadding);
    
    // Default drawing context
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);    // White lines
    CGContextSetLineWidth(context, 2.0);                        // Thick line width
    CGContextSetRGBFillColor (context, 1.0, 1.0, 1.0, 1);       // White fill

    //
    // Draw the axis
    //
    CGContextMoveToPoint(context, CGRectGetMinX(barChartRect), CGRectGetMinY(barChartRect));
    CGContextAddLineToPoint(context, CGRectGetMinX(barChartRect), CGRectGetHeight(barChartRect) + topPadding);
    CGContextAddLineToPoint(context, CGRectGetWidth(barChartRect) + leftPadding,  CGRectGetHeight(barChartRect) + topPadding);
    CGContextStrokePath(context);
    
    // calculate bar scales
    float xScale = 0.0;
    float yScale = 0.0;
    float barWidth = 0.0;
    float barMargin = 0.0;
    if (numOfXValues == 1)
    {
        xScale = 1.0;
        yScale = 1.0 / maxYValue;
        barWidth = 0.25;
        barMargin = 0.75 / 2.0;
    }
    
    if (numOfXValues >= 2)
    {
        xScale = 1.0 / numOfXValues;
        yScale = 1.0 / maxYValue;
        barWidth = xScale * barWidthFillFraction;
        barMargin = xScale * ((1.0 - barWidthFillFraction) / 2.0);
    }

    int j;
    CGRect *bars = (CGRect*) malloc(sizeof(CGRect) * numOfXValues);

    // Calculate Bar Rectangles
    for (j = 0; j < numOfXValues; j++) 
    {
        NSDictionary *dataitem = [dataset objectAtIndex:j];
        float value = [(NSNumber*)[dataitem objectForKey:@"yvalue"] floatValue];
        CGRect scaledBarRect = CGRectMake(0.0,                          // x
                                          j*xScale + barMargin,         // y
                                          value*yScale,                 // width
                                          barWidth);                    // height
        
        CGRect barRect = CGRectMake(CGRectGetWidth(barChartRect) * CGRectGetMinX(scaledBarRect) + CGRectGetMinX(barChartRect), 
                                    CGRectGetHeight(barChartRect) * CGRectGetMinY(scaledBarRect) + CGRectGetMinY(barChartRect), 
                                    CGRectGetWidth(barChartRect) * CGRectGetWidth(scaledBarRect), 
                                    CGRectGetHeight(barChartRect) * CGRectGetHeight(scaledBarRect));
        bars[j] = barRect;
    }
    

    //
    // Draw bars with a shadow
    //
    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGSize myShadowOffset = CGSizeMake (15,  -20);  // shadows
    CGContextSetShadow (context, myShadowOffset, 50);  // shadows
    CGContextSetRGBFillColor(context, 0.2, 0.7, 0.3, 1.0);  // green fill
    for (j = 0; j < numOfXValues; j++) 
    {
        CGRect barRect = bars[j];
        CGContextAddRect(context, barRect);
    }
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextRestoreGState(context);
    
    //
    // Draw labels inside the bars
    //
    for (j = 0; j < numOfXValues; j++) 
    {
        CGRect barRect = bars[j];

        NSDictionary *dataitem = [dataset objectAtIndex:j];
        NSString *labelText = [dataitem objectForKey:@"label"];
        CGRect labelRect = CGRectMake(CGRectGetMinX(barRect) + 5.0, 
                                      CGRectGetMinY(barRect) + (CGRectGetHeight(barRect)/2) - 7.0, 
                                      CGRectGetWidth(barChartRect) - CGRectGetMinX(barRect) - 5 + 5.0f, 
                                      14.0 + 2.0f);
        
        [self drawLabel:context rect:labelRect text:labelText fontName:@"Helvetica-Bold" fontSize:12.0f textAlignment:kCTLeftTextAlignment textColor:[UIColor whiteColor]];
    }
    
    //
    // Draw the ticks
    //
    int numOfUniqueYValues = uniqueYValues.count;
    
    float numOfTicks = 5.0;
    if (numOfUniqueYValues < 5)
        numOfTicks = numOfUniqueYValues;
    
    float tickScale = 1.0 / numOfTicks;
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setMaximumFractionDigits:1];
    
    for (int i=0; i< numOfTicks + 1; i++)
    {
        CGPoint scaledPoint = CGPointMake((i*tickScale),
                                          CGRectGetHeight(barChartRect) + topPadding);
        
        NSNumber *num = [NSNumber numberWithFloat:(i * (maxYValue / numOfTicks))];
        NSString *tickText = [nf stringFromNumber:num];
        CGRect tickRect = CGRectMake((CGRectGetWidth(barChartRect) * scaledPoint.x) - 30.0 + CGRectGetMinX(barChartRect), 
                                     scaledPoint.y + 7.0, 
                                     60.0, 
                                     14.0 + 2.0f);
        [self drawLabel:context rect:tickRect text:tickText fontName:@"Helvetica-Bold" fontSize:12.0f textAlignment:kCTLeftTextAlignment textColor:[UIColor whiteColor]];

    }
    
    CGContextRestoreGState(context);
    free(bars);
}






//
// LINE GRAPH
//
- (void)drawLineGraph:(CGContextRef)context rect:(CGRect)rect;
{
    const int leftPadding = 30;
    const int rightPadding = 30;
    const int topPadding = 20;
    const int bottomPadding = 30;
    
    // Default drawing context
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);    // White lines
    CGContextSetLineWidth(context, 2.0);                        // Thick line width
    CGContextSetRGBFillColor (context, 1.0, 1.0, 1.0, 1);       // White fill
    
    CGRect lineChartRect = CGRectMake(CGRectGetMinX(rect) + leftPadding, 
                                     CGRectGetMinY(rect) + topPadding, 
                                     CGRectGetWidth(rect) - leftPadding - rightPadding, 
                                     CGRectGetHeight(rect) - topPadding - bottomPadding);
    
    //
    // Draw the Y ticks
    //
    float numOfYTicks = 5.0;
    
    float tickScale = 1.0 / numOfYTicks;
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setMaximumFractionDigits:1];
    [nf setAlwaysShowsDecimalSeparator:NO];
    
    CGContextSaveGState(context);
    for (int i=1; i<= numOfYTicks; i++)     // start at 1 to skip the bottom label
    {
        CGPoint scaledPoint = CGPointMake(
                                          CGRectGetMinX(lineChartRect),
                                          i*tickScale);
        
        NSNumber *num = [NSNumber numberWithFloat:(i * (maxYValue / numOfYTicks))];
        NSString *ytickText = [nf stringFromNumber:num];
        CGRect ytickRect = CGRectMake(scaledPoint.x - leftPadding, 
                                      CGRectGetHeight(lineChartRect) * (1.0 - scaledPoint.y) + 12.0, 
                                      leftPadding - 5.0 + 2.0, 
                                      13.0 + 3.0f);
        [self drawLabel:context rect:ytickRect text:ytickText fontName:@"Helvetica-Bold" fontSize:13.0f textAlignment:kCTRightTextAlignment textColor:[UIColor whiteColor]];

        
        CGContextSetRGBStrokeColor(context, 0.7, 0.7, 0.7, 1.0);    // Grey lines
        CGContextSetLineWidth(context, 1.0);                        // Thin line width
        CGContextMoveToPoint(context, CGRectGetMinX(lineChartRect), CGRectGetHeight(lineChartRect) * (1.0 - scaledPoint.y) + topPadding);
        CGContextAddLineToPoint(context, CGRectGetWidth(lineChartRect) + leftPadding, CGRectGetHeight(lineChartRect) * (1.0 - scaledPoint.y) + topPadding);
        CGContextStrokePath(context);
    }
    CGContextRestoreGState(context);
    
    //
    // Draw the axis
    //
    CGContextMoveToPoint(context, CGRectGetMinX(lineChartRect), CGRectGetMinY(lineChartRect));
    CGContextAddLineToPoint(context, CGRectGetMinX(lineChartRect), CGRectGetHeight(lineChartRect) + topPadding);
    CGContextAddLineToPoint(context, CGRectGetWidth(lineChartRect) + leftPadding,  CGRectGetHeight(lineChartRect) + topPadding);
    CGContextStrokePath(context);
    
    float xScale = 1.0 / (maxXValue - 1);
    float yScale = 1.0 / maxYValue;
    
    //
    // RENDER CHART
    //
    int j;
    // Draw lines
    CGContextSaveGState(context);
    CGContextSetRGBFillColor(context, 215.0/255.0, 130.0/255.0, 29.0/255.0, 0.9);

    CGSize  myShadowOffset = CGSizeMake (15,  -20);  // shadows
    CGContextSetShadow (context, myShadowOffset, 50);  // shadows
    
    CGContextBeginPath(context);
    CGPoint startPoint = CGPointMake(CGRectGetMinX(lineChartRect), CGRectGetHeight(lineChartRect) + topPadding);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    for (j = 0; j < numOfXValues; j++) 
    {
        NSDictionary *dataitem = [dataset objectAtIndex:j];
        float value = [(NSNumber*)[dataitem objectForKey:@"yvalue"] floatValue];
        CGPoint scaledLinePoint = CGPointMake(j*xScale,       // x
                                              value*yScale);  // y
        
        //
        // Draw the bar
        //
        CGPoint linePoint = CGPointMake(CGRectGetWidth(lineChartRect) * scaledLinePoint.x + CGRectGetMinX(lineChartRect),              // x
                                        CGRectGetHeight(lineChartRect) * (1.0 - scaledLinePoint.y) + CGRectGetMinY(lineChartRect));    // y

        CGContextAddLineToPoint(context, linePoint.x, linePoint.y);
    }
    CGPoint endPoint = CGPointMake(CGRectGetWidth(lineChartRect) + leftPadding,  CGRectGetHeight(lineChartRect) + topPadding);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);

    CGContextRestoreGState(context);
    
    
    //
    // Draw the X ticks (date labels)
    //
    float numXTicks = 8.0;
    if (numOfXValues < 8.0)
        numXTicks = numOfXValues;
    float segments = numXTicks - 1.0;
    float xAxisScale = CGRectGetWidth(lineChartRect) / segments;
    float xDataScale = (numOfXValues-1) / segments;

    CGContextSaveGState(context);
    for (j=numXTicks-1; j>=0; j--)
    {
        int xDataIndex = round(j * xDataScale);
        NSDictionary *dataitem = [dataset objectAtIndex:xDataIndex];
        NSString *dateString = [dataitem objectForKey:@"label"];

        CGPoint xTickPoint = CGPointMake(j*xAxisScale + leftPadding, CGRectGetHeight(lineChartRect) + topPadding);

        // draw tick mark
        CGContextMoveToPoint(context,xTickPoint.x, xTickPoint.y + 1.0);
        CGContextAddLineToPoint(context, xTickPoint.x, xTickPoint.y + 5.0);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        // draw date text
        CGRect dateRect = CGRectMake(xTickPoint.x - 20.0, 
                                     xTickPoint.y + 5.0, 
                                     40.0, 
                                     14.0);
        [self drawLabel:context rect:dateRect text:dateString fontName:@"Helvetica-Bold" fontSize:11.0f textAlignment:kCTCenterTextAlignment textColor:[UIColor whiteColor]];

    }
    CGContextRestoreGState(context);
}


@end


