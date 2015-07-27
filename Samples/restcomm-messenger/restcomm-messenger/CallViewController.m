/*
 * TeleStax, Open Source Cloud Communications
 * Copyright 2011-2015, Telestax Inc and individual contributors
 * by the @authors tag.
 *
 * This program is free software: you can redistribute it and/or modify
 * under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 * For questions related to commercial use licensing, please contact sales@telestax.com.
 *
 */

//#include <unistd.h>

#import "CallViewController.h"
#import "RestCommClient.h"
//#import "TabBarController.h"

@interface CallViewController ()
//@property (weak, nonatomic) IBOutlet UITextField *sipMessageText;
//@property (weak, nonatomic) IBOutlet UITextField *sipUriText;
//@property (weak, nonatomic) IBOutlet UITextView *sipDialogText;
//@property (weak, nonatomic) IBOutlet UIButton *answerButton;
@property (weak, nonatomic) IBOutlet UISwitch *muteSwitch;
@end

@implementation CallViewController


/*
- (instancetype)initWithDevice:(RCDevice*)device andParams:(NSMutableDictionary *)params
{
    if (self = [super init]) {
        self.device = device;
        self.parameters = params;
    }
    return self;
}
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareSounds];
    self.muteSwitch.enabled = false;
    //self.muteSwitch.isOn = false;

    //self.connection = nil;
    //self.pendingIncomingConnection = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([[self.parameters valueForKey:@"invoke-view-type"] isEqualToString:@"make-call"]) {
        // call the other party
        if (self.connection) {
            NSLog(@"Connection already ongoing");
            return;
        }
        self.connection = [self.device connect:self.parameters delegate:self];
    }
    if ([[self.parameters valueForKey:@"invoke-view-type"] isEqualToString:@"receive-call"]) {
        [self.ringingPlayer play];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)answerPressed:(id)sender
{
    if (self.ringingPlayer.isPlaying) {
        [self.ringingPlayer stop];
        self.ringingPlayer.currentTime = 0.0;
    }
    
    if (self.pendingIncomingConnection) {
        [self.pendingIncomingConnection accept];
        self.connection = self.pendingIncomingConnection;
    }
}

- (IBAction)declinePressed:(id)sender
{
    if (self.ringingPlayer.isPlaying) {
        [self.ringingPlayer stop];
        self.ringingPlayer.currentTime = 0.0;
    }
    
    if (self.pendingIncomingConnection) {
        // reject the pending RCConnection
        [self.pendingIncomingConnection reject];
        self.pendingIncomingConnection = nil;
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    }
}

- (IBAction)hangUpPressed:(id)sender
{
    [self disconnect];
}

- (IBAction)cancelPressed:(id)sender
{
    if (self.connection) {
        [self.connection disconnect];
        self.connection = nil;
        self.pendingIncomingConnection = nil;
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    }
}

- (void)disconnect
{
    if (self.connection) {
        [self.connection disconnect];
        
        self.connection = nil;
        self.pendingIncomingConnection = nil;
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    }
}

// ---------- Delegate methods for RC Connection
// not implemented yet
- (void)connection:(RCConnection*)connection didFailWithError:(NSError*)error
{
    
}

// optional
// 'ringing' for outgoing connections
- (void)connectionDidStartConnecting:(RCConnection*)connection
{
    NSLog(@"connectionDidStartConnecting");
}

- (void)connectionDidConnect:(RCConnection*)connection
{
    NSLog(@"connectionDidConnect");
    self.muteSwitch.enabled = true;
}

- (void)connectionDidCancel:(RCConnection*)connection
{
    NSLog(@"connectionDidCancel");
    if (self.ringingPlayer.isPlaying) {
        [self.ringingPlayer stop];
        self.ringingPlayer.currentTime = 0.0;
    }
    
    if (self.pendingIncomingConnection) {
        self.pendingIncomingConnection = nil;
        self.connection = nil;
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    }
}

- (void)connectionDidDisconnect:(RCConnection*)connection
{
    NSLog(@"connectionDidDisconnect");
    self.connection = nil;
    self.pendingIncomingConnection = nil;
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

- (void)connectionDidGetDeclined:(RCConnection*)connection
{
    NSLog(@"connectionDidGetDeclined");
    self.connection = nil;
    self.pendingIncomingConnection = nil;
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:nil];
}

- (IBAction)toggleMute:(id)sender
{
    // if we aren't in connected state it doesn't make any sense to mute
    if (self.connection.state != RCConnectionStateConnected) {
        return;
    }
    
    UISwitch * muteSwitch = sender;
    if (muteSwitch.isOn) {
        self.connection.muted = true;
    }
    else {
        self.connection.muted = false;
    }
}

- (void)prepareSounds
{
    // message
    NSString * filename; // = @"message.mp3";
    // we are assuming the extension will always be the last 3 letters of the filename
    NSString * file;  // = [[NSBundle mainBundle] pathForResource:[filename substringToIndex:[filename length] - 3 - 1]
                      //                                ofType:[filename substringFromIndex:[filename length] - 3]];
    
    NSError *error;
    /*
    self.messagePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&error];
    if (!self.messagePlayer) {
        NSLog(@"Error: %@", [error description]);
        return;
    }
     */
    
    // ringing
    filename = @"ringing.mp3";
    // we are assuming the extension will always be the last 3 letters of the filename
    file = [[NSBundle mainBundle] pathForResource:[filename substringToIndex:[filename length] - 3 - 1]
                                           ofType:[filename substringFromIndex:[filename length] - 3]];
    
    self.ringingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&error];
    if (!self.ringingPlayer) {
        NSLog(@"Error: %@", [error description]);
        return;
    }
    self.ringingPlayer.numberOfLoops = -1; // repeat forever

    // calling
    filename = @"calling.mp3";
    // we are assuming the extension will always be the last 3 letters of the filename
    file = [[NSBundle mainBundle] pathForResource:[filename substringToIndex:[filename length] - 3 - 1]
                                           ofType:[filename substringFromIndex:[filename length] - 3]];
    
    self.callingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&error];
    if (!self.callingPlayer) {
        NSLog(@"Error: %@", [error description]);
        return;
    }
    self.callingPlayer.numberOfLoops = -1; // repeat forever
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end
