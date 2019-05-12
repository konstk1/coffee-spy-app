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

    private let bleManager = BleManager.shared
    
    private var roast: MyRoast?
    private var roastTimer: Timer?
    
    @IBOutlet weak var chartView: LineChartView!
    
    @IBOutlet weak var btLabel: UILabel!
    @IBOutlet weak var etLabel: UILabel!
    @IBOutlet weak var deviceLabel: UILabel!
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
        
        timerLabel.text = roast?.elapsedTime.asMinSecString()
    }
    
    @IBAction func startPushed(_ sender: UIButton) {
        if roast == nil || !roast!.isRunning {
            print("Starting roast")
            reset()
            roast?.start()
            
            roastTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (timer) in
                self?.timerLabel.text = self?.roast?.elapsedTime.asMinSecString()
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
    func didConnect(uuidStr: String) {
        DispatchQueue.main.async { [unowned self] in
            self.deviceLabel.text = "Dev: \(uuidStr.suffix(4))"
        }
    }
    
    func didDisconnect() {
        DispatchQueue.main.async { [unowned self] in
            self.btLabel.text = "BT:   N/A"
            self.etLabel.text = "BT:   N/A"
            self.deviceLabel.text = "Dev: N/A"
        }
    }
    
    func didUpdateTemperature1(tempC: Int) {
        DispatchQueue.main.async { [unowned self] in
            self.btLabel.text = "BT: \(Int(Double(tempC).asFahrenheit()))°F"
            
            // if roast is not running, ignore updates
            guard let roast = self.roast, roast.isRunning else { return }
            
            let tempC = DegreesC(tempC)
//            print("Updated temp 1 (BT): \(tempC)°C (\(tempC.asFahrenheit())°F)")
            // add sample to roast
            roast.addBtSample(temp: tempC)
            
            // add sample to chart
            guard let sample = roast.btCurve.last else { return }
            self.chartView.data!.addEntry(ChartDataEntry(x: sample.time, y: sample.temp.asFahrenheit()), dataSetIndex: 0)
            self.chartView.notifyDataSetChanged()
        }
    }
    
    func didUpdateTemperature2(tempC: Int) {
        DispatchQueue.main.async { [unowned self] in
            self.etLabel.text = "ET: \(Int(Double(tempC).asFahrenheit()))°F"
            
            // if roast is not running, ignore updates
            guard let roast = self.roast, roast.isRunning else { return }
            
            let tempC = DegreesC(tempC)
//            print("Updated temp 2 (ET): \(tempC)°C (\(tempC.asFahrenheit())°F)")
            // add sample to roast
            roast.addEtSample(temp: Double(tempC))
            
            // add sample to chart
            guard let sample = roast.etCurve.last else { return }
            self.chartView.data!.addEntry(ChartDataEntry(x: sample.time, y: sample.temp.asFahrenheit()), dataSetIndex: 1)
            self.chartView.notifyDataSetChanged()
        }
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
        chartView.doubleTapToZoomEnabled = false
        
        // legend
        chartView.legend.textColor = .white
        chartView.legend.horizontalAlignment = .right
        chartView.legend.verticalAlignment = .top
        chartView.legend.drawInside = true
        
        // x axis
        chartView.xAxis.axisMinimum = 0
        chartView.xAxis.axisMaximum = 15 * 60
        chartView.xAxis.labelCount = 16
        chartView.xAxis.forceLabelsEnabled = true
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelTextColor = .white
        chartView.xAxis.valueFormatter = TimeFormatter()
        chartView.xAxis.drawGridLinesEnabled = true
        chartView.xAxis.gridColor = .white
        chartView.xAxis.gridLineWidth = 0.2
        chartView.xAxis.gridLineDashLengths = [5, 4]
        
        // left y axis
        chartView.leftAxis.axisMinimum = 0.0
        chartView.leftAxis.axisMaximum = 500.0
        chartView.leftAxis.labelCount = 10
        chartView.leftAxis.gridColor = .white
        chartView.leftAxis.labelTextColor = .white
        
        // right y axis
        chartView.rightAxis.axisMinimum = 0.0
        chartView.rightAxis.axisMaximum = 50.0
        chartView.rightAxis.labelTextColor = .white
        chartView.rightAxis.drawGridLinesEnabled = false
        
        chartView.notifyDataSetChanged()
    }
    
    class TimeFormatter: IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return value.asMinSecString()
        }
    }
}
