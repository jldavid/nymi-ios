#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:[NSData dataWithBytes:nil length:0] forKey:@"NymiProvision"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	NSLog(@"will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	NSLog(@"did enter background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	NSLog(@"will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	NSLog(@"did become active");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	NSLog(@"will terminate");
}

@end
