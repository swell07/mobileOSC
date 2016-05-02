//
//  ViewController.h
//  ExampleOSC
//
//  Created by Charles Martin on 21/05/2014.
//  Copyright (c) 2014 Charles Martin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "F53OSC.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import<CoreLocation/CoreLocation.h>


@interface ViewController : UIViewController <F53OSCPacketDestination>


{
    AVAudioRecorder *recorder;
   	NSTimer *levelTimer;
    NSTimer *timer;
    NSTimer*timer2;
    double lowPassResults;
    CLHeading *heading;
    CLLocationDirection trueNorth;
    CLLocationDirection magneticNorth;
}

-(void)takeMessage:(F53OSCMessage *)message;
-(void)levelTimerCallback:(NSTimer *)timer;
-(void)updateMessage;
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;
-(void)getHeadings;
@end
