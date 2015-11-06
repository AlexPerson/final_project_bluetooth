//
//  ViewController.h
//  BLEScanner
//
//  Created by Michael Lehman on 9/26/14.
//  Copyright (c) 2014 Michael Lehman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController
<
CBCentralManagerDelegate,
CBPeripheralDelegate
>
#define SERVICE_UUID        @ "FFF0"
#define CHARACTERISTIC_UUID @ "FFF3"


@end

