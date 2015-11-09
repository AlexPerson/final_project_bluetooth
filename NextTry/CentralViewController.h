//
//  CentralViewController.h
//  NextTry
//
//  Created by Alexander Person on 11/8/15.
//  Copyright © 2015 Alexander Person. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Device.h"
#import "DevicesTableViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralViewController : UIViewController

@property (nonatomic) Device *currentDevice;
@property (weak, nonatomic) NSString *test;
@property (strong, nonatomic) CBPeripheral          *selectedPeripheral;
@property (strong, nonatomic) CBCentralManager      *centralManager;

@end
