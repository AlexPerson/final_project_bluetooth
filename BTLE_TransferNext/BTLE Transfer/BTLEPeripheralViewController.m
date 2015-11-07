/*
 
 File: LEPeripheralViewController.m
 
 Abstract: Interface to allow the user to enter data that will be
 transferred to a version of the app in Central Mode, when it is brought
 close enough.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc.
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "BTLEPeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPMediaPickerController.h>
#import <MediaPlayer/MPMediaQuery.h>



@interface BTLEPeripheralViewController () <CBPeripheralManagerDelegate, UITextViewDelegate, MPMediaPickerControllerDelegate>
@property (strong, nonatomic) IBOutlet UITextView       *textView;
@property (strong, nonatomic) IBOutlet UISwitch         *advertisingSwitch;
@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (strong, nonatomic) NSData *musicData;
@property (strong, nonatomic) NSURL *url;
@end



#define NOTIFY_MTU      20



@implementation BTLEPeripheralViewController



#pragma mark - View Lifecycle



- (void)viewDidLoad
{
    [super viewDidLoad];

    // Start up the CBPeripheralManager
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    NSLog(@"Peripherial viewcontroller loaded");


//    [self setupAudio];
}


- (void) mediaPicker: (MPMediaPickerController *) mediaPicker
   didPickMediaItems: (MPMediaItemCollection *) collection {
    
    [self dismissModalViewControllerAnimated: YES];
    NSLog(@"hihihihi");
    NSArray *songs = [collection items];
    for (MPMediaItem *song in songs) {
        NSString *songTitle =
        [song valueForProperty: MPMediaItemPropertyTitle];
        NSLog (@"\t\t%@", songTitle);
        NSString *songType =
        [song valueForProperty: MPMediaItemPropertyMediaType];
        NSLog (@"\t\t%@", songType);
        
        //setting self url to be the URL of the current song.
        self.url = [song valueForProperty:MPMediaItemPropertyAssetURL];
        
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:self.url options:nil];
        NSLog(@"song asset %@", songAsset);
        NSError *assetError = nil;
        AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&assetError];
        if (assetError) {
            NSLog (@"error: %@", assetError);
            return;
        }
        AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks: songAsset.tracks audioSettings:nil];
        if (![assetReader canAddOutput: assetReaderOutput]) {
            NSLog(@"can't add reader output... die!");
            return;
        }
        [assetReader addOutput: assetReaderOutput];
        NSArray *dirs = NSSearchPathForDirectoriesInDomains
        (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
//        NSString *exportPath = [[documentsDirectoryPath
//                                 stringByAppendingPathComponent:EXPORT_NAME]
//                                retain];
//        if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
//            [[NSFileManager defaultManager] removeItemAtPath:exportPath
//                                                       error:nil];
//        }
//        NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
//        
//        AVAssetWriter *assetWriter =
//        [AVAssetWriter assetWriterWithURL:exportURL
//                                  fileType:AVFileTypeCoreAudioFormat
//                                     error:&assetError];
//        if (assetError) {
//            NSLog (@"error: %@", assetError);
//            return;
//        }
    }
    [self setupAudio];
    NSLog(@"setup audio!!!");
}






- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker
{
    [self dismissModalViewControllerAnimated: YES];
//      [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)showMediaPicker:(id)sender {
    MPMediaPickerController *picker = [[MPMediaPickerController alloc]
                                       initWithMediaTypes: MPMediaTypeAnyAudio];                   // 1
    
    [picker setDelegate: self];                                         // 2
    [picker setAllowsPickingMultipleItems: YES];                        // 3
    picker.prompt =
    NSLocalizedString (@"Add songs to play",
                       "Prompt in media item picker");
    
    [self presentModalViewController: picker animated: YES];    // 4
    
}


- (void) setupAudio {
    NSLog(@"Inside setupAudio");
    NSError *error;
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error != nil) {
        NSAssert(error ==nil, @"");
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error != nil) {
        NSAssert(error ==nil, @"");
    }
    
//    NSURL *soundUrl = [[NSBundle mainBundle] URLForResource:@"SoManyTimes"
//                                              withExtension:@"mp3"];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.url error:&error];
    
//    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:self.song error:&error];
    if (error != nil) {
        NSAssert(error ==nil, @"");
    }
    
    [self.audioPlayer setVolume:self.volumeSlider.value];
    [self.audioPlayer prepareToPlay];
    
}


- (IBAction)playButtonPressed:(id)sender {
    BOOL played = [self.audioPlayer play];
    if (!played) {
        NSLog(@"Error");
    }
//    NSString * musicPath = [[NSBundle mainBundle] pathForResource:@"SoManyTimes" ofType:@"mp3"];
//    self.musicData = [NSData dataWithContentsOfFile:musicPath];
//    _dataToSend = _musicData;
    NSLog(@"file url: %@", self.url);
    self.musicData = [NSData dataWithContentsOfURL:self.url];
    NSLog(@"musicData: %@", self.musicData);
    _dataToSend = self.musicData;
    NSLog(@"data to send, %@", _dataToSend);
    [self sendData];
    NSLog(@"data sent");
}

- (IBAction)stopButtonPressed:(id)sender {
    [self.audioPlayer stop];
}

- (IBAction)volumeSliderChanged:(UISlider*)sender {
    [self.audioPlayer setVolume:sender.value];
}



- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [self.peripheralManager stopAdvertising];

    [super viewWillDisappear:animated];
}



#pragma mark - Peripheral Methods



/** Required protocol method.  A full app should take care of all the possible states,
 *  but we're just waiting for  to know when the CBPeripheralManager is ready
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");
    
    // ... so build our service.
    
    // Start with the CBMutableCharacteristic
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                      properties:CBCharacteristicPropertyNotify
                                                                           value:nil
                                                                     permissions:CBAttributePermissionsReadable];

    // Then the service
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
                                                                        primary:YES];
    
    // Add the characteristic to the service
    transferService.characteristics = @[self.transferCharacteristic];
    
    // And add it to the peripheral manager
    [self.peripheralManager addService:transferService];
}


/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    // Get the data
//    self.dataToSend = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
//    self.dataToSend = self.musicData;
    // Reset the index
    self.sendDataIndex = 0;
    
    // Start sending
//    [self sendData];
}


/** Recognise when the central unsubscribes
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
}


/** Sends the next amount of data to the connected central
 */
- (void)sendData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
}


/** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *  This is to ensure that packets will arrive in the order they are sent
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    // Start sending again
//    [self sendData];
}



#pragma mark - TextView Methods



/** This is called when a change happens, so we know to stop advertising
 */
- (void)textViewDidChange:(UITextView *)textView
{
    // If we're already advertising, stop
    if (self.advertisingSwitch.on) {
        [self.advertisingSwitch setOn:NO];
        [self.peripheralManager stopAdvertising];
    }
}


/** Adds the 'Done' button to the title bar
 */
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // We need to add this manually so we have a way to dismiss the keyboard
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard)];
    self.navigationItem.rightBarButtonItem = rightButton;
}


/** Finishes the editing */
- (void)dismissKeyboard
{
    [self.textView resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}




#pragma mark - Switch Methods



/** Start advertising
 */
- (IBAction)switchChanged:(id)sender
{
    if (self.advertisingSwitch.on) {
        // All we advertise is our service's UUID
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
    }
    
    else {
        [self.peripheralManager stopAdvertising];
    }
}


@end
