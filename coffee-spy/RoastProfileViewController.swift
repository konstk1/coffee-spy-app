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
        
        setupChart()
    }
    
    func setupChart() {
        chartView.configRoastChart()
        
        guard let roast = roast else { return }
        
        let dataSets = (chartView.data as? LineChartData)?.dataSets
        
        if let btSet = dataSets?[RoastDataSetIndex.bt.rawValue] {
            roast.btCurve?.forEach {
                guard let bt = $0 as? BtSample else { return }
                _ = btSet.addEntry(ChartDataEntry(x: bt.time, y: bt.tempC.asFahrenheit()))
            }
        }
        
        if let etSet = dataSets?[RoastDataSetIndex.et.rawValue] {
            roast.etCurve?.forEach {
                guard let et = $0 as? EtSample else { return }
                _ = etSet.addEntry(ChartDataEntry(x: et.time, y: et.tempC.asFahrenheit()))
            }
        }
        
        
//        let btEntries = roast.btCurve?.array.compactMap({ (x) -> ChartDataEntry? in
//            guard let bt = x as? BtSample else { return nil }
//            return ChartDataEntry(x: bt.time, y: bt.tempC.asFahrenheit())
//        })
        
//        chartView.data?.dataSets[RoastDataSetIndex.bt]
        chartView.notifyDataSetChanged()
        
    }
    
    @IBAction func shareClicked(_ sender: UIBarButtonItem) {
        guard let roast = roast else { return }
        
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let path = docDir.appendingPathComponent("roast.csv")
        
        try! roast.asCsv().write(to: path, atomically: true, encoding: .utf8)
        
        let activityVc = UIActivityViewController(activityItems: ["Roast export", path], applicationActivities: nil)
        present(activityVc, animated: true) {
            do {
                log.verbose("Removing csv")
                try FileManager.default.removeItem(at: path)
            } catch {
                log.error("Failed to remove file: \(error)")
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}
