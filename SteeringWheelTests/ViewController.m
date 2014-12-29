//
//  ViewController.m
//  SteeringWheel
//
//  Created by Axel Roest on 28-12-14.
//  Copyright (c) 2014 Phluxus. All rights reserved.
//

#import "ViewController.h"

#define kUpdateFrequency	60.0


@interface ViewController ()
    
@property (weak, nonatomic) IBOutlet UISlider *accellSlider;
@property (weak, nonatomic) IBOutlet UISlider *brakeSlider;

@property (weak, nonatomic) IBOutlet UILabel *currentAccellerationLevel;
@property (weak, nonatomic) IBOutlet UILabel *currentBrakeLevel;
@property (weak, nonatomic) IBOutlet UILabel *maxAccellerationLevel;
@property (weak, nonatomic) IBOutlet UILabel *maxBrakeLevel;

@property (nonatomic, assign) double accelleration;
@property (nonatomic, assign) double brakeLimit;
@property (nonatomic, assign) double maxAccelleration;
@property (nonatomic, assign) double maxBrakeLimit;

@property (nonatomic, strong) NSNumber *brake;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) AccelerometerFilter *filter;
@property (nonatomic, strong) NSTimer *updateTimer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupMotionManager];
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
#pragma mark timers
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
    // send stuff over BLE
    
}

#pragma mark filters

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

@end
