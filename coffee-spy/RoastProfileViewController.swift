//
//  RoastProfileViewController.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 6/19/19.
//  Copyright © 2019 KK. All rights reserved.
//

import UIKit
import Charts

class RoastProfileViewController: UIViewController {

    @IBOutlet weak var chartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
