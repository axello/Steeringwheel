//
//  MainVC.m
//  SteeringWheel
//
//  Created by Axel Roest on 29-12-14.
//  Copyright (c) 2014 Phluxus. All rights reserved.
//

#import "MainVC.h"
#import "SteeringVC.h"

NSString * const  UUIDPrefKey = @"UUIDPrefKey";
NSString * const  UUIDIdentifierPrefKey = @"UUIDIdentifierPrefKey";

const int kScanTimeout =   10;

@interface MainVC () {
    BOOL showAlert;
    bool isFindingLast;
    IBOutlet UIActivityIndicatorView *activityScanning;

}

@property (strong,nonatomic) NSString *lastUUID;
@property (strong, nonatomic) NSUUID *identifier;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) NSMutableArray *mDevices;
@property (strong, nonatomic) NSMutableArray *mDevicesName;
@property (strong, nonatomic) SteeringVC *steeringVC;

- (IBAction)scan:(id)sender;
- (IBAction)connect:(id)sender;

@end

@implementation MainVC
@synthesize ble;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.ble = [[BLE alloc] init];
    [self.ble controlSetup];
    self.ble.delegate = self;

    self.mDevices = [[NSMutableArray alloc] init];
    self.mDevicesName = [[NSMutableArray alloc] init];

    //Retrieve saved UUID from system
    self.lastUUID = [[NSUserDefaults standardUserDefaults] objectForKey:UUIDPrefKey];
    NSString *id = [[NSUserDefaults standardUserDefaults] objectForKey:UUIDIdentifierPrefKey];
    self.identifier = [[NSUUID alloc] initWithUUIDString:id];
    [self.scanButton setEnabled:YES];

    if ([self.identifier.UUIDString isEqualToString:@""])
    {
        [self.connectButton setEnabled:NO];
    }
    else
    {
        [self.connectButton setEnabled:YES];
        [self performSelector:@selector(connect:) withObject:self afterDelay:1.0];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)connect:(id)sender
{
    if (ble.peripherals) {
        ble.peripherals = nil;
    }
    
    [self.scanButton setEnabled:NO];
    [self.connectButton setEnabled:NO];
    [ble findBLEPeripherals:kScanTimeout];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    isFindingLast = true;
    [activityScanning startAnimating];
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDevicesVC"])
    {
        RBLDetailViewController *vc = [segue destinationViewController];
        vc.BLEDevices = self.mDevices;
        vc.BLEDevicesName = self.mDevicesName;
        vc.ble = ble;
    }
    else if ([[segue identifier] isEqualToString:@"showSteeringVC"])
    {
        self.steeringVC = [segue destinationViewController];
        self.steeringVC.ble = ble;
    }
}

#pragma mark - RBLEController
- (IBAction)scan:(id)sender
{
    if (ble.activePeripheral)
        if(ble.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[ble CM] cancelPeripheralConnection:[ble activePeripheral]];
            return;
        }
    
    if (ble.peripherals)
        ble.peripherals = nil;
    
    [self.scanButton setEnabled:NO];
    [self.connectButton setEnabled:NO];
    [ble findBLEPeripherals:kScanTimeout];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)kScanTimeout target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    isFindingLast = false;
    [activityScanning startAnimating];
}


-(void) connectionTimer:(NSTimer *)timer
{
    showAlert = YES;
    
    self.lastUUID = [[NSUserDefaults standardUserDefaults] objectForKey:UUIDPrefKey];
    
    if ([self.lastUUID isEqualToString:@""])
    {
        [self.connectButton setEnabled:NO];
    }
    else
    {
        [self.connectButton setEnabled:YES];
    }
    
    if (ble.peripherals.count > 0)
    {
        if(isFindingLast)
        {
            int i;
            for (i = 0; i < ble.peripherals.count; i++)
            {
                CBPeripheral *p = [ble.peripherals objectAtIndex:i];
                
                
                if (p.identifier != NULL)
                {
                    //Comparing UUIDs and call connectPeripheral is matched
                    if([self.identifier.UUIDString isEqualToString:[p.identifier UUIDString]])
                    {
                        showAlert = NO;
                        [ble connectPeripheral:p];
                    }
                }
            }
        }
        else
        {
            [self.mDevices removeAllObjects];
            [self.mDevicesName removeAllObjects];
            
            int i;
            for (i = 0; i < ble.peripherals.count; i++)
            {
                CBPeripheral *p = [ble.peripherals objectAtIndex:i];
                
                if (p.identifier != NULL)
                {
                    [self.mDevices insertObject:[p.identifier UUIDString] atIndex:i];
                    if (p.name != nil) {
                        [self.mDevicesName insertObject:p.name atIndex:i];
                    } else {
                        [self.mDevicesName insertObject:@"RedBear Device" atIndex:i];
                    }
                }
                else
                {
                    [self.mDevices insertObject:@"NULL" atIndex:i];
                    [self.mDevicesName insertObject:@"RedBear Device" atIndex:i];
                }
            }
            showAlert = NO;
            [self performSegueWithIdentifier:@"showDevicesVC" sender:self];
        }
    }
    
    if (showAlert == YES) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"No BLE Device(s) found."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    [self.scanButton setEnabled:YES];
    [activityScanning stopAnimating];
}

#pragma mark -

-(void) bleDidConnect
{
    NSLog(@"->DidConnect");
    
//    self.lastUUID = [self getUUIDString:ble.activePeripheral.UUID];
//    [[NSUserDefaults standardUserDefaults] setObject:self.lastUUID forKey:UUIDPrefKey];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    //     self.lastUUID = [[NSUserDefaults standardUserDefaults] objectForKey:UUIDPrefKey];

    self.identifier = ble.activePeripheral.identifier;
    [[NSUserDefaults standardUserDefaults] setObject:self.identifier.UUIDString forKey:UUIDIdentifierPrefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if ([self.identifier.UUIDString isEqualToString:@""]) {
        [self.connectButton setEnabled:NO];
    } else {
        [self.connectButton setEnabled:YES];
    }
    
    [activityScanning stopAnimating];
    [self performSegueWithIdentifier:@"showSteeringVC" sender:self];
}

- (void)bleDidDisconnect
{
    NSLog(@"->DidDisconnect");
    
    [activityScanning stopAnimating];
    [self.navigationController popToRootViewControllerAnimated:true];
}

-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
#if defined(MV_DEBUG)
    NSLog(@"->DidReceiveData");
#endif
    
    if (self.steeringVC != nil)
    {
        [self.steeringVC processData:data length:length];
    }
}

-(void) bleDidUpdateRSSI:(NSNumber *) rssi
{
}

@end
