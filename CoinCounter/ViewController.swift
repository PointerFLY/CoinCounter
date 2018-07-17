//
//  ViewController.swift
//  CoinCounter
//
//  Created by PointerFLY on 17/07/2018.
//  Copyright © 2018 PointerFLY. All rights reserved.
//

import UIKit
import SnapKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.view.addSubview(_previewView)
        self.view.addSubview(_freezeButton)
        _previewView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-80)
        }
        _freezeButton.snp.makeConstraints { make in
            make.top.equalTo(_previewView.snp.bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.height.equalTo(44)
        }
        _freezeButton.addTarget(self, action: #selector(freezeButtonClicked(_:)), for: .touchUpInside)
    }
    
    @objc
    private func freezeButtonClicked(_ sender: UIButton) {
        print("freeze")
    }

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

