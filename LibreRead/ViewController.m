//
//  ViewController.m
//  LibreRead
//
//  Created by fishermen21 on 15.04.16.
//  Copyright © 2016 Softwarehaus Kassel GmbH. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController () <ChartViewDelegate,ChartXAxisValueFormatter>
@property (nonatomic,strong) NSMutableArray* xAxisValues;
@property (nonatomic,strong) NSDictionary* sensor;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    ((AppDelegate*)([[UIApplication sharedApplication] delegate])).view = self;

    _chartView.delegate = self;

    _chartView.descriptionText = @"";
    _chartView.noDataTextDescription = @"You need to provide data for the chart.";

    _chartView.backgroundColor = [UIColor clearColor];//[UIColor colorWithWhite:204/255.f alpha:1.f];

    _chartView.legend.form = ChartLegendFormLine;
    _chartView.legend.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:11.f];
    _chartView.legend.textColor = UIColor.blackColor;
    _chartView.legend.position = ChartLegendPositionBelowChartLeft;

    [_chartView setScaleEnabled:YES];
    _chartView.pinchZoomEnabled = YES;
    _chartView.dragEnabled = YES;

    [_chartView setHighlightPerTapEnabled:NO];
    [_chartView setHighlightPerDragEnabled:NO];

    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelFont = [UIFont systemFontOfSize:12.f];
    xAxis.labelTextColor = UIColor.blackColor;
    xAxis.drawGridLinesEnabled = NO;
    xAxis.drawAxisLineEnabled = NO;
    xAxis.spaceBetweenLabels = 1.0;

    ChartLimitLine *ll1 = [[ChartLimitLine alloc] initWithLimit:170.0 label:@"Hoch"];
    ll1.lineWidth = 2.0;
    ll1.lineColor = [UIColor redColor];
    ll1.lineDashLengths = @[@5.f, @5.f];
    ll1.labelPosition = ChartLimitLabelPositionRightTop;
    ll1.valueFont = [UIFont systemFontOfSize:10.0];
    ChartLimitLine *ll2 = [[ChartLimitLine alloc] initWithLimit:50.0 label:@"Tief"];
    ll2.lineWidth = 2.0;
    ll2.lineColor = [UIColor redColor];
    ll2.lineDashLengths = @[@5.f, @5.f];
    ll2.labelPosition = ChartLimitLabelPositionRightBottom;
    ll2.valueFont = [UIFont systemFontOfSize:10.0];

    ChartYAxis *leftAxis = _chartView.leftAxis;
    leftAxis.labelTextColor = UIColor.blackColor;//[UIColor colorWithRed:51/255.f green:181/255.f blue:229/255.f alpha:1.f];
    leftAxis.axisMaxValue = 450.0;
    leftAxis.axisMinValue = 0.0;
    leftAxis.drawGridLinesEnabled = YES;
    leftAxis.drawZeroLineEnabled = NO;
    leftAxis.granularityEnabled = YES;
    [leftAxis addLimitLine:ll1];
    [leftAxis addLimitLine:ll2];

    _chartView.rightAxis.enabled = NO;


    _xAxisValues = [NSMutableArray new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewDidAppear:(BOOL)animated
{
    ((AppDelegate*)([[UIApplication sharedApplication] delegate])).view = self;

    [self.statusLabel setNumberOfLines:0];
    [self.sensorLabel setNumberOfLines:0];

    self.statusLabel.text = @"suche blueReader…";
    self.sensorLabel.text = @"Warte auf Sensor…";
    NSData* archive = [[NSUserDefaults standardUserDefaults] objectForKey:@"sensors"];
    NSDictionary* inmutablesensors = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
    if(!inmutablesensors)
    {
        inmutablesensors = [NSDictionary new];
    }
    NSMutableDictionary* sensors = [NSMutableDictionary dictionaryWithDictionary:inmutablesensors];

    NSDictionary* lastRead = [sensors objectForKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"current_tag"]];

    [self updateGraph:lastRead];
}
- (NSString * _Nonnull)stringForXValue:(NSInteger)index original:(NSString * _Nonnull)original viewPortHandler:(ChartViewPortHandler * _Nonnull)viewPortHandler
{
    NSNumber* st = [_sensor objectForKey:@"sensor_time"];
    NSNumber* os = [_xAxisValues objectAtIndex:index];

    int minutes = [st intValue] - [os intValue];

    NSDate* d = [NSDate dateWithTimeIntervalSince1970:[[_sensor objectForKey:@"last"] timeIntervalSince1970] - (minutes * 60)];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];

    return [dateFormatter stringFromDate:d];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if(((AppDelegate*)([[UIApplication sharedApplication] delegate])).view == self)
    {
        ((AppDelegate*)([[UIApplication sharedApplication] delegate])).view = nil;
    }
}

- (void)updateLabelText:(NSDictionary*)cs bgv:(int)bgv trv:(int)trv {

    NSDate* lt = [cs objectForKey:@"last"];
    NSNumber* st = [cs objectForKey:@"sensor_time"];
    NSDate* end = [NSDate dateWithTimeIntervalSince1970:([lt timeIntervalSince1970] + ((14*24*60)-[st intValue])*60)];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];

    self.sensorLabel.text = [NSString stringWithFormat:@"Sensor ID: %@\nEndet %@\nletzter Read %@\naktueller Trend: %d\naktueller Wert: %d",[cs objectForKey:@"sensor"],[dateFormatter stringFromDate:end],[dateFormatter stringFromDate:lt],bgv,trv];
    
}
-(void) updateGraph:(NSDictionary*)sensor
{
    _sensor = sensor;

    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelFont = [UIFont systemFontOfSize:12.f];
    xAxis.labelTextColor = UIColor.blackColor;
    xAxis.drawGridLinesEnabled = NO;
    xAxis.drawAxisLineEnabled = NO;
    xAxis.spaceBetweenLabels = 1.0;
    xAxis.valueFormatter = self;

    [_xAxisValues removeAllObjects];
    NSDictionary* trend = [sensor objectForKey:@"trend"];
    NSDictionary* historie = [sensor objectForKey:@"historie"];
    for(NSNumber* t in [trend keyEnumerator])
    {
        [_xAxisValues addObject:t];
    }
    for(NSNumber* t in [historie keyEnumerator])
    {
        if(![_xAxisValues containsObject:t])
        {
            [_xAxisValues addObject:t];
        }
    }
    [_xAxisValues sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue"
                                                                       ascending:YES]]];
    NSLog(@"x_values: %@",[_xAxisValues description]);

    NSMutableArray *xVals = [[NSMutableArray alloc] init];

    NSMutableArray *yVals1 = [[NSMutableArray alloc] init];
    NSMutableArray *yVals2 = [[NSMutableArray alloc] init];

    int max = 0;
    int min = 5000;

    int bgv = 0;
    int trv = 0;
    for (int i = 0; i < [_xAxisValues count]; i++)
    {
        NSNumber* ts = [_xAxisValues objectAtIndex:i];
        [xVals addObject:[ts stringValue]];

        if([trend objectForKey:ts])
        {
            int v = [[trend objectForKey:ts] intValue];
            if(v<=25)continue;
            if(v>=450)continue;
            if(v > max)max = v;
            if(v < min)min = v;
            [yVals2 addObject:[[ChartDataEntry alloc] initWithValue:v xIndex:i]];
            trv = v;
        }
        if([historie objectForKey:ts])
        {
            int v = [[historie objectForKey:ts] intValue];
            if(v<=25)continue;
            if(v>=450)continue;
            if(v > max)max = v;
            if(v < min)min = v;
            [yVals1 addObject:[[ChartDataEntry alloc] initWithValue:v xIndex:i]];
            bgv = v;
        }
    }
    if(max == 0 || min == 5000)
        return;

    [self updateLabelText:sensor bgv:bgv trv:trv];

    ChartYAxis *leftAxis = _chartView.leftAxis;
    leftAxis.axisMaxValue = ((max+50)/25)*25;
    leftAxis.axisMinValue = ((min-50)/25)*25;;

    LineChartDataSet *set1 = nil;
    LineChartDataSet *set2 = nil;

    [_chartView clear];

    set1 = [[LineChartDataSet alloc] initWithYVals:yVals1 label:@"Verlauf"];
    set1.axisDependency = AxisDependencyLeft;
    [set1 setColor:[UIColor darkGrayColor]];//colorWithRed:51/255.f green:181/255.f blue:229/255.f alpha:1.f]];
    [set1 setCircleColor:UIColor.blackColor];
    set1.lineWidth = 4.0;
    set1.circleRadius = 2.0;
    set1.drawValuesEnabled = NO;
    //set1.fillAlpha = 65/255.0;
    //set1.fillColor = [UIColor lightGrayColor];//[UIColor colorWithRed:51/255.f green:181/255.f blue:229/255.f alpha:1.f];
    //set1.highlightColor = [UIColor colorWithRed:244/255.f green:117/255.f blue:117/255.f alpha:1.f];
    set1.drawCircleHoleEnabled = NO;

    set2 = [[LineChartDataSet alloc] initWithYVals:yVals2 label:@"Trend"];
    set2.axisDependency = AxisDependencyLeft;
    [set2 setColor:[UIColor blueColor]];//colorWithRed:51/255.f green:181/255.f blue:229/255.f alpha:1.f]];
    [set2 setCircleColor:UIColor.blackColor];
    set2.lineWidth = 4.0;
    set2.circleRadius = 2.0;
    set2.drawValuesEnabled = NO;
    //set1.fillAlpha = 65/255.0;
    //set1.fillColor = [UIColor lightGrayColor];//[UIColor colorWithRed:51/255.f green:181/255.f blue:229/255.f alpha:1.f];
    //set1.highlightColor = [UIColor colorWithRed:244/255.f green:117/255.f blue:117/255.f alpha:1.f];
    set2.drawCircleHoleEnabled = NO;


        NSMutableArray *dataSets = [[NSMutableArray alloc] init];
        [dataSets addObject:set1];
    [dataSets addObject:set2];

        LineChartData *data = [[LineChartData alloc] initWithXVals:xVals dataSets:dataSets];
        [data setValueTextColor:UIColor.darkGrayColor];
        [data setValueFont:[UIFont systemFontOfSize:9.f]];

        _chartView.data = data;

}

@end
