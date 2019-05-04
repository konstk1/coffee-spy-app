//
//  Roast.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 4/30/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

public final class MyRoast {
    var startTimestamp: Date?
    
    var fcTime: TimeInterval?
    var scTime: TimeInterval?
    var stopTime: TimeInterval?
    
    var elapsedTime: TimeInterval {
        guard let startTimestamp = startTimestamp else { return 0 }
        return Date().timeIntervalSince(startTimestamp)
    }
    
    var isRunning: Bool {
        return startTimestamp != nil && stopTime == nil
    }
    
    public var btCurve = [TempSample]()
    public var etCurve = [TempSample]()
    
    public init() {
        
    }
    
    func start() {
        startTimestamp = Date()
        stopTime = nil
        fcTime = nil
        scTime = nil
    }
    
    func markFC() {
        fcTime = elapsedTime
    }
    
    func marcSC() {
        scTime = elapsedTime
    }
    
    func stop() {
        stopTime = elapsedTime
    }
    
    func addBtSample(temp: Double, time: TimeInterval? = nil) {
        var sampleTime: TimeInterval
        
        if time == nil, let startTimestamp = startTimestamp {
            sampleTime = Date().timeIntervalSince(startTimestamp)
        } else if let time = time {
            sampleTime = time
        } else {
            return
        }
        
        btCurve.append(TempSample(time: sampleTime, temp: temp))
    }
    
    func addEtSample(temp: Double, time: TimeInterval? = nil) {
        guard let startTimestamp = startTimestamp else { return }

        let time = time ?? Date().timeIntervalSince(startTimestamp)
        etCurve.append(TempSample(time: time, temp: temp))
    }
}

extension MyRoast {
    public func loadSampleCsv() {
        let data = try! String(contentsOf: URL(fileURLWithPath: "/Users/kon/Library/Developer/Xcode/DerivedData/coffee-spy-gxhfygvqgfbdlpaxoxhbghrgxvta/Build/Products/Debug/SampleRoast.csv"))
        
        print(data)
        
        for line in data.components(separatedBy: "\n")[1...] {
            var time: Int = 0
            var beanTemp: Double = 0
            var envTemp: Double = 0
            
            for (idx, column) in line.components(separatedBy: ",").enumerated() {
                switch idx {
                case 1:
                    let timeParts = column.components(separatedBy: ":")
                    time = Int(timeParts[0])! * 60 + Int(timeParts[1])!
                case 2:
                    beanTemp = Double(column)!
                case 3:
                    envTemp = Double(column)!
                default:
                    // nothing
                    break
                }
            }
            
            addBtSample(temp: beanTemp, time: TimeInterval(time))
            addEtSample(temp: envTemp, time: TimeInterval(time))
        }
        
        print("Loaded \(btCurve.count) samples")
    }
    
    public func printData() {
        
    }
}

public struct TempSample {
    public var time: TimeInterval
    public var temp: Double
}
