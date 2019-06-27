//
//  Roast+CoreDataClass.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 5/14/19.
//  Copyright © 2019 KK. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Roast)
public class Roast: NSManagedObject {
    
    var elapsedTime: TimeInterval {
        guard let startTimestamp = startTimestamp else { return 0 }
        return Date().timeIntervalSince(startTimestamp)
    }
    
    var isRunning: Bool {
        return startTimestamp != nil && stopTime == 0
    }
    
    func start() {
        guard !isRunning else { log.warning("Roast already running"); return }  // only start if not running
        startTimestamp = Date()
    }
    
    func markFirstCrackStart() {
        guard isRunning else { log.warning("Roast not running"); return }
        firstCrackStartTime = elapsedTime
        log.info("1st crack start: \(firstCrackStartTime) sec")
    }
    
    func markFirstCrackEnd() {
        guard isRunning else { log.warning("Roast not running"); return }
        firstCrackEndTime = elapsedTime
        log.info("1st crack end: \(firstCrackEndTime) sec")
    }
    
    func marcSecondCrackStart() {
        guard isRunning else { log.warning("Roast not running"); return }
        secondCrackStartTime = elapsedTime
        log.info("2nd crack start: \(secondCrackStartTime) sec")
    }
    
    func marcSecondCrackEnd() {
        guard isRunning else { log.warning("Roast not running"); return }
        secondCrackEndTime = elapsedTime
        log.info("2nd crack: \(secondCrackEndTime) sec")
    }
    
    func stop() {
        guard isRunning else { log.warning("Roast not running"); return }     // only stop if running
        stopTime = elapsedTime
        log.info("Stopped roast: \(stopTime) sec")
    }
    
    fileprivate func makeTimestamp(time: TimeInterval?) -> TimeInterval? {
        // only add samples if roast hasn't been stopped
        guard stopTime == 0 else { log.warning("Roast stopped"); return nil }
        
        switch (time, startTimestamp) {
        case let (nil, startTimestamp?):        // no time provided, requires startTimestamp
            return Date().timeIntervalSince(startTimestamp)
        case let (time?, _):                    // time provided, ignore startTimestamp
            return time
        default:                                // no time provided and roast hasn't started
            log.warning("No timestamp available")
            return nil                          // ignore sample
        }
    }
    
    func addBtSample(temp: DegreesC, time: TimeInterval? = nil) {
        guard let time = makeTimestamp(time: time),
              let context = managedObjectContext else {
            log.warning("BT sample ignored")
            return
        }
        
        let sample = BtSample(context: context)
        sample.time = time
        sample.tempC = temp
        
        addToBtCurve(sample)
    }
    
    func addEtSample(temp: DegreesC, time: TimeInterval? = nil) {
        guard let time = makeTimestamp(time: time),
              let context = managedObjectContext else {
            log.warning("ET sample ignored")
            return
        }
        
        let sample = EtSample(context: context)
        sample.time = time
        sample.tempC = temp
        
        addToEtCurve(sample)
    }
}

public extension Roast {
    func asCsv() -> String {
        var csv = "t(s),bt(C),bt(F),t(s),et(C),et(F)\n"
        
        var i = 0
        var btVal: BtSample?
        var etVal: EtSample?
        
        
        repeat {
            btVal = (btCurve?.count ?? 0) > i ? btCurve?.object(at: i) as? BtSample : nil
            etVal = (etCurve?.count ?? 0) > i ? etCurve?.object(at: i) as? EtSample : nil
            
            csv += "\(btVal?.time ?? 0),\(btVal?.tempC ?? 0),\(btVal?.tempC.asFahrenheit() ?? 0),\(etVal?.time ?? 0),\(etVal?.tempC ?? 0),\(etVal?.tempC.asFahrenheit() ?? 0)\n"
            i += 1
        } while btVal != nil || etVal != nil
        
//        print(csv)
        return csv
    }
    
    func loadSampleCsv() {
        let path = Bundle.main.path(forResource: "SampleRoast", ofType: "csv")
        let data = try! String(contentsOfFile: path!)
        
        for line in data.components(separatedBy: "\n")[1...] {
            var time: Int = 0
            var beanTemp: DegreesC = 0
            var envTemp: DegreesC = 0
            
            for (idx, column) in line.components(separatedBy: ",").enumerated() {
                switch idx {
                case 1:
                    let timeParts = column.components(separatedBy: ":")
                    time = Int(timeParts[0])! * 60 + Int(timeParts[1])!
                case 2:
                    // this sample csv has temps in F, need to convert to C
                    beanTemp = Double(column)!.asCelcius()
                case 3:
                    envTemp = Double(column)!.asCelcius()
                default:
                    // nothing
                    break
                }
            }
            
            addBtSample(temp: beanTemp, time: TimeInterval(time))
            addEtSample(temp: envTemp, time: TimeInterval(time))
        }
        
        log.info("Loaded \(btCurve?.count ?? 0) samples")
    }
    
    func printData() {
        
    }
}
