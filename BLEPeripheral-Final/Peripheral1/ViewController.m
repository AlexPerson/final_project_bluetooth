//
//  ViewController.m
//  BLEPeripheral
//
//  Created by Michael Lehman on 4/6/14.
//  Copyright (c) 2014 Michael Lehman. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@property (weak, nonatomic) IBOutlet UIButton *startAdvertisingButton;
@property BOOL bluetoothOn;
@property BOOL advertising;
@property BOOL initialized;
@property (strong, nonatomic) NSDictionary *advertisingData;
@end

@implementation ViewController

-(void)segmentedControlChanged:(NSObject *)sender
{
    [self sendData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.bluetoothOn = NO;
    self.advertising = NO;
    self.initialized = NO;
    [self.segControl addTarget:self
                        action:@selector(segmentedControlChanged:)
              forControlEvents:UIControlEventValueChanged];
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state != CBPeripheralManagerStatePoweredOn)
    {
        self.bluetoothOn = NO;
    }
    else
    {
        self.bluetoothOn = YES;
    }
}

- (IBAction)startStopAdvertising:(id)sender
{
    if (self.advertising)
    {
        self.advertising = NO;
        [self.peripheralManager stopAdvertising];
        return;
    }
    
    if (!self.initialized)
    {
        self.transferCharacteristic = [[CBMutableCharacteristic alloc]
                                       initWithType:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]
                                       properties:CBCharacteristicPropertyNotify |
                                       CBCharacteristicPropertyRead
                                       value:nil
                                       permissions:CBAttributePermissionsReadable];
    
        CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID
                                                                                    UUIDWithString:SERVICE_UUID]
                                                                           primary:YES];
        
        transferService.characteristics = @[self.transferCharacteristic];
        
        [self.peripheralManager addService:transferService];
        self.advertisingData =
        @{CBAdvertisementDataLocalNameKey : @"BLEPeripheral",
          CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:SERVICE_UUID]]};
    
    }
    
    [self.peripheralManager startAdvertising:self.advertisingData];

}

-(void)sendData
{
    NSString *dataToSend;
    
    if (self.segControl.selectedSegmentIndex == 0)
        dataToSend = @"0x0101";
    else
        dataToSend = @"0x0202";
    
    NSData *chunk = [dataToSend dataUsingEncoding:NSStringEncodingConversionExternalRepresentation];
    
    [self.peripheralManager updateValue:chunk
                      forCharacteristic:self.transferCharacteristic
                   onSubscribedCentrals:nil];
}

-(void) peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self sendData];
}

-(void) peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    [self sendData];
}



@end
