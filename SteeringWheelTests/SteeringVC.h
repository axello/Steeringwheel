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
#import "RBLProtocol.h"

typedef enum : NSUInteger {
    kWheelSegmentOff,
    kWheelSegment1,
    kWheelSegment2,
    kWheelSegment3,
    kWheelSegment4,
    kWheelSegment5
} kWheelSegments;

@interface SteeringVC : UIViewController <ProtocolDelegate>

@property (strong, nonatomic) BLE *ble;
@property (strong, nonatomic) RBLProtocol *protocol;

-(void) processData:(uint8_t *) data length:(uint8_t) length;

@end

