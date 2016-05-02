//
//  ViewController.m
//  ExampleOSC
//
//  Created by Charles Martin on 21/05/2014.
//  Copyright (c) 2014 Charles Martin. All rights reserved.
//

#import "ViewController.h"
#import "CoreMotion/CoreMotion.h" 

#define SENDHOST @"10.0.1.3"
#define SENDPORT 3000
#define RECEIVEPORT 3001
@import CoreLocation;

@interface ViewController ()<UITextFieldDelegate>

@property (strong, nonatomic) F53OSCClient* oscClient;
@property (strong, nonatomic) F53OSCServer* oscServer;
@property(readonly, nonatomic) CLHeadingComponentValue x;
@property(readonly, nonatomic) CLHeadingComponentValue y;
@property(readonly, nonatomic) CLHeadingComponentValue z;
@property (nonatomic, strong) CLLocationManager *location;
@property(readonly, nonatomic) CLLocationDirection *magneticHeading;
@property(strong, nonatomic) CLHeading *heading;
@property(readonly, nonatomic) CLLocationDirection *trueHeading;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *argumentsLabel;

@property (weak, nonatomic) IBOutlet UITextField *HostAddress;
@property (weak, nonatomic) IBOutlet UITextField *PortNumber;

@property (weak, nonatomic) IBOutlet UIButton *sendMessage;

@property (weak, nonatomic) IBOutlet UISwitch *switch1;
@property (weak, nonatomic) IBOutlet UISwitch *switch2;
@property (weak, nonatomic) IBOutlet UISwitch *switch3;
@property (weak, nonatomic) IBOutlet UISwitch *switch4;

@property (nonatomic, strong) CMMotionManager *motion;

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.oscClient = [[F53OSCClient alloc] init];
    self.oscServer = [[F53OSCServer alloc] init];
    self.motion = [[CMMotionManager alloc] init];
    [self.oscServer setPort:RECEIVEPORT];
    [self.oscServer setDelegate:self];
    self.HostAddress.delegate=self;
    self.PortNumber.delegate=self;
    [self.oscServer startListening];
    [super viewDidLoad];
   
    
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax],         AVEncoderAudioQualityKey,
                              nil];
    
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    self.location = [[CLLocationManager alloc] init];
    self.location.delegate = self;
    //[self.location startUpdatingLocation];
    //[self.location startUpdatingHeading];
    
}
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    
    trueNorth = [newHeading trueHeading];
    //NSLog(@"trueheading = %f", trueNorth);
    magneticNorth = [newHeading magneticHeading];
    //NSLog(@"magneticheading = %f", magneticNorth);
}

- (IBAction)sendMessage:(UIButton *)sender {
    static int counter;
    counter++;
    
    if (counter % 2 == 1) {
        self.switch1.enabled = NO;
        self.switch2.enabled = NO;
        self.switch3.enabled = NO;
        self.switch4.enabled = NO;
        [self.sendMessage setTitle:@"UNLOCK" forState:UIControlStateNormal];
    }
    
    else if (counter % 2 == 0) {
        self.switch1.enabled = YES;
        self.switch2.enabled = YES;
        self.switch3.enabled = YES;
        self.switch4.enabled = YES;
        [self.sendMessage setTitle:@"LOCK" forState:UIControlStateNormal];
        }
}


- (IBAction)switch1:(id)sender {
    if ([sender isOn]) {
        NSLog(@"switch1 is ON");
        int portnumber=[self.PortNumber.text intValue];
        if ([self.motion isAccelerometerAvailable]){
            
            if ([self.motion isAccelerometerActive] == NO){
                
                [self.motion setAccelerometerUpdateInterval:1.0f / 40.0f];
                
                NSOperationQueue *queue = [[NSOperationQueue alloc] init];
                
                [self.motion
                 startAccelerometerUpdatesToQueue:queue
                 withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                     
                     NSLog(@"Gyro Acc x = %.04f", accelerometerData.acceleration.x);
                     NSLog(@"Gyro Acc y = %.04f", accelerometerData.acceleration.y);
                     NSLog(@"Gyro Acc z = %.04f", accelerometerData.acceleration.z);
                     
                     F53OSCMessage *message1 =
                     [F53OSCMessage messageWithAddressPattern:@"/Acc/X"
                                                    arguments:@[[NSNumber numberWithFloat:accelerometerData.acceleration.x]]];
                     F53OSCMessage *message2 =
                     [F53OSCMessage messageWithAddressPattern:@"/Acc/Y"
                                                    arguments:@[[NSNumber numberWithFloat:accelerometerData.acceleration.y]]];
                     F53OSCMessage *message3 =
                     [F53OSCMessage messageWithAddressPattern:@"/Acc/Z"
                                                    arguments:@[[NSNumber numberWithFloat:accelerometerData.acceleration.z]]];
                     
                     
                     [self.oscClient sendPacket:message1 toHost:self.HostAddress.text onPort:portnumber];
                     [self.oscClient sendPacket:message2 toHost:self.HostAddress.text onPort:portnumber];
                     [self.oscClient sendPacket:message3 toHost:self.HostAddress.text onPort:portnumber];
                     
                 }];
                
            } else {
                NSLog(@"Acc is already active.");
            }
        } else {
            NSLog(@"Acc isn't available.");
        }
    }
    else
    {
        NSLog(@"switch1 is OFF");
        [self.motion stopAccelerometerUpdates];
    }
}

- (IBAction)switch2:(id)sender {
    if ([sender isOn]) {
        NSLog(@"switch2 is ON");
        //int portnumber=[self.PortNumber.text intValue];
        if ([self.motion isGyroAvailable]){
            
            if ([self.motion isGyroActive] == NO){
            
            [self.motion setGyroUpdateInterval:1.0f / 40.0f];
            
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            
            [self.motion
             startGyroUpdatesToQueue:queue
             withHandler:^(CMGyroData *gyroData, NSError *error) {
                 
                 NSLog(@"Gyro Rotation x = %.04f", gyroData.rotationRate.x);
                 NSLog(@"Gyro Rotation y = %.04f", gyroData.rotationRate.y);
                 NSLog(@"Gyro Rotation z = %.04f", gyroData.rotationRate.z);
                
                 F53OSCMessage *message4 =
                 [F53OSCMessage messageWithAddressPattern:@"/Gyro/X"
                                                arguments:@[[NSNumber numberWithFloat:gyroData.rotationRate.x]]];
                 F53OSCMessage *message5 =
                 [F53OSCMessage messageWithAddressPattern:@"/Gyro/Y"
                                                arguments:@[[NSNumber numberWithFloat:gyroData.rotationRate.y]]];
                 F53OSCMessage *message6 =
                 [F53OSCMessage messageWithAddressPattern:@"/Gyro/Z"
                                                arguments:@[[NSNumber numberWithFloat:gyroData.rotationRate.z]]];
                 
                 [self.oscClient sendPacket:message4 toHost:self.HostAddress.text onPort:[self.PortNumber.text intValue]];
                 [self.oscClient sendPacket:message5 toHost:self.HostAddress.text onPort:[self.PortNumber.text intValue]];
                 [self.oscClient sendPacket:message6 toHost:self.HostAddress.text onPort:[self.PortNumber.text intValue]];
             }];
                
        } else {
            NSLog(@"Gyro is already active.");
        }
        
        } else {
            NSLog(@"Gyro isn't available.");
        }
    }
    else
    {
        NSLog(@"switch2 is OFF");
        [self.motion stopGyroUpdates];
    }
}
- (IBAction)switch3:(id)sender {
    if ([sender isOn]) {
        NSLog(@"switch3 is ON");
        if ([CLLocationManager headingAvailable]){
            [self.location startUpdatingHeading];
            [self locationManager:self.location didUpdateHeading:self.heading
             ];
            timer2 = [NSTimer scheduledTimerWithTimeInterval: .1 target: self selector: @selector(getHeadings) userInfo: nil repeats: YES];
        }
    }
        else{
            NSLog(@"switch3 is OFF");
            [self.location stopUpdatingHeading];
        }
    
    
}
- (IBAction)switch4:(id)sender {
}

- (IBAction)switch5:(id)sender {
    if ([sender isOn]){
        NSLog(@"switch5 is ON");
           levelTimer = [NSTimer scheduledTimerWithTimeInterval: .1 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES
                         ];
        if (recorder) {
            [recorder prepareToRecord];
            recorder.meteringEnabled = YES;

            [recorder updateMeters];
            [recorder record];
                     }
        timer = [NSTimer scheduledTimerWithTimeInterval: .1 target: self selector: @selector(updateMessage) userInfo: nil repeats: YES];
        
    }
    
    else {
    NSLog(@"switch5 is OFF");
    [recorder stop];
    [levelTimer invalidate];
    [timer invalidate];
        
        
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


-(void)takeMessage:(F53OSCMessage *)message {
    [self.addressLabel setText:message.addressPattern];
    [self.argumentsLabel setText:[message.arguments description]];
}

-(void)updateMessage
{
    F53OSCMessage *message10 =
    [F53OSCMessage messageWithAddressPattern:@"/breath"
                                   arguments:@[[NSNumber numberWithFloat:lowPassResults]]];
    [self.oscClient sendPacket:message10 toHost:self.HostAddress.text onPort:[self.PortNumber.text intValue]];
 
};
-(void)getHeadings
{
    F53OSCMessage *message11 =
    [F53OSCMessage messageWithAddressPattern:@"/headings"
                                   arguments:@[[NSNumber numberWithFloat:trueNorth]]];
    [self.oscClient sendPacket:message11 toHost:self.HostAddress.text onPort:[self.PortNumber.text intValue]];
    NSLog(@"testheading = %f", trueNorth);
    

}
- (void)levelTimerCallback:(NSTimer *)timer {
                    [recorder updateMeters];
                    NSLog(@"Average input: %f Peak input: %f", [recorder averagePowerForChannel:0], [recorder peakPowerForChannel:0]);
                
                    const double ALPHA = 0.05;
                    double peakPowerForChannel = pow(10, (0.05 * [recorder peakPowerForChannel:0]));
                    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;
                    
                    if (lowPassResults >0.55)
                        NSLog(@"Mic blow detected:%g",lowPassResults);
    }

@end



