/*
 FlomioPlugin.m
 Uses Flomio SDK version 2.0
*/

#import "FlomioPlugin.h"

@implementation FlomioPlugin

/** Initialise the plugin */
- (void)init:(CDVInvokedUrlCommand*)command
{
    readerManager = [FmSessionManager sharedManager];
    readerManager.delegate = self;
    
    // Initialise strings
    self->selectedDeviceType = @"null";
    self->didFindATagUUID_callbackId = @"null";
    self->readerStatusChange_callbackId = @"null";
    self->apduResponse_callbackId = @"null";
    self->deviceConnected_callbackId = @"null";
    self->readerTable = [NSMutableDictionary dictionary];
    
    // Set SDK configuration and update reader settings
    readerManager.scanPeriod = [NSNumber numberWithInteger:500]; // in ms
    readerManager.scanSound = [NSNumber numberWithBool:YES]; // play scan sound
    
    // Stop reader scan when the app becomes inactive
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inactive) name:UIApplicationDidEnterBackgroundNotification object:nil];
    // Start reader scan when the app becomes active
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(active) name:UIApplicationDidBecomeActiveNotification object:nil];
}

/** Update settings for a particular reader */
- (void)setReaderSettings:(CDVInvokedUrlCommand*)command
{
    NSString* scanPeriod = [command.arguments objectAtIndex:0];
    NSString* scanSound = [command.arguments objectAtIndex:1];
    
    NSString* callbackId = command.callbackId;
    [self setScanPeriod:[NSString stringWithFormat:@"%@", scanPeriod] :callbackId];
    [self toggleScanSound:scanSound :callbackId];
}

/** Retrieve settings for a particular reader */
- (void)getReaderSettings:(CDVInvokedUrlCommand *)command
{
	dispatch_async(dispatch_get_main_queue(), ^{
	    NSArray* settings = @[self->selectedDeviceType, readerManager.scanPeriod, readerManager.scanSound];
	    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:settings];
	    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	});
}

/** Stops active readers of the current type then starts readers of the new type */
- (void)selectDeviceType:(CDVInvokedUrlCommand*)command
{
    [readerManager stopReaders];
    NSString* deviceType = [command.arguments objectAtIndex:0];
    deviceType = [deviceType stringByReplacingOccurrencesOfString:@" " withString:@""]; // remove whitespace
    
    if ([[deviceType lowercaseString] isEqualToString:@"flojack-bzr"])
    {
        self->selectedDeviceType = @"flojack-bzr";
        readerManager.selectedDeviceType = kFlojackBzr;
    }
    else if ([[deviceType lowercaseString] isEqualToString:@"flojack-msr"])
    {
        self->selectedDeviceType = @"flojack-msr";
        readerManager.selectedDeviceType = kFlojackMsr;
    }
    else if ([[deviceType lowercaseString] isEqualToString:@"floble-emv"])
    {
        self->selectedDeviceType = @"floble-emv";
        readerManager.selectedDeviceType = kFloBleEmv;
    }
    else if ([[deviceType lowercaseString] isEqualToString:@"floble-plus"])
    {
        self->selectedDeviceType = @"floble-plus";
        readerManager.selectedDeviceType = kFloBlePlus;
    }
    else
    {
        self->selectedDeviceType = @"null";
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Enter 'FloJack-BZR', 'FloJack-MSR', 'FloBLE-EMV' or 'FloBLE-Plus' only"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    
    [readerManager startReaders];
}

/** Starts readers polling for tags */
- (void)startReader:(CDVInvokedUrlCommand*)command
{
    self->didFindATagUUID_callbackId = command.callbackId;
    NSString* deviceId = [command.arguments objectAtIndex:0];
    deviceId = [deviceId stringByReplacingOccurrencesOfString:@" " withString:@""]; // remove whitespace
    
    if ([self->selectedDeviceType isEqualToString:@"null"])
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Select a reader type first"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self->didFindATagUUID_callbackId];
    }
    else if ([[deviceId lowercaseString] isEqualToString:@"all"])
    {
        [readerManager startReaders]; // start all active readers
    }
    else
    {
        // start a specific reader
    }
}

/** Stops readers polling for tags */
- (void)stopReader:(CDVInvokedUrlCommand*)command
{
    NSString* deviceId = [command.arguments objectAtIndex:0];
    deviceId = [deviceId stringByReplacingOccurrencesOfString:@" " withString:@""]; // remove whitespace
    
    if ([self->selectedDeviceType isEqualToString:@"null"])
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Select a reader type first"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else if ([[deviceId lowercaseString] isEqualToString:@"all"])
    {
        [readerManager stopReaders]; // stop all active readers
    }
    else
    {
        // stop a specific reader
    }
}

/** Send an APDU to a specific reader */
- (void)sendApdu:(CDVInvokedUrlCommand *)command
{
    NSString* deviceId = [command.arguments objectAtIndex:0];
    NSString* apdu = [command.arguments objectAtIndex:1];
    
    if (![self validateDeviceId:deviceId])
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Enter a valid device ID"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else
    {
        self->apduResponse_callbackId = command.callbackId;
        
        for (FmDevice *device in self->connectedDevices)
        {
            if (device.device == deviceId)
            {
                [device sendApduCommand:apdu];
                break;
            }
        }
    }
}

- (void)setDeviceConnectCallback:(CDVInvokedUrlCommand*)command
{
	self->deviceConnected_callbackId = command.callbackId;
}

////////////////////// INTERNAL FUNCTIONS /////////////////////////

/** Validates device UIDs */
- (BOOL)validateDeviceId:(NSString *)deviceId
{
    deviceId = [deviceId stringByReplacingOccurrencesOfString:@" " withString:@""];  // remove whitespace
    
    // TODO: input validation
    return TRUE;
}

/** Set the scan period (in ms) */
- (void)setScanPeriod:(NSString*)periodString :(NSString*)callbackId;
{
    periodString = [periodString stringByReplacingOccurrencesOfString:@" " withString:@""];  // remove whitespace
    
    if ([[periodString lowercaseString] isEqualToString:@"unchanged"])
    {
        return;
    }
    
    int period = [periodString intValue];
    if (period > 0)
    {
        readerManager.scanPeriod = [NSNumber numberWithInteger:period];
    }
    else
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Scan period must be > 0"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }
}

/** Toggle on/off scan sound */
- (void)toggleScanSound:(NSString*)toggleString :(NSString*)callbackId;
{
    NSString* toggle = [toggleString stringByReplacingOccurrencesOfString:@" " withString:@""]; // remove whitespace
    if ([[toggle lowercaseString] isEqualToString:@"unchanged"])
    {
        return;
    }
    
    if ([[toggle lowercaseString] isEqualToString:@"true"])
    {
        readerManager.scanSound = [NSNumber numberWithBool:YES];
    }
    else if ([[toggle lowercaseString] isEqualToString:@"false"])
    {
        readerManager.scanSound = [NSNumber numberWithBool:NO];
    }
    else
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Enter 'true' or 'false' only"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }
}

////////////////////// INTERNAL FLOMIO READER FUNCTIONS /////////////////////////

/** Called when the app becomes active */
- (void)active {
    NSLog(@"App Activated");
}

/** Called when the app becomes inactive */
- (void)inactive {
    NSLog(@"App Inactive");
}

/** Called when the list of connected devices is updated */
- (void)didUpdateConnectedDevices:(NSArray *)connectedDevices {
    self->connectedDevices = connectedDevices;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* deviceId = self->connectedDevices[0];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:deviceId];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self->deviceConnected_callbackId];
    });
}

/** Called when the list of connected BR500 devices is updated */
- (void)didUpdateConnectedBr500:(NSArray *)peripherals {
    // TODO: something
}

/** Receives the UUID of a scanned tag */
- (void)didFindATagUUID:(NSString *)UUID fromDevice:(NSString *)deviceId withError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Found tag UUID: %@ from device:%@", UUID, deviceId);
        
        // send tag read update to Cordova
        if (![self->didFindATagUUID_callbackId isEqualToString:@"null"])
        {
            NSArray* result = @[deviceId, UUID];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:result];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:didFindATagUUID_callbackId];
        }
    });
}

/** Receives APDU responses from connected devices */
- (void)didRespondToApduCommand:(NSString *)response fromDevice:(NSString *)deviceId withError:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Received APDU: %@ from device:%@", response, deviceId); //APDU Response
        
        // send response to Cordova
        if (![self->apduResponse_callbackId isEqualToString:@"null"])
        {
            NSArray* result = @[deviceId, response];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:result];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:didFindATagUUID_callbackId];
        }
    });
}

/** Receives error messages from connected devices */
- (void)didReceiveReaderError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@", error); // reader error
        
        // TODO: send error to Cordova
    });
}

/** Sets the connected/disconnected image */
- (void)ReaderManager:(Reader *)reader readerAlert:(UIImageView *)imageView
{
    imageView.hidden = NO;
    imageView.alpha = 1.0f;
    
    // Then fades away after 2 seconds (the cross-fade animation will take 0.5s)
    [UIView animateWithDuration:0.5 delay:2.0 options:0 animations:^{
        // Animate the alpha value of your imageView from 1.0 to 0.0 here
        imageView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        // Once the animation is completed and the alpha has gone to 0.0, hide the view for good
        imageView.hidden = YES;
    }];
    
    imageView.center = [self.viewController.view convertPoint:self.viewController.view.center fromView:self.viewController.view.superview];
    [self.viewController.view addSubview:imageView];
}

@end
