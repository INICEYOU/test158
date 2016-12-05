//
//  DetailViewController.swift
//  test158
//
//  Created by Nice on 01/12/2016.
//  Copyright © 2016 Andrey Kozhurin. All rights reserved.
//

import UIKit
import Contacts

class DetailViewController: UIViewController
{
    // Так как UI не имеет значения, то отображается содержимое объекта CNContact в textView

    @IBOutlet weak var detailDescriptionTextView: UITextView!

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let textView = self.detailDescriptionTextView
            {
                textView.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var detailItem: CNContact? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
}

