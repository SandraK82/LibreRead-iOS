//
//  AppDelegate.m
//  LibreRead
//
//  Created by fishermen21 on 15.04.16.
//  Copyright © 2016 Softwarehaus Kassel GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import <libBlueReader/blueReader.h>
#import <NotificationCenter/NotificationCenter.h>
#import <MMWormhole/MMWormhole.h>

#define WAIT_TIME 120

@interface AppDelegate () <BlueReaderDelegate>
@property (strong, nonatomic) BlueReader* blueReader;
@property (nonatomic) int waitTime;

@property (nonatomic,strong) NSString* myReader;
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (nonatomic,strong) NSString* infoText;
//@property (nonatomic,strong) NSString* sensorText;
@property (nonatomic,strong) NSTimer* timer;
@property (nonatomic,strong) MMWormhole* wormhole;

@property (nonatomic,strong) NSMutableString* current_tag;
@property (nonatomic,strong) NSMutableData* currentData;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.blueReader = [[BlueReader alloc] initWithDelegate:self];
    self.blueReader.consoleLogging = YES;

    self.wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:@"group.softwarehauskassel.sandrakessler.libredata"
                                                         optionalDirectory:@"wormhole"];
    if(_myReader)
    {
        if(self.blueReader.state != CONNECTED)
        {
            self.view.statusLabel.text = @"reconnecting to blueReader…";
            [self.blueReader openConnection:self.myReader];
        }
    }
    else
    {
        self.view.statusLabel.text = @"Searching for blueReader…";
        [self.blueReader startScanningForReader];
    }
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self.timer invalidate];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        self.bgTask = UIBackgroundTaskInvalid;
        [self.timer invalidate];
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)setView:(ViewController *)view
{
    _view = view;
    if(_infoText)
        self.view.statusLabel.text = [NSString stringWithFormat:@"%@ %d", _infoText, _waitTime];
    //self.view.sensorLabel.text = self.sensorText;

}
-(void) info
{
    self.view.statusLabel.text = [NSString stringWithFormat:@"%@ %d", _infoText, _waitTime];

    if(_waitTime <= 0)
    {
        [self.blueReader readTag];
    }
    else
    {
        _waitTime--;
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(info) userInfo:nil repeats:NO];
    }
}
-(void)blueReaderFoundTag:(NSData *)tag error:(NSError *)error
{
    if(!error)
    {
        self.view.statusLabel.text = @"found a Tag, reading…";

        self.current_tag = [NSMutableString new];
        uint8_t* b = (uint8_t*)[tag bytes];
        for(int i = 0; i < [tag length]; i++)
        {
            [self.current_tag appendFormat:@"%02x",b[i]];
        }
        [self.blueReader readAddress:0x03];
    }
    else
    {
        self.infoText = @"no Tag found, sleeping…";
        _waitTime = 60;
        [self.blueReader hybernate];
        [self info];
    }
}
-(uint16_t) bg:(uint8_t*)data index:(uint16_t)lowByte
{
    int bgh = data[lowByte+1];
    int bgl = data[lowByte];
    return ((bgh <<8) + bgl) / 10;//original method
    //return (((bgh <<8) + bgl) / 6) -37;
}
-(void)blueReaderGotData:(uint8_t)adr data:(NSData *)data error:(NSError *)error
{
    if(error)
    {
        self.infoText = @"Tag error, retrying…";
        _waitTime = 10;
        [self.blueReader hybernate];
        [self info];
        return;
    }
    if(adr==0x03)
    {
        _currentData = [NSMutableData new];
    }
    if(adr < 0x27)
    {
        [_currentData appendData:data];
        [self.blueReader readAddress:adr+1];
    }
    else
    {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];

        [self.blueReader hybernate];

        [_currentData appendData:data];

        NSLog(@"read %ld bytes",[_currentData length]);

        uint8_t* d = (uint8_t*)[_currentData bytes];
        uint8_t index_trend = d[26-24];
        uint8_t index_history = d[27-24];
        uint16_t sensor_time = (d[317-24] << 8) + d[316-24];

        NSLog(@"sensor time %d",sensor_time);

        NSMutableDictionary* sensor = [NSMutableDictionary new];
        [sensor setObject:self.current_tag forKey:@"sensor"];
        [sensor setObject:[NSNumber numberWithInteger:sensor_time] forKey:@"sensor_time"];

        /*int days = sensor_time/(24*60);
        int hours = (sensor_time - (days*24*60)) / 60;
        int minutes = (sensor_time - (days*24*60)) - (hours*60);
        self.sensorText = [NSString stringWithFormat:@"Laufzeit: %d Tag(e), %d Stunde(n), %d Minute(n)",days,hours,minutes];
        NSLog(@"%@",self.sensorText);
*/
        NSMutableDictionary* trend = [NSMutableDictionary new];

        uint16_t bgt = 0;
        for(int i = 0; i < 16; i++)
        {
            bgt = [self bg:d index:(4+(6*index_trend))];
            //NSLog(@"trend %d = %d @ %d",index_trend,bgt,sensor_time - (15 - i));
            index_trend = (index_trend+1)%16;
            [trend setObject:[NSNumber numberWithInteger:bgt] forKey:[NSNumber numberWithInteger:sensor_time - (15 - i)]];
        }
        [sensor setObject:trend forKey:@"trend"];

        NSMutableDictionary* history = [NSMutableDictionary new];

        uint16_t h_time = sensor_time -(sensor_time%15);
        h_time -= (15*32);
        uint16_t bg=0;
        for(int i = 0; i < 32; i++)
        {
            uint16_t ndex = (100+(6*index_history));

            bg = [self bg:d index:ndex];
           // NSLog(@"historie %d = %d @ %d {%d}",index_history,bg,h_time,ndex);
            index_history = (index_history+1)%32;
            [history setObject:[NSNumber numberWithInteger:bg] forKey:[NSNumber numberWithInteger:h_time]];
            h_time+=15;
        }
        [sensor setObject:history forKey:@"historie"];

        [sensor setObject:[NSDate date] forKey:@"last"];

        NSNumber* n = [[NSUserDefaults standardUserDefaults] objectForKey:@"count"];

        int nn = [n intValue]+1;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:nn] forKey:@"count"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        /*self.sensorText = [NSString stringWithFormat:@"%@\nletzter Wert: %d vor %d Minuten\n\n%d reads",self.sensorText,bg/10,(sensor_time%15),nn];
*/
        NSData* archive = [[NSUserDefaults standardUserDefaults] objectForKey:@"sensors"];
        NSDictionary* inmutablesensors = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
        if(!inmutablesensors)
        {
            inmutablesensors = [NSDictionary new];
        }
        NSMutableDictionary* sensors = [NSMutableDictionary dictionaryWithDictionary:inmutablesensors];

        [sensors setObject:sensor forKey:self.current_tag];


        archive = [NSKeyedArchiver archivedDataWithRootObject:sensors];
        [self.wormhole passMessageObject:archive
                              identifier:@"sensors"];

        [self.wormhole passMessageObject:self.current_tag
                              identifier:@"current_sensor"];

        [[NSUserDefaults standardUserDefaults] setObject:archive forKey:@"sensors"];
        [[NSUserDefaults standardUserDefaults] setObject:self.current_tag forKey:@"current_tag"];

        [[NSUserDefaults standardUserDefaults] synchronize];

        //self.view.sensorLabel.text = self.sensorText = [NSString stringWithFormat:@"%@\naktueller Trend: %d",self.sensorText,bgt/10];

        self.infoText = @"Tag read completed, sleeping…";
        _waitTime = WAIT_TIME;

        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:WAIT_TIME*2];
        localNotification.alertBody = @"Reader lost!";
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = 1;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];

        [self info];
        [_view updateGraph:sensor];
    }
}
-(void)blueReaderFound:(NSString *)blueReader
{
    self.view.statusLabel.text = @"found a blueReader, connecting…";
    [self.blueReader openConnection:blueReader];
    [self.blueReader stopScanningForReader];
}
-(void)blueReaderClosedConnection:(NSString *)blueReader
{
    self.view.statusLabel.text = @"lost blueReader, reconnecting…";
    [self.blueReader startScanningForReader];
}
-(void)blueReaderChangedStatus:(BlueReaderStatus)status
{
    if(status == READY_FOR_TAG)
    {
        self.view.statusLabel.text = @"blueReader ready…";
    }
}
-(void)blueReaderIdentified:(NSString *)blueReaderData error:(NSError *)error
{

}
-(void)blueReaderOpenedConnection:(NSString *)blueReader
{
    self.view.statusLabel.text = @"opened connection, configuring blueReader…";
    _myReader = blueReader;
    [self.blueReader startbeat:60];
    [self.blueReader readTag];
}
@end
