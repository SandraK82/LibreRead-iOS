//
//  TodayViewController.m
//  BGWidget
//
//  Created by fishermen21 on 18.04.16.
//  Copyright © 2016 Softwarehaus Kassel GmbH. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <MMWormhole/MMWormhole.h>

@interface TodayViewController () <NCWidgetProviding,ChartViewDelegate,ChartXAxisValueFormatter>
@property (nonatomic,strong) MMWormhole* wormhole;
@property (nonatomic,strong) NSMutableArray* xAxisValues;
@property (nonatomic,strong) NSDictionary* sensor;
@end

@implementation TodayViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.softwarehauskassel.sandrakessler.libredata"
                                                             optionalDirectory:@"wormhole"];
        [self.wormhole listenForMessageWithIdentifier:@"current_sensor"
                                             listener:^(id messageObject) {
                                                 [self updateLabelText];
                                             }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataLabel.text = @"";

    _chartView.delegate = self;

    _chartView.descriptionText = @"";
    _chartView.noDataTextDescription = @"You need to provide data for the chart.";

    _chartView.backgroundColor = [UIColor clearColor];

    _chartView.legend.enabled = NO;
    [_chartView setScaleEnabled:NO];
    _chartView.pinchZoomEnabled = NO;
    _chartView.dragEnabled = NO;

    [_chartView setHighlightPerTapEnabled:NO];
    [_chartView setHighlightPerDragEnabled:NO];

    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelFont = [UIFont systemFontOfSize:12.f];
    xAxis.labelTextColor = [UIColor lightTextColor];
    xAxis.drawGridLinesEnabled = NO;
    xAxis.drawAxisLineEnabled = NO;
    xAxis.spaceBetweenLabels = 1.0;

    ChartLimitLine *ll1 = [[ChartLimitLine alloc] initWithLimit:170.0 label:@"Hoch"];
    ll1.lineWidth = 1.0;
    ll1.lineColor = [UIColor redColor];
    ll1.lineDashLengths = @[@5.f, @5.f];
    ll1.labelPosition = ChartLimitLabelPositionRightTop;
    ll1.valueFont = [UIFont systemFontOfSize:8.0];
    ll1.valueTextColor = [UIColor lightTextColor];
    ChartLimitLine *ll2 = [[ChartLimitLine alloc] initWithLimit:50.0 label:@"Tief"];
    ll2.lineWidth = 1.0;
    ll2.lineColor = [UIColor redColor];
    ll2.lineDashLengths = @[@5.f, @5.f];
    ll2.labelPosition = ChartLimitLabelPositionRightBottom;
    ll2.valueFont = [UIFont systemFontOfSize:8.0];
    ll2.valueTextColor = [UIColor lightTextColor];

    ChartYAxis *leftAxis = _chartView.leftAxis;
    leftAxis.labelTextColor = [UIColor lightTextColor];
    leftAxis.axisMaxValue = 450.0;
    leftAxis.axisMinValue = 0.0;
    leftAxis.drawGridLinesEnabled = YES;
    leftAxis.drawZeroLineEnabled = NO;
    leftAxis.granularityEnabled = YES;
    [leftAxis addLimitLine:ll1];
    [leftAxis addLimitLine:ll2];

    _chartView.rightAxis.enabled = NO;

    _xAxisValues = [NSMutableArray new];
    [self updateLabelText];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    [self updateLabelText];

    completionHandler(NCUpdateResultNewData);
}

-(void)viewDidAppear:(BOOL)animated
{
    [self updateLabelText];
}

- (void)updateLabelText {
    NSString* sensor = [self.wormhole messageWithIdentifier:@"current_sensor"];;

    NSData* dda = [self.wormhole messageWithIdentifier:@"sensors"];
    NSDictionary* dd = [NSKeyedUnarchiver unarchiveObjectWithData:dda];

    NSDictionary* cs = [dd objectForKey:sensor];

    [self updateGraph: cs];

    NSDate* lt = [cs objectForKey:@"last"];
    NSNumber* st = [cs objectForKey:@"sensor_time"];
    NSDate* end = [NSDate dateWithTimeIntervalSince1970:([lt timeIntervalSince1970] + ((14*24*60)-[st intValue])*60)];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];

    self.dataLabel.text = [NSString stringWithFormat:@"Sensor ID: %@\nEndet %@\nletzter Read %@",sensor,[dateFormatter stringFromDate:end],[dateFormatter stringFromDate:lt]];

}
-(void) updateGraph:(NSDictionary*)sensor
{
    _sensor = sensor;

    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelFont = [UIFont systemFontOfSize:8.f];
    xAxis.labelTextColor = [UIColor lightGrayColor];
    xAxis.drawGridLinesEnabled = NO;
    xAxis.drawAxisLineEnabled = NO;
    xAxis.spaceBetweenLabels = 1.0;
    xAxis.valueFormatter = self;

    [_xAxisValues removeAllObjects];
    NSDictionary* trend = [sensor objectForKey:@"trend"];
    for(NSNumber* t in [trend keyEnumerator])
    {
        [_xAxisValues addObject:t];
    }
    [_xAxisValues sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"intValue"
                                                                       ascending:YES]]];
    NSLog(@"x_values: %@",[_xAxisValues description]);

    NSMutableArray *xVals = [[NSMutableArray alloc] init];

    NSMutableArray *yVals1 = [[NSMutableArray alloc] init];

    int max = 0;
    int min = 5000;

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
            [yVals1 addObject:[[ChartDataEntry alloc] initWithValue:v xIndex:i]];
        }
    }

    if(max == 0 || min == 5000)
        return;

    ChartYAxis *leftAxis = _chartView.leftAxis;
    leftAxis.axisMaxValue = ((max+50)/25)*25;
    leftAxis.axisMinValue = ((min-50)/25)*25;;

    LineChartDataSet *set1 = nil;

    [_chartView clear];

    set1 = [[LineChartDataSet alloc] initWithYVals:yVals1 label:@""];
    set1.axisDependency = AxisDependencyLeft;
    [set1 setColor:[UIColor lightGrayColor]];
    [set1 setCircleColor:[UIColor lightTextColor]];
    set1.lineWidth = 4.0;
    set1.circleRadius = 2.0;
    set1.drawValuesEnabled = NO;
    set1.drawCircleHoleEnabled = NO;


    NSMutableArray *dataSets = [[NSMutableArray alloc] init];
    [dataSets addObject:set1];

    LineChartData *data = [[LineChartData alloc] initWithXVals:xVals dataSets:dataSets];
    [data setValueTextColor:UIColor.darkGrayColor];
    [data setValueFont:[UIFont systemFontOfSize:9.f]];

    _chartView.data = data;
    
}
- (NSString * _Nonnull)stringForXValue:(NSInteger)index original:(NSString * _Nonnull)original viewPortHandler:(ChartViewPortHandler * _Nonnull)viewPortHandler
{
    NSNumber* st = [_sensor objectForKey:@"sensor_time"];
    NSNumber* os = [_xAxisValues objectAtIndex:index];

    int minutes = [st intValue] - [os intValue];

    NSDate* d = [NSDate dateWithTimeIntervalSince1970:[[_sensor objectForKey:@"last"] timeIntervalSince1970] - (minutes * 60)];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];

    /*if(minutes > 15)
     {
     int h = minutes / 60;
     minutes = minutes % 60;
     return [NSString stringWithFormat:@"-%d:%d",h,minutes];
     }
     return [NSString stringWithFormat:@"-%d",minutes];
     */
    return [dateFormatter stringFromDate:d];
}


@end
