#import <UIKit/UIKit.h>
#import "messageLog.h"
#include "ncl.h"
#include <cstdio>
#include <vector>

@interface ViewController: UIViewController{
    @public std::vector<NclProvision> provisions;
    FILE* errorStream;
    fpos_t errorStreamPosition;
    NSMutableString* error;
    NSTimer* errorTimer;
}
@end
