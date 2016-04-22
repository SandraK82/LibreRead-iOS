//
//  ViewController.h
//  LibreRead
//
//  Created by fishermen21 on 15.04.16.
//  Copyright © 2016 Softwarehaus Kassel GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Charts;

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *sensorLabel;

@property (weak, nonatomic) IBOutlet LineChartView *chartView;

-(void) updateGraph:(NSDictionary*)sensor;
@end

