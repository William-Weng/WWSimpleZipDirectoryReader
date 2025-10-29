//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2025/10/29.
//

import UIKit
import WWSimpleZipDirectoryReader

final class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let zipFileURL = Bundle.main.url(forResource: "Test", withExtension: "zip")!
        let array = try! WWSimpleZipDirectoryReader.shared.array(fileUrl: zipFileURL).get()
        array.forEach { print($0) }
    }
}

