//
//  DevicesTableViewController.m
//  NextTry
//
//  Created by Alexander Person on 11/8/15.
//  Copyright © 2015 Alexander Person. All rights reserved.
//

#import "DevicesTableViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import "TransferService.h"

@interface DevicesTableViewController () <CBCentralManagerDelegate, CBPeripheralDelegate> {
    NSMutableArray *discoveredPeripheralDevices;
}

@property (strong, nonatomic) IBOutlet UITextView   *textview;
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;
@property (readonly) CBPeripheralState state;


@end

@implementation DevicesTableViewController

// Was used to display device table name in menu and central view
//{NSMutableArray *discoveredPeripheralDevices;}
// As was this viewDidLoad method
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//    
//    discoveredPeripheralDevices = [[NSMutableArray alloc] init];
//    
//    Device *discoveredPeripheralDevice = [[Device alloc] init];
//    discoveredPeripheralDevice.name = @"Alexander's iPhone";
//    discoveredPeripheralDevice.UUID = @"123456789";
//    
//    [discoveredPeripheralDevices addObject:discoveredPeripheralDevice];
//    
//}

#pragma mark - View Lifecycle



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start up the CBCentralManager
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // And somewhere to store the incoming data
    _data = [[NSMutableData alloc] init];
    
    // create array for discovered device objects
    discoveredPeripheralDevices = [[NSMutableArray alloc] init];
    
    NSLog(@"View loaded");

}



#pragma mark - Central Methods


/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        // In a real app, you'd deal with all the states correctly
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...
    
    // ... so start scanning
    [self scan];
    
}

- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    
    NSLog(@"Scanning started");
}



/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        return;
    }
    
    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    if (RSSI.integerValue < -35) {
        return;
    }
    
//    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    // Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral) {
        
        // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        // Check if our list of discovered devices already contains the current peripheral.
        // If not, add it in.
        if (![discoveredPeripheralDevices containsObject:peripheral]) {
            [discoveredPeripheralDevices addObject:peripheral];
            [self.tableView reloadData];
            NSLog(@"%@", discoveredPeripheralDevices[0]);
        }
        
        // And connect
//        NSLog(@"Connecting to peripheral %@", peripheral);
//        [self.centralManager connectPeripheral:peripheral options:nil];
        
        
    }

}


//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    return 1;
//}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return discoveredPeripheralDevices.count;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    CBPeripheral *current = [discoveredPeripheralDevices objectAtIndex:indexPath.row];
    NSLog(@"new added cell is %@", [current name]);
    cell.textLabel.text = [current name];
    
    return cell;
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    CentralViewController *cvc = [segue destinationViewController];
    //Pass the selected object to the new veiw controller.
    // What's the selected cell?
    NSIndexPath *path = [self.tableView indexPathForSelectedRow];
    CBPeripheral *cd = discoveredPeripheralDevices[path.row];
//    NSLog(@"Connecting to peripheral %@", cd);
//    [self.centralManager connectPeripheral:cd options:nil];
    cvc.selectedPeripheral = cd;
//    cvc.centralManager = self.centralManager;
}

@end
