//
//  BackgroundJS.m
//  BackgroundJS
//
//  Created by James O'Cull on 7/6/13.
//
//

#import "BackgroundJS.h"

@implementation BackgroundJS

@synthesize backgroundSecondsCounter;

- (void)dealloc
{
    //[super dealloc];
}

- (void)pluginInitialize
{
    backgroundSecondsCounter = 0;
    [super pluginInitialize];
}

// private
- (void)doBackgroundTimeLoop
{
    __block UIBackgroundTaskIdentifier task;
    UIApplication* app = [UIApplication sharedApplication];
    task = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    }];
    
    while(YES){
        @synchronized(self){
            backgroundSecondsCounter--;
            NSLog(@"Remaining background seconds: %i", backgroundSecondsCounter);
            if (backgroundSecondsCounter <= 0)
                break; // Exit loop
        }
        [NSThread sleepForTimeInterval:1];
    }
    
    // End this background task now
    [app endBackgroundTask:task];
    task = UIBackgroundTaskInvalid;
}

// private
- (void)setBackgroundSecondsWithSeconds:(NSNumber*)seconds
{
    NSInteger secondsInt = [seconds integerValue];
    @synchronized(self){
        NSInteger preAddSeconds = backgroundSecondsCounter;

        // Start if not started
        if(preAddSeconds <= 0 && secondsInt > 0){
            backgroundSecondsCounter = secondsInt;
            [self performSelectorInBackground:@selector(doBackgroundTimeLoop) withObject:nil];
        }
    }
}

- (void)setBackgroundSeconds:(CDVInvokedUrlCommand *)command
{
    if(self.backgroundSecondsCounter > 0){
       CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Thread already running"];
       [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else if([command.arguments count] > 0
       && [[command argumentAtIndex:0] isKindOfClass:[NSNumber class]])
    {
        [self setBackgroundSecondsWithSeconds:[command argumentAtIndex:0]];
    }
}

- (void)lockBackgroundTime:(CDVInvokedUrlCommand *)command
{
    // Push it to the limit!
    [self setBackgroundSecondsWithSeconds:[NSNumber numberWithInteger:NSIntegerMax]];
}

- (void)unlockBackgroundTime:(CDVInvokedUrlCommand *)command
{
    @synchronized(self){
        backgroundSecondsCounter = -1; // Must set manually to override
    }
    [self setBackgroundSecondsWithSeconds:[NSNumber numberWithInteger:backgroundSecondsCounter]];
}

- (void)isBackgroundThreadRunning:(CDVInvokedUrlCommand *)command
{
	bool threadRunning = backgroundSecondsCounter > 0;

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:threadRunning];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
