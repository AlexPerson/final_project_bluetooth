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
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MPMediaQuery.h>
#import "TPAACAudioConverter.h"



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
@property (nonatomic, retain) IBOutlet UILabel *sizeLabel;
@property (strong, nonatomic) NSData *exportedMusicData;
@property (nonatomic) TPAACAudioConverter *audioConverter;

@end



#define NOTIFY_MTU      150
#define EXPORT_NAME @"exported.caf"


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

- (void) mediaPicker: (MPMediaPickerController *) mediaPicker
   didPickMediaItems: (MPMediaItemCollection *) collection {
    NSLog(@"item picked");

    
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
    }
    
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
    NSString *exportPath = [documentsDirectoryPath
                            stringByAppendingPathComponent:EXPORT_NAME];
    NSLog (@"exportpath: %@", exportPath);
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath
                                                   error:nil];
    }
    NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
    NSLog (@"exportURL: %@", exportURL);
    AVAssetWriter *assetWriter =
    [AVAssetWriter assetWriterWithURL:exportURL
                             fileType:AVFileTypeCoreAudioFormat
                                error:&assetError];
//    [AVAssetWriter assetWriterWithURL:exportURL
//                             fileType:AVFileTypeAppleM4A
//                                error:&assetError];
//    
    NSLog(@"asset write: %@", assetWriter);
    if (assetError) {
        NSLog (@"error: %@", assetError);
        return;
    }
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary *outputSettings =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
     [NSNumber numberWithFloat:8000.0], AVSampleRateKey,
     [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
     [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)],
     AVChannelLayoutKey,
     [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
     [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
     [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
     [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
     nil];
    
    AVAssetWriterInput *assetWriterInput =
    [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                       outputSettings:outputSettings];
    NSLog(@"asset write input: %@", assetWriterInput);
    if ([assetWriter canAddInput:assetWriterInput]) {
        [assetWriter addInput:assetWriterInput];
    } else {
        NSLog (@"can't add asset writer input... die!");
        return;
    }
    assetWriterInput.expectsMediaDataInRealTime = NO;
    
    [assetWriter startWriting];
    [assetReader startReading];
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    NSLog(@"sound track: %@", soundTrack);
    CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime: startTime];
    NSLog(@"start time: %f", startTime);
    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue =
    dispatch_queue_create("mediaInputQueue", NULL);
    NSLog(@"media input queue: %@", mediaInputQueue);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue
                                            usingBlock: ^
     {
         while (assetWriterInput.readyForMoreMediaData) {
             CMSampleBufferRef nextBuffer =
             [assetReaderOutput copyNextSampleBuffer];
             if (nextBuffer) {
                 // append buffer
                 [assetWriterInput appendSampleBuffer: nextBuffer];
                 // update ui
                 convertedByteCount +=
                 CMSampleBufferGetTotalSampleSize (nextBuffer);
                 NSNumber *convertedByteCountNumber =
                 [NSNumber numberWithLong:convertedByteCount];
                 [self performSelectorOnMainThread:@selector(updateSizeLabel:)
                                        withObject:convertedByteCountNumber
                                     waitUntilDone:NO];
             } else {
                 // done!
                 [assetWriterInput markAsFinished];
                 [assetWriter finishWriting];
                 [assetReader cancelReading];
                 NSDictionary *outputFileAttributes =
                 [[NSFileManager defaultManager]
                  attributesOfItemAtPath:exportPath
                  error:nil];
                 NSLog (@"done. file size is %ld",
                        [outputFileAttributes fileSize]);
                 NSNumber *doneFileSize = [NSNumber numberWithLong:
                                           [outputFileAttributes fileSize]];
                 [self performSelectorOnMainThread:@selector(updateCompletedSizeLabel:)
                                        withObject:doneFileSize
                                     waitUntilDone:NO];
                 // release a lot of stuff
                 self.exportedMusicData = [NSData dataWithContentsOfURL:exportURL];
                 NSLog(@"exported music data length: %i", self.exportedMusicData.length);
//                 NSLog(@"exported music data: %@", self.exportedMusicData);
                 NSLog (@"bottom of convertTapped:");

                 break;
                 
             }
         }
     }];
    
    self.exportedMusicData = [NSData dataWithContentsOfURL:exportURL];
    
}


-(void) updateSizeLabel: (NSNumber*) convertedByteCountNumber {
    UInt64 convertedByteCount = [convertedByteCountNumber longValue];
    self.sizeLabel.text = [NSString stringWithFormat: @"%llu bytes converted", convertedByteCount];
}

-(void) updateCompletedSizeLabel: (NSNumber*) convertedByteCountNumber {
    UInt64 convertedByteCount = [convertedByteCountNumber longValue];
    self.sizeLabel.text = [NSString stringWithFormat: @"done. file size is %llu", convertedByteCount];
}

-(void) convertAudio
{
    if ( ![TPAACAudioConverter AACConverterAvailable] ) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Converting audio", @"")
                                    message:NSLocalizedString(@"Couldn't convert audio: Not supported on this device", @"")
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"OK", @""), nil] show];
        return;
    }
    
    // Register an Audio Session interruption listener, important for AAC conversion
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionInterrupted:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
    
    // Set up an audio session compatible with AAC conversion.  Note that AAC conversion is incompatible with any session that provides mixing with other device audio.
    NSError *error = nil;
    if ( ![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                           withOptions:0
                                                 error:&error] ) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Converting audio", @"")
                                    message:[NSString stringWithFormat:NSLocalizedString(@"Couldn't setup audio category: %@", @""), error.localizedDescription]
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"OK", @""), nil] show];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        return;
    }
    
    // Activate audio session
    if ( ![[AVAudioSession sharedInstance] setActive:YES error:NULL] ) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Converting audio", @"")
                                    message:[NSString stringWithFormat:NSLocalizedString(@"Couldn't activate audio category: %@", @""), error.localizedDescription]
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"OK", @""), nil] show];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        return;
        
    }
    
    NSArray *dirs = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
    NSString *exportPath = [documentsDirectoryPath
                            stringByAppendingPathComponent:EXPORT_NAME];
    NSLog(@"Compare export: %@", exportPath);
    
    NSArray *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.audioConverter = [[TPAACAudioConverter alloc] initWithDelegate:self
                                                                 source:exportPath
                                                            destination:[[documentsFolders objectAtIndex:0] stringByAppendingPathComponent:@"exported.m4a"]];
    
    
//        NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
//    NSString *exportPath = [documentsDirectoryPath
//                            stringByAppendingPathComponent:EXPORT_NAME];
//    NSLog (@"exportpath: %@", exportPath);
//    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
//        [[NSFileManager defaultManager] removeItemAtPath:exportPath
//                                                   error:nil];
//    }
//    NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
    
    
    
//    ((UIButton*)sender).enabled = NO;
//    [self.spinner startAnimating];
//    self.progressView.progress = 0.0;
//    self.progressView.hidden = NO;
    [_audioConverter start];

}
//
//
#pragma mark - Audio converter delegate

-(void)AACAudioConverter:(TPAACAudioConverter *)converter didMakeProgress:(CGFloat)progress {
//    self.progressView.progress = progress;
    NSLog(@"didMakeProgress called");
}
//
-(void)AACAudioConverterDidFinishConversion:(TPAACAudioConverter *)converter {
//    self.progressView.hidden = YES;
//    [self.spinner stopAnimating];
//    self.convertButton.enabled = YES;
//    self.playConvertedButton.enabled = YES;
//    self.emailConvertedButton.enabled = YES;
//    self.audioConverter = nil;
    NSArray *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString* converted = [[documentsFolders objectAtIndex:0] stringByAppendingPathComponent:@"exported.m4a"];
    NSData * contents = [NSData dataWithContentsOfMappedFile:converted];
    NSLog(@"converted song size: %i", contents.length);
    
    NSLog(@"conversion finished");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
//
-(void)AACAudioConverter:(TPAACAudioConverter *)converter didFailWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Converting audio", @"")
                                message:[NSString stringWithFormat:NSLocalizedString(@"Couldn't convert audio: %@", @""), [error localizedDescription]]
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:NSLocalizedString(@"OK", @""), nil] show];
//    self.convertButton.enabled = YES;
    self.audioConverter = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
//
//
#pragma mark - Audio session interruption

- (void)audioSessionInterrupted:(NSNotification*)notification {
    AVAudioSessionInterruptionType type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
    
    if ( type == AVAudioSessionInterruptionTypeEnded) {
        [[AVAudioSession sharedInstance] setActive:YES error:NULL];
        if ( _audioConverter ) [_audioConverter resume];
    } else if ( type == AVAudioSessionInterruptionTypeBegan ) {
        if ( _audioConverter ) [_audioConverter interrupt];
    }
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
    
//    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.url error:&error];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:self.exportedMusicData error:&error];
    if (error != nil) {
        NSAssert(error ==nil, @"");
    }
    
    [self.audioPlayer setVolume:self.volumeSlider.value];
    [self.audioPlayer prepareToPlay];
    
}


- (IBAction)playButtonPressed:(id)sender {
    NSLog(@"play Button Pressed");
    [self convertAudio];
//    [self performSelectorInBackground:@selector(convertAudio) withObject:nil];
    [self setupAudio];
    BOOL played = [self.audioPlayer play];
    if (!played) {
        NSLog(@"Error");
    }
//    NSString * musicPath = [[NSBundle mainBundle] pathForResource:@"SoManyTimes" ofType:@"mp3"];
//    self.musicData = [NSData dataWithContentsOfFile:musicPath];
//    _dataToSend = _musicData;
    NSLog(@"exported music data: %@", self.exportedMusicData);
     NSLog(@"exported music data: %i", self.exportedMusicData.length);
    NSArray *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* converted = [[documentsFolders objectAtIndex:0] stringByAppendingPathComponent:@"exported.m4a"];
    NSData * contents = [NSData dataWithContentsOfMappedFile:converted];
//    self.musicData = [NSData dataWithContentsOfURL:self.url];
//    NSLog(@"musicData: %@", self.musicData);
//    _dataToSend = self.exportedMusicData;
    _dataToSend = contents;
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
    [self sendData];
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
    [self sendData];
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
