//
//  Interpreter.h
//  CoinCounter
//
//  Created by PointerFLY on 17/07/2018.
//  Copyright © 2018 PointerFLY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Interpreter : NSObject

- (NSDictionary<NSString*, NSNumber*>*)runOnFrame:(nonnull CVPixelBufferRef)pixelBuffer;

@end
