//
//  SteeringVC.h
//  SteeringWheel
//
//  Created by Axel Roest on 28-12-14.
//  Copyright (c) 2014 Phluxus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccelerometerFilter.h"
#import "BLE.h"

@interface SteeringVC : UIViewController

@property (strong, nonatomic) BLE *ble;

-(void) processData:(uint8_t *) data length:(uint8_t) length;

@end

