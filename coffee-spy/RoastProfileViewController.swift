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

    var roast: Roast?
    
    @IBOutlet weak var chartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .system)
        button.titleLabel!.text = "Share"
//        button.setImage(UIImage(systemName: "Share"), for: .normal)
        button.addTarget(self, action: #selector(shareClicked), for: .touchUpInside)
        view.addSubview(button)

        print("Loaded with roast \(roast!)")
        // Do any additional setup after loading the view.
    }
    
    @IBAction func shareClicked(_ sender: UIBarButtonItem) {
        guard let roast = roast else { return }
        
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let path = docDir.appendingPathComponent("roast.csv")
        
        try! roast.asCsv().write(to: path, atomically: true, encoding: .utf8)
        
        let activityVc = UIActivityViewController(activityItems: ["Roast export", path], applicationActivities: nil)
        present(activityVc, animated: true, completion: nil)
        
//        try! FileManager.default.removeItem(at: path)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
