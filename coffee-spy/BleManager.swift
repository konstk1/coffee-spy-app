//
//  BleManager.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 4/29/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import CoreBluetooth

let coffeeSpyServiceUUID = CBUUID(string: "CFFE")
let coffeeTemp1CharServiceUUID = CBUUID(string: "FE01")
let coffeeTemp2CharServiceUUID = CBUUID(string: "FE02")

protocol BleManagerDelegate: class {
    func didConnect()
    func didDisconnect()
    func didUpdateTemperature1(tempC: Int)
    func didUpdateTemperature2(tempC: Int)
}

final class BleManager: NSObject {
    static var shareInstance = BleManager()
    
    var delegate: BleManagerDelegate?
    
    private var centralManager: CBCentralManager!
    private var coffeeSpyPeriph: CBPeripheral!
    
    private var simTimer: Timer?
    
    fileprivate override init() {
        super.init()
        let centralQueue = DispatchQueue(label: "coffee.ble-central")
        centralManager = CBCentralManager(delegate: self, queue: centralQueue, options: [CBCentralManagerOptionShowPowerAlertKey: NSNumber(value: true)])
    }
    
    fileprivate func scan() {
    #if targetEnvironment(simulator)
        startSimulation()
    #else
        centralManager.scanForPeripherals(withServices: [coffeeSpyServiceUUID], options: nil)
        print("BLE scanning...")
    #endif
    }
    
    func disconnect() {
        guard let periph = coffeeSpyPeriph else { return }
        print("BLE disconnecting coffee-spy")
        centralManager.cancelPeripheralConnection(periph)
    }
    
    fileprivate func startSimulation() {
        print("BLE Simulation...")
        var i = 0
        let roast = MyRoast()
        roast.loadSampleCsv()
        DispatchQueue.main.async {
            self.simTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] (timer) in
                let (btSample, etSample) = (roast.btCurve[i % roast.btCurve.count], roast.etCurve[i % roast.btCurve.count])
                self?.delegate?.didUpdateTemperature1(tempC: Int(btSample.temp))
                self?.delegate?.didUpdateTemperature2(tempC: Int(etSample.temp))
                i += 1
            }
        }
    }
}

extension BleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
            #if targetEnvironment(simulator)
            scan()
            #endif
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            scan()
        @unknown default:
            print("central.state is @unknown default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered coffee-spy, connecting...")
        coffeeSpyPeriph = peripheral
        coffeeSpyPeriph.delegate = self
        // TODO: enable ble backround mode
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to coffee-spy")
        delegate?.didConnect()
        coffeeSpyPeriph.discoverServices([coffeeSpyServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to coffee-spy: \(String(describing: error))")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from coffee-spy")
        delegate?.didDisconnect()
    }
}

extension BleManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        print("Discovered coffee-spy service")
        for service in services {
            print("   \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        print("Discovered characteristics")
        for char in chars {
            print("   \(char)")
            
            if char.uuid == coffeeTemp1CharServiceUUID {
                print("Found Temp 1 char")
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char)
                }
            } else if char.uuid == coffeeTemp2CharServiceUUID {
                print("Found Temp 2 char")
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        
        let tempC: Int32 = value.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian
        print("Updated char \(characteristic) with \(tempC)")
        
        switch characteristic.uuid {
        case coffeeTemp1CharServiceUUID:
            delegate?.didUpdateTemperature1(tempC: Int(tempC))
        case coffeeTemp2CharServiceUUID:
            delegate?.didUpdateTemperature2(tempC: Int(tempC))
        default:
            print("BLE: Notify on unknown char")
            break
        }
    }
}
