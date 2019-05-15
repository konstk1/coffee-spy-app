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
        guard !isRunning else { print("Warning: starting running roast"); return }  // only start if not running
        startTimestamp = Date()
    }
    
    func markFC() {
        firstCrackTime = elapsedTime
    }
    
    func marcSC() {
        secondCrackTime = elapsedTime
    }
    
    func stop() {
        guard isRunning else { print("Warning: stopping non-running roast"); return }     // only stop if running
        stopTime = elapsedTime
    }
    
    fileprivate func makeTimestamp(time: TimeInterval?) -> TimeInterval? {
        // only add samples if roast hasn't been stopped
        guard stopTime == 0 else { print("Warning: roast stopped"); return nil }
        
        switch (time, startTimestamp) {
        case let (nil, startTimestamp?):        // no time provided, requires startTimestamp
            return Date().timeIntervalSince(startTimestamp)
        case let (time?, _):                    // time provided, ignore startTimestamp
            return time
        default:                                // no time provided and roast hasn't started
            print("Warning: no timestamp available")
            return nil                          // ignore sample
        }
    }
    
    fileprivate func makeSample(time: TimeInterval?) -> TimeInterval? {
        // only add samples if roast hasn't been stopped
        guard stopTime == 0 else { print("Warning: roast stopped"); return nil }
        
        switch (time, startTimestamp) {
        case let (nil, startTimestamp?):        // no time provided, requires startTimestamp
            return Date().timeIntervalSince(startTimestamp)
        case let (time?, _):                    // time provided, ignore startTimestamp
            return time
        default:                                // no time provided and roast hasn't started
            print("Warning: no timestamp available")
            return nil                          // ignore sample
        }
    }
    
    func addBtSample(temp: DegreesC, time: TimeInterval? = nil) {
        guard let time = makeTimestamp(time: time),
              let context = managedObjectContext else {
            print("Warning: BT sample ignored")
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
            print("Warning: ET sample ignored")
            return
        }
        
        let sample = EtSample(context: context)
        sample.time = time
        sample.tempC = temp
        
        addToEtCurve(sample)
    }
}

public extension Roast {
    func loadSampleCsv() {
        let path = Bundle.main.path(forResource: "SampleRoast", ofType: "csv")
        print(path)
        let data = try! String(contentsOfFile: path!)
        
        //        print(data)
        
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
        
        print("Loaded \(btCurve?.count ?? 0) samples")
    }
    
    func printData() {
        
    }
}
