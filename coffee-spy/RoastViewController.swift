//
//  RoastViewController.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 4/25/19.
//  Copyright © 2019 Konstantin Klitenik. All rights reserved.
//

import UIKit
import Charts

class RoastViewController: UIViewController {

    private let bleManager = BleManager.shareInstance
    
    private var roast: MyRoast?
    private var roastTimer: Timer?
    
    @IBOutlet weak var chartView: LineChartView!
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLineChart()
        bleManager.delegate = self
    }
    
    func reset() {
        // create new roast
        roast = MyRoast()
        // clear chart data
        chartView.data?.dataSets[0].clear()
        chartView.data?.dataSets[1].clear()
        chartView.notifyDataSetChanged()
    }
    
    @IBAction func startPushed(_ sender: UIButton) {
        if roast == nil || !roast!.isRunning {
            print("Starting roast")
            reset()
            roast?.start()
            
            roastTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (timer) in
                guard let roast = self?.roast else { return }
                let min = Int(roast.elapsedTime / 60)
                let sec = Int(roast.elapsedTime) % 60
                self?.timerLabel.text = String(format: "%02d:%02d", min, sec)
            }
            
            startButton.setTitle("STOP", for: .normal)
        } else {
            print("Stopping roast")
            roast?.stop()
            roastTimer?.invalidate()
            startButton.setTitle("START", for: .normal)
        }
    }
    
    @IBAction func fcPushed(_ sender: UIButton) {
    }
    
    @IBAction func scPushed(_ sender: UIButton) {
    }
    
    @IBAction func savePushed(_ sender: Any) {
        
    }
}

// MARK: BleManagerDelegate
extension RoastViewController: BleManagerDelegate {
    func didConnect() {
        
    }
    
    func didDisconnect() {
        
    }
    
    func didUpdateTemperature1(tempC: Int) {
        // if roast is not running, ignore updates
        guard let roast = roast, roast.isRunning else { return }
        
        print("Updated temp 1 (BT): \(tempC)")
        // add sample to roast
        roast.addBtSample(temp: Double(tempC))
        
        // add sample to chart
        guard let sample = roast.btCurve.last else { return }
        chartView.data!.addEntry(ChartDataEntry(x: sample.time, y: sample.temp.asFahrenheit()), dataSetIndex: 0)
        chartView.notifyDataSetChanged()
    }
    
    func didUpdateTemperature2(tempC: Int) {
        // if roast is not running, ignore updates
        guard let roast = roast, roast.isRunning else { return }
        
        print("Updated temp 2 (ET): \(tempC)")
        // add sample to roast
        roast.addEtSample(temp: Double(tempC))
        
        // add sample to chart
        guard let sample = roast.etCurve.last else { return }
        chartView.data!.addEntry(ChartDataEntry(x: sample.time, y: sample.temp.asFahrenheit()), dataSetIndex: 1)
        chartView.notifyDataSetChanged()
    }
}

extension RoastViewController {
    private func setupLineChart() {
        // BT line
        let btSet = LineChartDataSet(entries: nil, label: "BT")
        btSet.setColor(.green)
        btSet.lineWidth = 2
        btSet.drawCirclesEnabled = false
        btSet.highlightLineDashLengths = [5, 2.5]
        btSet.drawValuesEnabled = false
        btSet.axisDependency = .left
        
        // ET line
        let etSet = LineChartDataSet(entries: nil, label: "ET")
        etSet.setColor(.yellow)
        etSet.lineWidth = 2
        etSet.drawCirclesEnabled = false
        etSet.highlightLineDashLengths = [5, 2.5]
        etSet.drawValuesEnabled = false
        etSet.axisDependency = .left
        
        let data = LineChartData(dataSets: [btSet, etSet])
        
        // chart
        chartView.data = data
        chartView.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 1, alpha: 0)
        
        // legend
        chartView.legend.textColor = .white
        chartView.legend.horizontalAlignment = .right
        chartView.legend.verticalAlignment = .top
        chartView.legend.drawInside = true
        
        // x axis
        chartView.xAxis.axisMaximum = 15 * 60
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelTextColor = .white
        chartView.xAxis.valueFormatter = TimeFormatter()
        
        // left y axis
        chartView.leftAxis.axisMinimum = 100.0
        chartView.leftAxis.axisMaximum = 500.0
        chartView.leftAxis.gridColor = .white
        chartView.leftAxis.labelTextColor = .white
        
        // right y axis
        chartView.rightAxis.axisMinimum = 0.0
        chartView.rightAxis.axisMaximum = 50.0
        chartView.rightAxis.labelTextColor = .white
        chartView.rightAxis.drawGridLinesEnabled = false
    }
    
    class TimeFormatter: IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let mins = Int(value / 60)
            let secs = Int(value) % 60
            return String(format: "%d:%02d", mins, secs)
        }
    }
}
