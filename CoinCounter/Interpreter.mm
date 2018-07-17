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
    NSDictionary* dictionary = @{@"20 Euro": [NSNumber numberWithInt:1], @"50 Cent" : [NSNumber numberWithInt:2]};
    return dictionary;
}

@end
