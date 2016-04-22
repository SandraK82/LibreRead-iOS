//
//  TodayViewController.h
//  BGWidget
//
//  Created by fishermen21 on 18.04.16.
//  Copyright © 2016 Softwarehaus Kassel GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Charts;

@interface TodayViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *dataLabel;

@property (weak, nonatomic) IBOutlet LineChartView *chartView;

@end
