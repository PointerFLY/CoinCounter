//
//  Interpreter.h
//  CoinCounter
//
//  Created by PointerFLY on 17/07/2018.
//  Copyright © 2018 PointerFLY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InterpreterResult : NSObject
@property(nonatomic, strong) UIImage* image;
@property(nonatomic, strong) NSDictionary* coinInfo;
@end

@interface Interpreter : NSObject

- (InterpreterResult *)runOnFrame:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
