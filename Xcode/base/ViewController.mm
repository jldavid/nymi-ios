#import "ViewController.h"

NSString* provisionIdToString(NclProvisionId provisionId){
    NSMutableString* result = [[NSMutableString alloc] init];
    for(unsigned i = 0; i < NCL_PROVISION_ID_SIZE; ++i)
        [result appendFormat: @"%x ", provisionId[i]];
    return result;
}

const char* disconnectionReasonToString(NclDisconnectionReason reason){
    switch(reason){
        case NCL_DISCONNECTION_LOCAL:
            return "NCL_DISCONNECTION_LOCAL";
        case NCL_DISCONNECTION_TIMEOUT:
            return "NCL_DISCONNECTION_TIMEOUT";
        case NCL_DISCONNECTION_FAILURE:
            return "NCL_DISCONNECTION_FAILURE";
        case NCL_DISCONNECTION_REMOTE:
            return "NCL_DISCONNECTION_REMOTE";
        case NCL_DISCONNECTION_CONNECTION_TIMEOUT:
            return "NCL_DISCONNECTION_CONNECTION_TIMEOUT";
        case NCL_DISCONNECTION_LL_RESPONSE_TIMEOUT:
            return "NCL_DISCONNECTION_LL_RESPONSE_TIMEOUT";
        case NCL_DISCONNECTION_OTHER:
            return "NCL_DISCONNECTION_OTHER";
        default: break;
    }
    return "invalid disconnection reason, something bad happened";
}

void callback(NclEvent event, void* userData){
    ViewController* v=(__bridge ViewController*)userData;
    switch(event.type){
        case NCL_EVENT_INIT:
            NSLog(@"NCL_EVENT_INIT %s", event.init.success?"success":"failure");
            break;
        case NCL_EVENT_DISCOVERY:{
            NSLog(@"NCL_EVENT_DISCOVERY");
            NSLog(@"Nymi Handle: %d", event.discovery.nymiHandle);
            NSLog(@"Nymi RSSI: %d", event.discovery.rssi);
            NSLog(@"nclAgree()");
            nclStopScan();
            NclBool agree = nclAgree(event.discovery.nymiHandle);
            NSLog(@"called nclAgree returned %u", agree);
            break;
        }
        case NCL_EVENT_AGREEMENT:
            NSLog(@"NCL_EVENT_AGREEMENT");
            NSLog(@"Nymi handle: %d",event.agreement.nymiHandle);
            NSLog(@"nclProvision()");
            nclProvision(event.agreement.nymiHandle);
            NSLog(@"event.agreement.leds[0][0]: %d", event.agreement.leds[0][0]);
            NSLog(@"event.agreement.leds[0][1]: %d", event.agreement.leds[0][1]);
            NSLog(@"event.agreement.leds[0][2]: %d", event.agreement.leds[0][2]);
            NSLog(@"event.agreement.leds[0][3]: %d", event.agreement.leds[0][3]);
            NSLog(@"event.agreement.leds[0][4]: %d", event.agreement.leds[0][4]);
            NSLog(@"event.agreement.leds[1][0]: %d", event.agreement.leds[1][0]);
            NSLog(@"event.agreement.leds[1][1]: %d", event.agreement.leds[1][1]);
            NSLog(@"event.agreement.leds[1][2]: %d", event.agreement.leds[1][2]);
            NSLog(@"event.agreement.leds[1][3]: %d", event.agreement.leds[1][3]);
            NSLog(@"event.agreement.leds[1][4]: %d", event.agreement.leds[1][4]);
            break;
        case NCL_EVENT_PROVISION:{
            NSLog(@"NCL_EVENT_PROVISION");
            NSLog(@"Provision ID: %@",provisionIdToString(event.provision.provision.id));
            NSLog(@"Raw Provision ID: %s",event.provision.provision.id);
            NSLog(@"Provision Key: %@",provisionIdToString(event.provision.provision.key));
            v->provisions.push_back(event.provision.provision);
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NclProvision provision = event.provision.provision;
            NSData *savedProvision = [NSData dataWithBytes:&provision length:sizeof(provision)];
            [userDefaults setObject:savedProvision forKey:@"NymiProvision"];
            
            nclStartFinding(v->provisions.data(), v->provisions.size(), NCL_FALSE);
            break;
        }
        case NCL_EVENT_FIND:{
            NSLog(@"NCL_EVENT_FIND");
            NSLog(@"nclStopScan()");
            nclStopScan();
            NSLog(@"nclValidate()");
            nclValidate(event.find.nymiHandle);
            break;
        }
        case NCL_EVENT_VALIDATION:
             NSLog(@"NCL_EVENT_VALIDATION");
             NSLog(@"Nymi validated! Now trusted user stuff can happen.");
             break;
        case NCL_EVENT_DISCONNECTION:
             NSLog(@"NCL_EVENT_DISCONNECTION");
             NSLog(@"Reason %s",disconnectionReasonToString(event.disconnection.reason));
            break;
        case NCL_EVENT_ECG:
             NSLog(@"NCL_EVENT_ECG");
             NSLog(@"event.ecg.nymiHandle: %d", event.ecg.nymiHandle);
             NSLog(@"event.ecg.samples[0]: %d", event.ecg.samples[0]);
             NSLog(@"event.ecg.samples[1]: %d", event.ecg.samples[1]);
             NSLog(@"event.ecg.samples[2]: %d", event.ecg.samples[2]);
             NSLog(@"event.ecg.samples[3]: %d", event.ecg.samples[3]);
             NSLog(@"event.ecg.samples[4]: %d", event.ecg.samples[4]);
             NSLog(@"event.ecg.samples[5]: %d", event.ecg.samples[5]);
             NSLog(@"event.ecg.samples[6]: %d", event.ecg.samples[6]);
             NSLog(@"event.ecg.samples[7]: %d", event.ecg.samples[7]);
            break;
        case NCL_EVENT_RSSI:
             NSLog(@"NCL_EVENT_RSSI");
             NSLog(@"Nymi Handle: %d", event.rssi.nymiHandle);
             NSLog(@"RSSI: %d", event.rssi.rssi);
            break;
        default: break;
    }
}

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    errorStream = fopen([[NSHomeDirectory() stringByAppendingString: @"/Documents/errorStream.txt"] UTF8String], "w+");
    errorStreamPosition = 0;
    error = [[NSMutableString alloc] init];
    errorTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(pumpErrorStream:) userInfo: nil repeats: YES];
    
    NSLog(@"nclSetIpAndPort()");
	nclSetIpAndPort("192.168.1.146", 9089); //nclSetIpAndPort("192.168.1.168", 9089);
    NSLog(@"nymiInit()");
	NclBool nymiInit = nclInit(callback, (__bridge void*)self, "iOSClient", NCL_MODE_DEV, errorStream); // - For Nymulator (libNCLNetiOS.a)
	//NclBool nymiInit = nclInit(callback, (__bridge void*)self, "iOSClient", NCL_MODE_DEFAULT, errorStream); // - For Device (libNCLiOS.a)
    nclStartDiscovery();
    if (nymiInit){
        NSLog(@"nclStartDiscovery()");
        nclStartDiscovery();

        /*
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSData *savedProvision = [userDefaults dataForKey:@"NymiProvision"];
        if (savedProvision != nil && [savedProvision length] > 0) {
            NclProvision provision;
            [savedProvision getBytes:&provision length:sizeof(provision)];
            self->provisions.push_back(provision);
        }
        NSLog(@"nclStartFinding()");
        nclStartFinding(provisions.data(), 1, NCL_TRUE);
        */
    }
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (void)dealloc{
	nclFinish();
}

//------error timer callback-----//
- (void)pumpErrorStream: (NSTimer*)timer{
    nclLockErrorStream();
    fpos_t newErrorStreamPosition;
    fgetpos(errorStream, &newErrorStreamPosition);
    while(errorStreamPosition<newErrorStreamPosition){
        fsetpos(errorStream, &errorStreamPosition);
        char c=fgetc(errorStream);
        if(c=='\n'){
            NSLog(@"Error:%@", error);
            [error deleteCharactersInRange: NSMakeRange(0, [error length])];
        }
        else [error appendFormat: @"%c", c];
        ++errorStreamPosition;
    }
    nclUnlockErrorStream();
}

@end