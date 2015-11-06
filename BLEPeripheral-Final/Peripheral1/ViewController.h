//
//  ViewController.h
//  BLEPeripheral
//
//  Created by Michael Lehman on 4/6/14.
//  Copyright (c) 2014 Michael Lehman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController
<CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *transferCharacteristic;

#define SERVICE_UUID        @ "FFF0"
#define CHARACTERISTIC_UUID @ "FFF3"

@end
