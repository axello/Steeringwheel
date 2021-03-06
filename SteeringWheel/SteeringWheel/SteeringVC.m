//
//  SteeringVC.m
//  SteeringWheel
//
//  Created by Axel Roest on 28-12-14.
//  Copyright (c) 2014 Phluxus. All rights reserved.
//

#import "SteeringVC.h"
#import "ArduinoPins.h"

#define kUpdateFrequency	60.0

#define TOTALPIXELS 30

@interface SteeringVC () {
    int _brightness;
}

// UI
@property (weak, nonatomic) IBOutlet UISlider *accellSlider;
@property (weak, nonatomic) IBOutlet UISlider *sensitivitySlider;
@property (weak, nonatomic) IBOutlet UISlider *brightnessSlider;

@property (weak, nonatomic) IBOutlet UILabel *currentAccellerationLevel;
@property (weak, nonatomic) IBOutlet UILabel *currentSensitivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxAccellerationLevel;
@property (weak, nonatomic) IBOutlet UIImageView *arduinoReadyView;

// actions
- (IBAction)buzzer:(id)sender;
- (IBAction)setBrightness:(id)sender;
- (IBAction)setSensitivitySlider:(UISlider *)slider;

// internals
@property (nonatomic, assign) double accelleration;
@property (nonatomic, assign) double maxAccelleration;
@property (nonatomic, assign) double sensitivity;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) AccelerometerFilter *filter;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSTimer *syncTimer;

// this is the state machine for the currently lit up segments
@property (nonatomic, assign) kWheelSegments currentSegments;

@property (nonatomic, strong) NSDictionary *phoneMaxAccelleration;
@property (nonatomic, strong) NSString *currentPhone;

// contains the --current-- state of all the pixels
@property (nonatomic, strong) NSMutableArray *allPixels;
@end

@implementation SteeringVC
@synthesize protocol;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentPhone = @"iPhone5";
    // Do any additional setup after loading the view, typically from a nib.
    [self setupMotionManager];
    self.protocol = [[RBLProtocol alloc] init];
    self.protocol.delegate = self;
    self.protocol.ble = self.ble;
    self.arduinoReadyView.hidden = YES;
    self.allPixels = [[NSMutableArray alloc] initWithCapacity:TOTALPIXELS];
    [self setupArduinoPorts];
    for (int i=0 ; i < TOTALPIXELS ; i++) {
        self.allPixels[i] = @-1  ;
    }
    self.sensitivity = 1.0;
    self.sensitivitySlider.value = self.sensitivity;
    _brightness = 127;
    self.brightnessSlider.value = _brightness;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(syncTimeout:) userInfo:nil repeats:NO];
//
//    [protocol queryProtocolVersion];
    
    [self allLights];

}
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.motionManager startAccelerometerUpdates];
    [self startTimer];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.motionManager stopAccelerometerUpdates];
    [self stopTimer];
    [super viewWillDisappear:animated];
}

- (void) setupMotionManager
{
    [self changeFilter:[LowpassFilter class]];

    // Create coremotion manager object
    CMMotionManager *motManager = [[CMMotionManager alloc] init];
    motManager.deviceMotionUpdateInterval = 1.0 / kUpdateFrequency;
//    [motManager startAccelerometerUpdates];
    [motManager startDeviceMotionUpdates];
    self.motionManager = motManager;
    
    self.maxAccelleration = 0.;
    
    self.phoneMaxAccelleration = @{@"iPhone4": @2.8 , @"iPhone5" : @3, @"iPhone6" : @6};
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)setAccellLimitSlider:(UISlider *)slider
{
    self.accelleration = slider.value;
}

- (IBAction)setSensitivitySlider:(UISlider *)slider
{
    self.sensitivity = slider.value;
    
    self.currentSensitivityLabel.text = [NSString stringWithFormat:@"sensitivity: %5.3f",self.sensitivity];

}

#pragma mark - timers
- (void) startTimer
{
    if (self.updateTimer) {
        [self.updateTimer invalidate];
    }
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/kUpdateFrequency target:self selector:@selector(update:) userInfo:nil repeats:YES];
}

- (void) stopTimer
{
    if (self.updateTimer) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
}

- (void) update:(NSTimer *)aTimer
{
    // update screen
    CMAcceleration acc = [self.motionManager.deviceMotion userAcceleration];
    [self.filter addAcceleration:acc];
    double absAcc = [self.filter absAccelleration];
    
    self.accellSlider.value = absAcc;
    self.currentAccellerationLevel.text = [NSString stringWithFormat:@"acc: %5.3f",absAcc];
    
    if (absAcc > self.maxAccelleration) {
        self.maxAccelleration = absAcc;
        self.maxAccellerationLevel.text = [NSString stringWithFormat:@"Max acc: %5.3f",absAcc];
    }
    
    [self updateNeoPixels:absAcc];
}

- (void) updateNeoPixels:(double) absAcc
{
    // double maxAcc = [self.phoneMaxAccelleration[self.currentPhone] doubleValue];
    double maxAcc = self.sensitivity;
    double step = maxAcc / 6.0;
    
    if (absAcc != self.currentSegments) {
        kWheelSegments newSegments;
        // decide upon external actions
        if (absAcc > step * 5.0) {
            newSegments = kWheelSegmentOff;
            // and we buzz
        } else if (absAcc > step * 4.0) {
            newSegments = kWheelSegment5;
        } else if (absAcc > step * 3.0) {
            newSegments = kWheelSegment4;
        } else if (absAcc > step * 2.0) {
            newSegments = kWheelSegment3;
        } else if (absAcc > step * 1.0) {
            newSegments = kWheelSegment2;
        } else {
            newSegments = kWheelSegment1;
        }
        // buzzer
        [self buzz:(kWheelSegmentOff == newSegments)];
        // lights
        [self lights:newSegments];
        
        // NSLog(@"Accelleration changed to %f, level %lu",absAcc, (unsigned long)newSegments);
        self.currentSegments = newSegments;
        // send stuff over BLE
    }
}

-(void) syncTimeout:(NSTimer *)timer
{
    NSLog(@"Timeout: no response");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"No response from the SteeringWheel Controller."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    // disconnect it
    [self.ble.CM cancelPeripheralConnection:self.ble.activePeripheral];
}

#pragma mark - filters

- (void)changeFilter:(Class)filterClass
{
    // Ensure that the new filter class is different from the current one...
    if (filterClass != [self.filter class])
    {
        // And if it is, release the old one and create a new one.
        self.filter = [[filterClass alloc] initWithSampleRate:kUpdateFrequency cutoffFrequency:5.0];
        // Set the adaptive flag
        self.filter.adaptive = YES;
    }
}

#pragma mark - BLE
-(void) processData:(uint8_t *) data length:(uint8_t) length
{
#if defined(CV_DEBUG)
    NSLog(@"ControlView: processData");
    NSLog(@"Length: %d", length);
#endif
    
   [protocol parseData:data length:length];
}

#pragma mark - RBL
-(void) protocolDidReceiveProtocolVersion:(uint8_t)major Minor:(uint8_t)minor Bugfix:(uint8_t)bugfix
{
    NSLog(@"protocolDidReceiveProtocolVersion: %d.%d.%d", major, minor, bugfix);
    
    // get response, so stop timer
    [self.syncTimer invalidate];
    self.syncTimer = nil;
    
    self.arduinoReadyView.hidden = NO;
    [self setupArduinoPorts];

//    uint8_t buf[] = {'B', 'L', 'E'};
//    [protocol sendCustomData:buf Length:3];
//    
//    [protocol queryTotalPinCount];
}

-(void) protocolDidReceiveTotalPinCount:(UInt8) count
{
    NSLog(@"protocolDidReceiveTotalPinCount: %d", count);
}

-(void) protocolDidReceivePinCapability:(uint8_t)pin Value:(uint8_t)value
{
    NSLog(@"protocolDidReceivePinCapability");
    NSLog(@" Pin %d Capability: 0x%02X", pin, value);
    
    if (value == 0)
        NSLog(@" - Nothing");
    else
    {
        if (value & PIN_CAPABILITY_DIGITAL)
            NSLog(@" - DIGITAL (I/O)");
        if (value & PIN_CAPABILITY_ANALOG)
            NSLog(@" - ANALOG");
        if (value & PIN_CAPABILITY_PWM)
            NSLog(@" - PWM");
        if (value & PIN_CAPABILITY_SERVO)
            NSLog(@" - SERVO");
    }
}

-(void) protocolDidReceivePinData:(uint8_t)pin Mode:(uint8_t)mode Value:(uint8_t)value
{
    NSLog(@"protocolDidReceiveDigitalData");
    NSLog(@" Pin: %d, mode: %d, value: %d", pin, mode, value);
}

-(void) protocolDidReceivePinMode:(uint8_t)pin Mode:(uint8_t)mode
{
    NSLog(@"protocolDidReceivePinMode");
    
    if (mode == INPUT)
        NSLog(@" Pin %d Mode: INPUT", pin);
    else if (mode == OUTPUT)
        NSLog(@" Pin %d Mode: OUTPUT", pin);
    else if (mode == PWM)
        NSLog(@" Pin %d Mode: PWM", pin);
    else if (mode == SERVO)
        NSLog(@" Pin %d Mode: SERVO", pin);
    
}

-(void) protocolDidReceiveCustomData:(UInt8 *)data length:(UInt8)length
{
    // Handle your customer data here.
    for (int i = 0; i< length; i++)
        printf("0x%2X ", data[i]);
    printf("\n");
}

#pragma mark - Arduino methods
- (void) setupArduinoPorts
{
    [protocol setPinMode:kBuzzPin Mode:OUTPUT];
}

- (void) buzz:(BOOL)buzz
{
    if (buzz) {
        NSLog(@"Buzzer ON");
        [protocol digitalWrite:kBuzzPin Value:HIGH];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [protocol digitalWrite:kBuzzPin Value:LOW];
            NSLog(@"Buzzer Auto OFF");
        });
    } else {
//        [protocol digitalWrite:kBuzzPin Value:LOW];
//        NSLog(@"Buzzer OFF");
    }
}

- (void) lights:(kWheelSegments)segments
{
    static kWheelSegments lastSegmentShown=kWheelSegment1;
//    
//    if (kWheelSegmentOff == segments ) {
//        for (int i = 0 ; i < 29; i++) {
//            [protocol rgbWritePixel:i red:0 green:0 blue:0];
//        }
//        return;
//    }
    NSMutableArray *newPixelState = [[NSMutableArray alloc] initWithCapacity:TOTALPIXELS];
    
    // only do something when the state has changed
    if (segments != lastSegmentShown) {
        int startLed=0;
        int endLed=-1;
        switch (segments) {
            case kWheelSegment1:
                startLed = 0;
                endLed = 29;
                break;
            case kWheelSegment2:
                startLed = 3;
                endLed = 26;
                break;
            case kWheelSegment3:
                startLed = 6;
                endLed = 23;
                break;
            case kWheelSegment4:
                startLed = 9;
                endLed = 20;
                break;
            case kWheelSegment5:
                startLed = 12;
                endLed = 17;
                break;
            case kWheelSegmentOff:
            default:
                break;
        }
//        
//        switch (segments) {
//            case kWheelSegment1:
//                startLed = 25;
//                endLed = 29;
//            case kWheelSegmentOff:
//            default:
//                break;
//        }
        
        // loop over all pixels and set all pixels according to 'segments' state
        for (int i = 0 ; i < TOTALPIXELS; i++) {
            if (i >= startLed && i <= endLed) {
                newPixelState[i] = @1;              // means green
            } else {
                newPixelState[i] = @0;              // means off
            }
        }

        // compare new pixels with old pixels and only send the changes to the last pixel setup
        for (int i = 0 ; i < TOTALPIXELS; i++) {
            int value = ((NSNumber *) newPixelState[i]).intValue;
            int oldValue = ((NSNumber *) self.allPixels[i]).intValue;
            if (value != oldValue) {
                if (value) {
                    [protocol rgbWritePixel:i red:0 green:_brightness blue:0];
                } else {
                    [protocol rgbWritePixel:i red:0 green:0 blue:0];
                }
                self.allPixels[i] = [newPixelState[i] copy];
            }
        }
        
        // store current segment setup
        lastSegmentShown = segments;
    }
}

- (void) allLights
{
    for (int i = 0 ; i < TOTALPIXELS; i++) {
            [protocol rgbWritePixel:i red:0 green:0 blue:_brightness * 0.25];
    }
}

- (IBAction)buzzer:(id)sender
{
    [self buzz:YES];
}

- (void) resetAllPixels
{
    for (int i = 0 ; i < TOTALPIXELS; i++) {
        int value = ((NSNumber *) self.allPixels[i]).intValue;
        if (value) {
            [protocol rgbWritePixel:i red:0 green:_brightness blue:0];
        } else {
            [protocol rgbWritePixel:i red:0 green:0 blue:0];
        }
    }

}
- (IBAction)setBrightness:(UISlider *)sender {
    _brightness = sender.value;
    [self resetAllPixels];
}
@end
