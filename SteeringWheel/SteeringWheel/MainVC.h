//
//  MainVC.h
//  SteeringWheel
//
//  Created by Axel Roest on 29-12-14.
//  Copyright (c) 2014 Phluxus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"
#import "RBLDetailViewController.h"

@interface MainVC : UIViewController <BLEDelegate>
@property (strong, nonatomic) BLE *ble;

@end
