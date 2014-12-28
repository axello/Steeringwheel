//
//  ViewController.m
//  SteeringWheel
//
//  Created by Axel Roest on 28-12-14.
//  Copyright (c) 2014 Phluxus. All rights reserved.
//

#import "ViewController.h"
#import "AccelerometerFilter.h"

#define kUpdateFrequency	60.0


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISlider *accellerationSlider;
@property (weak, nonatomic) IBOutlet UISlider *breakSlider;

@property (weak, nonatomic) IBOutlet UILabel *currentAccellerationLevel;
@property (weak, nonatomic) IBOutlet UILabel *currentBreakLevel;

@property (nonatomic, assign) double accelleration;
@property (nonatomic, assign) double breakLimit;

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) AccelerometerFilter *filter;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupMotionManager];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.motionManager startAccelerometerUpdates];
}
- (void) viewWillDisappear:(BOOL)animated
{
    [self.motionManager stopAccelerometerUpdates];

}

- (void) setupMotionManager
{
    [self changeFilter:[LowpassFilter class]];

    // Create coremotion manager object
    CMMotionManager *motManager = [[CMMotionManager alloc] init];
    [motManager startAccelerometerUpdates];
    self.motionManager = motManager;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)setAccellerationSlider:(UISlider *)slider
{
    
}

- (IBAction)setBreakLimitSlider:(UISlider *)slider
{
    
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
