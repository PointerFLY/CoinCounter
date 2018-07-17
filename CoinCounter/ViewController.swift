//
//  ViewController.swift
//  CoinCounter
//
//  Created by PointerFLY on 17/07/2018.
//  Copyright © 2018 PointerFLY. All rights reserved.
//

import AVFoundation
import UIKit
import SnapKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEvents()
        setupAVCapture();
    }
    
    // MARK: - AVCapture
    
    private var _session: AVCaptureSession!
    private var _videoDataOuput: AVCaptureVideoDataOutput!
    private var _previewLayer: AVCaptureVideoPreviewLayer!
    private var _videoDataOutputQueue: DispatchQueue!
    private let _interpreter = Interpreter()
    
    private func setupAVCapture() {
        _session = AVCaptureSession()
        if UIDevice.current.userInterfaceIdiom == .phone {
            _session.sessionPreset = .vga640x480
        } else {
            _session.sessionPreset = .photo
        }
        
        let device = AVCaptureDevice.default(for: .video)!
        let deviceInput = try! AVCaptureDeviceInput(device: device)
        
        if _session.canAddInput(deviceInput) {
            _session.addInput(deviceInput)
        }
    
        _videoDataOuput = AVCaptureVideoDataOutput()
        _videoDataOuput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCMPixelFormat_32BGRA]
        _videoDataOutputQueue = DispatchQueue(label: "com.pointerfly.CoinCounter.videoDataOutputQueue")
        _videoDataOuput.alwaysDiscardsLateVideoFrames = true
        _videoDataOuput.setSampleBufferDelegate(self, queue: _videoDataOutputQueue);
        if _session.canAddOutput(_videoDataOuput) {
            _session.addOutput(_videoDataOuput)
        }
        _videoDataOuput.connection(with: .video)?.isEnabled = true
        
        _previewLayer = AVCaptureVideoPreviewLayer(session: _session);
        _previewLayer.backgroundColor = UIColor.black.cgColor
        _previewLayer.videoGravity = .resizeAspect
        let rootLayer = _previewView.layer
        rootLayer.masksToBounds = true
        rootLayer.addSublayer(_previewLayer)
        
        _session.startRunning()
    }
    
    // MARK: - Events
    
    private func setupEvents() {
        _freezeButton.addTarget(self, action: #selector(freezeButtonClicked(_:)), for: .touchUpInside)
    }
    
    @objc
    private func freezeButtonClicked(_ sender: UIButton) {
        if _session.isRunning {
            _session.stopRunning()
            sender.setTitle("Continue", for: .normal)
            let flashView = UIView(frame: _previewView.frame)
            flashView.backgroundColor = UIColor.white
            flashView.alpha = 0.0
            self.view.window?.addSubview(flashView);
            
            UIView.animate(withDuration: 0.2, animations: {
                flashView.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    flashView.alpha = 0.0
                }, completion: { _ in
                    flashView.removeFromSuperview()
                })
            }
        } else {
            self._session.startRunning()
            sender.setTitle("Freeze Frame", for: .normal)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let coinInfo =  _interpreter.run(onFrame: buffer) as! [String: Int]
        
        var text = "";
        for (key, value) in coinInfo {
            text += "[\(value)]\(key)\n"
        }
        DispatchQueue.main.async { [weak self] in
            self?._infoTextView.text = text
        }
    }
    
    // MARK: - UI
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        let rootLayer = _previewView.layer
        _previewLayer.frame = rootLayer.bounds
    }
    
    private func setupUI() {
        self.view.backgroundColor = UIColor.black
        self.view.addSubview(_previewView)
        self.view.addSubview(_infoTextView)
        self.view.addSubview(_freezeButton)
        _previewView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(_infoTextView.snp.top)
        }
        _infoTextView.snp.makeConstraints { make in
            make.left.equalTo(self.view)
            make.right.equalTo(_freezeButton.snp.left)
            make.bottom.equalTo(self.view)
            make.height.equalTo(164)
            make.width.equalTo(100)
        }
        _freezeButton.snp.makeConstraints { make in
            make.top.equalTo(_previewView.snp.bottom)
            make.right.equalTo(self.view)
            make.height.equalTo(_infoTextView)
        }
    }
    
    private let _infoTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor.white
        textView.font = UIFont(name: "Menlo-Regular", size: 14)
        textView.textColor = UIColor.black
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false
        return textView
    }()
    
    private let _previewView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    private let _freezeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Freeze Frame", for: .normal)
        button.titleLabel?.font = UIFont(name: "Menlo-Regular", size: 24)
        button.backgroundColor = UIColor.black
        button.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
        button.setTitleColor(UIColor.white, for: .normal)
        return button
    }()
}

