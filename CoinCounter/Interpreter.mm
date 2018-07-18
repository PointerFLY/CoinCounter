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
    
    GaussianBlur(mGray, mGray, cv::Size(5, 5), 2, 2);
    vector<Vec3f> circles;
    HoughCircles(mGray, circles, CV_HOUGH_GRADIENT, 1, mGray.rows / 20, 100, 60, 20, 100);
    
    for( size_t i = 0; i < circles.size(); i++ ) {
        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
        int radius = cvRound(circles[i][2]);
        circle(mRgba, center, radius, Scalar(255, 0, 0, 255), 2);
    }
    
    NSDictionary* coinInfo = [self runTFModel:mRgba];
    UIImage* image = MatToUIImage(mRgba);
    
    InterpreterResult* result = [[InterpreterResult alloc] init];
    result.coinInfo = coinInfo;
    result.image = image;
    
    return result;
}

- (NSDictionary*)runTFModel:(Mat)mat {
    // TODO: General image preprocessing, now assume 640 * 480
    
    int kImageWidth = 224;
    int kChannel = 3;
    
    cv::Rect rect = cvRect(16, 96, 448, 448);
    Mat img = mat(rect);
    resize(img, img, cv::Size(kImageWidth, kImageWidth));

    float* input = _interpreter->typed_input_tensor<float>(0);
    
    for (int i = 0; i < kImageWidth; i++) {
        for (int j = 0; j < kImageWidth; j++) {
            for (int k = 0; k < kChannel; k++) {
                input[i * kImageWidth * kChannel + j * kChannel + k] = static_cast<float>(img.at<Vec4b>(i, j)[k]);
            }
        }
    }

    assert(_interpreter->Invoke() == kTfLiteOk);
    
    NSMutableDictionary* coinInfo = [[NSMutableDictionary alloc] init];
    float* output = _interpreter->typed_output_tensor<float>(0);
    for (int i = 0; i < 5; i++) {
        [coinInfo setObject:[NSString stringWithFormat:@"%.2f", output[i]] forKey:[NSString stringWithUTF8String:_labels[i].c_str()]];
    }

    return coinInfo;
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
    int width = static_cast<int>(CVPixelBufferGetWidth(pixelBuffer));
    int height = static_cast<int>(CVPixelBufferGetHeight(pixelBuffer));
    
    Mat mRgba = Mat(height, width, CV_8UC4, address, 0);
    rotate(mRgba, mRgba, ROTATE_90_CLOCKWISE);
    cvtColor(mRgba, mRgba, CV_BGRA2RGBA);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return mRgba;
}

@end
