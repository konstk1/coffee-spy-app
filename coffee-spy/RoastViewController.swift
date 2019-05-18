//
//  RoastViewController.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 4/25/19.
//  Copyright © 2019 Konstantin Klitenik. All rights reserved.
//

import UIKit
import CoreData
import Charts

class RoastViewController: UIViewController {

    private let bleManager = BleManager.shared
    
    private var context: NSManagedObjectContext?
    private var roast: Roast?
    private var roastTimer: Timer?
    
    private var devRatio: Double = 0.0 {
        didSet {
            devRatioLabel.text = String(format: "Dev: %2.0f%%", devRatio * 100)
        }
    }
    
    @IBOutlet weak var chartView: LineChartView!
    
    @IBOutlet weak var roastInfoLabel: UILabel!
    @IBOutlet weak var devRatioLabel: UILabel!
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
        // creating new child context will discard any unsaved Roast data
        context = DataController.shared.makeChildContext()
        
        // create new roast
        roast = Roast(context: context!)
        
        // clear and reset chart data
        chartView.data?.dataSets.removeAll()
        setupLineChart()
        
        timerLabel.text = roast?.elapsedTime.asMinSecString()
        devRatio = 0.0
    }
    
    @IBAction func startPushed(_ sender: UIButton) {
        if roast == nil || !roast!.isRunning {
            log.verbose("Starting roast")
            reset()
            roast?.start()
            
            roastTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (timer) in
                guard let roast = self?.roast else { log.error("No roast"); return }
                self?.timerLabel.text = roast.elapsedTime.asMinSecString()
                if roast.firstCrackStartTime > 0 {
                    self?.devRatio = 1.0 - roast.firstCrackStartTime / roast.elapsedTime
                }
            }
            
            startButton.setTitle("STOP", for: .normal)
        } else {
            log.verbose("Stopping roast")
            roast?.stop()
            roastTimer?.invalidate()
            startButton.setTitle("START", for: .normal)
        }
    }
    
    @IBAction func fcPushed(_ sender: UIButton) {
        roast?.markFirstCrackStart()
        if let roast = roast, roast.firstCrackStartTime > 0 {
            setFcMarker(at: roast.firstCrackStartTime)
        }
    }
    
    @IBAction func scPushed(_ sender: UIButton) {
        roast?.marcSecondCrackStart()
        if let roast = roast, roast.secondCrackStartTime > 0 {
            setScMarker(at: roast.secondCrackStartTime)
        }
    }
    
    @IBAction func savePushed(_ sender: Any) {
        guard let context = context else { fatalError("Context for save is nil") }
        DataController.shared.saveContext(context, saveParent: true)
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
            guard let sample = roast.btCurve?.lastObject as? BtSample else { return }
            self.chartView.data!.addEntry(ChartDataEntry(x: sample.time, y: sample.tempC.asFahrenheit()), dataSetIndex: 0)
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
            guard let sample = roast.etCurve?.lastObject as? EtSample else { return }
            self.chartView.data!.addEntry(ChartDataEntry(x: sample.time, y: sample.tempC.asFahrenheit()), dataSetIndex: 1)
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
    
    func setVerticalMarker(at time: Double, label: String, color: UIColor) {
        let entries = [ChartDataEntry(x: time, y: 0.0), ChartDataEntry(x: time, y: chartView.leftAxis.axisMaximum)]
        
        if let dataSet = chartView.data?.getDataSetByLabel(label, ignorecase: false) {
            chartView.data?.removeDataSet(dataSet)
        }
        
        let dataSet = LineChartDataSet(entries: entries, label: label)
        dataSet.lineWidth = 1.0
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.axisDependency = .left
        dataSet.setColor(color)
        
        chartView.data?.addDataSet(dataSet)
        
        chartView.notifyDataSetChanged()
    }
    
    func setFcMarker(at time: Double) {
        setVerticalMarker(at: time, label: "FC", color: .white)
    }
    
    func setScMarker(at time: Double) {
        setVerticalMarker(at: time, label: "SC", color: .lightGray)
    }
    
    class TimeFormatter: IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return value.asMinSecString()
        }
    }
}
