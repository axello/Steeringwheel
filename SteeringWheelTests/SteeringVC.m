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


@interface SteeringVC ()
    
@property (weak, nonatomic) IBOutlet UISlider *accellSlider;
@property (weak, nonatomic) IBOutlet UISlider *brakeSlider;

@property (weak, nonatomic) IBOutlet UILabel *currentAccellerationLevel;
@property (weak, nonatomic) IBOutlet UILabel *currentBrakeLevel;
@property (weak, nonatomic) IBOutlet UILabel *maxAccellerationLevel;
@property (weak, nonatomic) IBOutlet UILabel *maxBrakeLevel;
@property (weak, nonatomic) IBOutlet UIImageView *arduinoReadyView;

@property (nonatomic, assign) double accelleration;
@property (nonatomic, assign) double brakeLimit;
@property (nonatomic, assign) double maxAccelleration;
@property (nonatomic, assign) double maxBrakeLimit;

@property (nonatomic, strong) NSNumber *brake;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) AccelerometerFilter *filter;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSTimer *syncTimer;

@end

@implementation SteeringVC
@synthesize protocol;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupMotionManager];
    self.protocol = [[RBLProtocol alloc] init];
    self.protocol.delegate = self;
    self.protocol.ble = self.ble;
    self.arduinoReadyView.hidden = YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(syncTimeout:) userInfo:nil repeats:NO];

    [protocol queryProtocolVersion];
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
    self.maxBrakeLimit = 0.;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)setAccellLimitSlider:(UISlider *)slider
{
    self.accelleration = slider.value;
}

- (IBAction)setBrakeLimitSlider:(UISlider *)slider
{
    self.brakeLimit = slider.value;
}

- (NSNumber *)brake
{
    return [NSNumber numberWithDouble:self.brakeLimit];
}

- (void) setBrake:(NSNumber *)brake
{
    self.brakeLimit = brake.doubleValue;
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
    self.brakeSlider.value = absAcc;
    self.currentBrakeLevel.text = [NSString stringWithFormat:@"brake: %5.3f",absAcc];
    if (absAcc > self.maxBrakeLimit) {
        self.maxBrakeLimit = absAcc;
        self.maxBrakeLevel.text = [NSString stringWithFormat:@"Max brake: %5.3f",absAcc];
    }

    
    // decide upon external actions
    if (absAcc > 0.5) {
        [self buzz:YES];
    }
    // send stuff over BLE
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
    [protocol setPinMode:kWheel1 Mode:OUTPUT];
    [protocol setPinMode:kWheel2 Mode:OUTPUT];
    [protocol setPinMode:kWheel3 Mode:OUTPUT];
}

- (void) buzz:(BOOL)buzz
{
    if (buzz) {
        [protocol digitalWrite:kBuzzPin Value:HIGH];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [protocol digitalWrite:kBuzzPin Value:LOW];
        });
    } else {
        [protocol digitalWrite:kBuzzPin Value:LOW];
    }
}

- (void) lights:(int)segments
{
    if (segments < 1) {
        [protocol digitalWrite:kWheel1 Value:LOW];
    } else if (segments < 2) {
        [protocol digitalWrite:kWheel1 Value:HIGH];
    }
    
}
@end
