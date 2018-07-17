//
//  Interpreter.m
//  CoinCounter
//
//  Created by PointerFLY on 17/07/2018.
//  Copyright © 2018 PointerFLY. All rights reserved.
//

#import "Interpreter.h"

@implementation Interpreter

- (NSDictionary*)runOnFrame:(CVPixelBufferRef)pixelBuffer {
    NSDictionary* dictionary = @{@"10 Cent": [NSNumber numberWithInt:1],
                                 @"20 Cent" : [NSNumber numberWithInt:2],
                                 @"50 Cent": [NSNumber numberWithInt:1],
                                 @"1 Cent" : [NSNumber numberWithInt:2],
                                 @"2 Euro": [NSNumber numberWithInt:1],
                                 @"5 Cent" : [NSNumber numberWithInt:2],
                                 @"1 Cent" : [NSNumber numberWithInt:2]};
    return dictionary;
}

@end
