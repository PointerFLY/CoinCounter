//
//  Interpreter.m
//  CoinCounter
//
//  Created by PointerFLY on 17/07/2018.
//  Copyright © 2018 PointerFLY. All rights reserved.
//

#include "opencv2/opencv.hpp"
#import "Interpreter.h"

#include "opencv2/imgcodecs/ios.h"
#include <vector>
#include "tensorflow/contrib/lite/kernels/register.h"
#include "tensorflow/contrib/lite/model.h"
#include "tensorflow/contrib/lite/string_util.h"
#include "tensorflow/contrib/lite/tools/mutable_op_resolver.h"

using namespace cv;
using namespace std;

@implementation InterpreterResult
@end

@implementation Interpreter {
    std::unique_ptr<tflite::FlatBufferModel> _model;
    std::unique_ptr<tflite::Interpreter> _interpreter;
    std::vector<std::string> _labels;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupTFModel];
    }
    return self;
}

- (InterpreterResult *)runOnFrame:(CVPixelBufferRef)pixelBuffer {
    Mat mRgba = [self readMatFromPixelBuffer:pixelBuffer];
    Mat mGray;
    cvtColor(mRgba, mGray, CV_RGBA2GRAY);
    
    Mat cannyOutput;
    vector<Mat> contours;
    vector<Vec4i> hierarchy;
    
    GaussianBlur(mGray, mGray, cv::Size(5, 5), 2, 2);
    Canny(mGray, cannyOutput, 100, 255, 3);
    findContours(cannyOutput, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    
    vector<Mat> contourPolygons(contours.size());
    vector<cv::Rect> boundRect(contours.size());
    vector<Point2f> center(contours.size());
    vector<float> radius(contours.size());
    NSDictionary* coinInfo = [[NSMutableDictionary alloc] init];
    
    for(int i = 0; i < contours.size(); i++) {
        approxPolyDP(contours[i], contourPolygons[i], 3, true);
        boundRect[i] = boundingRect(contourPolygons[i]);
        minEnclosingCircle(contourPolygons[i], center[i], radius[i]);
        
        double ratio = static_cast<double>(boundRect[i].width) / boundRect[i].height;
        if (ratio > 0.8 && ratio < 1.25 ) {
            Scalar color = Scalar(255, 0, 0, 255);
            rectangle(mRgba, boundRect[i].tl(), boundRect[i].br(), color, 2, 8, 0);
//            circle(mRgba, center[i], static_cast<int>(radius[i]), color, 2, 8, 0);
            
            int idx = [self runTFModel:mRgba(boundRect[i])].intValue;
            NSString* key = [NSString stringWithUTF8String:_labels[idx].c_str()];
            id value = [NSNumber numberWithInt:((NSNumber*)[coinInfo valueForKey:key]).intValue + 1];
            [coinInfo setValue:value forKey:key];
        }
    }
    
    InterpreterResult* result = [[InterpreterResult alloc] init];
    result.coinInfo = coinInfo;
    result.image = MatToUIImage(mRgba);
    
    return result;
}

- (NSNumber*)runTFModel:(Mat)mat {
    int kImageWidth = 224;
    int kChannel = 3;
    
    resize(mat, mat, cv::Size(kImageWidth, kImageWidth));

    float* input = _interpreter->typed_input_tensor<float>(0);
    for (int i = 0; i < kImageWidth; i++) {
        for (int j = 0; j < kImageWidth; j++) {
            for (int k = 0; k < kChannel; k++) {
                input[i * kImageWidth * kChannel + j * kChannel + k] = static_cast<float>(mat.at<Vec4b>(i, j)[k]);
            }
        }
    }

    assert(_interpreter->Invoke() == kTfLiteOk);
    
    float* output = _interpreter->typed_output_tensor<float>(0);
    
    int maxIdx = 0;
    for (int i = 1; i < 5; i++) {
        if (output[i] > output[maxIdx]) {
            maxIdx = i;
        }
    }
    
    return [NSNumber numberWithInt:maxIdx];
}

- (void)setupTFModel {
    // Load Model
    
    NSString* modelPath = [[NSBundle mainBundle] pathForResource:@"model" ofType:@"tflite"];
    _model = tflite::FlatBufferModel::BuildFromFile([modelPath UTF8String]);
    _model->error_reporter();
    
    tflite::ops::builtin::BuiltinOpResolver resolver;
    tflite::InterpreterBuilder(*_model, resolver)(&_interpreter);
    assert(_interpreter->AllocateTensors() == kTfLiteOk);
    
    // Load labels
    
    NSString* labelsPath = [[NSBundle mainBundle] pathForResource:@"labels" ofType:@"txt"];
    ifstream ifs([labelsPath UTF8String]);
    std::string line;
    while (ifs) {
        std::getline(ifs, line);
        _labels.push_back(line);
    }
}

- (Mat)readMatFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* address =  CVPixelBufferGetBaseAddress(pixelBuffer);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    int width = static_cast<int>(CVPixelBufferGetWidth(pixelBuffer));
    int height = static_cast<int>(CVPixelBufferGetHeight(pixelBuffer));
    Mat mRgba = Mat(height, width, CV_8UC4, address, 0);
    rotate(mRgba, mRgba, ROTATE_90_CLOCKWISE);
    cvtColor(mRgba, mRgba, CV_BGRA2RGBA);
    
    return mRgba;
}

@end
