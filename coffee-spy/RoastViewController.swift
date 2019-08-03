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
    
    func didUpdateTemperature1(tempC: DegreesC) {
        DispatchQueue.main.async { [unowned self] in
            self.btLabel.text = "BT: \(String(format: "%5.1f", tempC.asFahrenheit()))°F"
            
            // if roast is not running, ignore updates
            guard let roast = self.roast, roast.isRunning else { return }
            
            let tempC = DegreesC(tempC)
//            print("Updated temp 1 (BT): \(tempC)°C (\(tempC.asFahrenheit())°F)")
            // add sample to roast
            roast.addBtSample(temp: tempC)
            
            // add sample to chart
            guard let btCurve = roast.btCurve, let lastSample = btCurve.lastObject as? BtSample else { return }
            self.chartView.data!.addEntry(ChartDataEntry(x: lastSample.time, y: lastSample.tempC.asFahrenheit()), dataSetIndex: RoastDataSetIndex.bt.rawValue)
            
            // add delta data point
            let btWindowSize = 5
            if btCurve.count >= btWindowSize, let prevSample = btCurve.object(at: btCurve.count - btWindowSize) as? BtSample {
                let deltaF = lastSample.tempC.asFahrenheit() - prevSample.tempC.asFahrenheit()
                let deltaT = lastSample.time - prevSample.time
                let ror = deltaF / deltaT * 60
                log.debug("T \(lastSample.time): cur \(lastSample.tempC.asFahrenheit())F prev \(prevSample.tempC.asFahrenheit())F, delta \(deltaF) F ror \(ror) F/min")
                self.chartView.data!.addEntry(ChartDataEntry(x: lastSample.time, y: ror), dataSetIndex: RoastDataSetIndex.deltaBt.rawValue)
            }
            
            self.chartView.notifyDataSetChanged()
        }
    }
    
    func didUpdateTemperature2(tempC: DegreesC) {
        DispatchQueue.main.async { [unowned self] in
            self.etLabel.text = "ET: \(String(format: "%5.1f", tempC.asFahrenheit()))°F"
            
            // if roast is not running, ignore updates
            guard let roast = self.roast, roast.isRunning else { return }
            
            let tempC = DegreesC(tempC)
//            print("Updated temp 2 (ET): \(tempC)°C (\(tempC.asFahrenheit())°F)")
            // add sample to roast
            roast.addEtSample(temp: Double(tempC))
            
            // add sample to chart
            guard let sample = roast.etCurve?.lastObject as? EtSample else { return }
            self.chartView.data!.addEntry(ChartDataEntry(x: sample.time, y: sample.tempC.asFahrenheit()), dataSetIndex: RoastDataSetIndex.et.rawValue)
            self.chartView.notifyDataSetChanged()
        }
    }
}

extension RoastViewController {
    private func setupLineChart() {
        chartView.configRoastChart()
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
}

