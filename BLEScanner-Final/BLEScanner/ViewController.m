//
//  ViewController.m
//  BLEScanner
//
//  Created by Michael Lehman on 9/26/14.
//  Copyright (c) 2014 Michael Lehman. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *verbositySelector;
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;
@property BOOL bluetoothOn;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@end

@implementation ViewController

-(bool)verboseMode
{
    return (self.verbositySelector.selectedSegmentIndex != 0);
}

-(void)tLog:(NSString *)msg
{
    self.outputTextView.text = [@"\r\n\r\n" stringByAppendingString:self.outputTextView.text];
    self.outputTextView.text = [msg stringByAppendingString:self.outputTextView.text];
    
}

- (IBAction)startScan:(id)sender
{
    if (!self.bluetoothOn)
    {
        [self tLog:@"Bluetooth is OFF"];
        return;
    }
    
    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self tLog:@"Bluetooth LE Device Scanner\r\n\r\nProgramming the Internet of Things for iOS"];
    self.bluetoothOn = NO;
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void) centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    [self tLog:[NSString stringWithFormat:@"Discovered %@, RSSI: %@\n",
                [advertisementData objectForKey:@"kCBAdvDataLocalName"], RSSI]];
    self.discoveredPeripheral = peripheral;
    
    if([self verboseMode])
        [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void) centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                  error:(NSError *)error
{
    [self tLog:@"Failed to connect"];
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if(error)
    {
        [self tLog:[error description]];
        return;
    }
    
    for(CBService *service in peripheral.services)
    {
        [self tLog:[NSString stringWithFormat:@"Discovered service: %@", [service description]]];
        [peripheral discoverCharacteristics:nil forService:service];
    }
}


-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        [self tLog:[error description]];
        return;
    }
    
    for(CBCharacteristic *characteristic in service.characteristics)
    {
        [self tLog:[NSString stringWithFormat:@"Characteristic found: %@", [characteristic description]]];
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]])
        {
            [peripheral setNotifyValue:YES
                     forCharacteristic:characteristic];
        }
    }

}

- (void) peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error
{
    if (error)
    {
        [self tLog:[error description]];
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value
                                                     encoding:NSUTF8StringEncoding];
    [self tLog:[NSString stringWithFormat:@"Characteristic updated: %@", stringFromData]];
    self.valueLabel.text = stringFromData;
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        [self tLog:@"Bluetooth OFF"];
        self.bluetoothOn = NO;
    }
    else
    {
        [self tLog:@"Bluetooth ON"];
        self.bluetoothOn = YES;
    }
}


@end
