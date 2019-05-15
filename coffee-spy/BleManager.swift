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
    func didConnect(uuidStr: String)
    func didDisconnect()
    func didUpdateTemperature1(tempC: Int)
    func didUpdateTemperature2(tempC: Int)
}

final class BleManager: NSObject {
    static var shared = BleManager()
    
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
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            self?.startSimulation()
        }
    #else
        centralManager.scanForPeripherals(withServices: [coffeeSpyServiceUUID], options: nil)
        log.info("BLE scanning...")
    #endif
    }
    
    func disconnect() {
        guard let periph = coffeeSpyPeriph else { return }
        log.info("BLE disconnecting coffee-spy")
        centralManager.cancelPeripheralConnection(periph)
    }
    
    fileprivate func startSimulation() {
        log.info("BLE Simulation...")
        delegate?.didConnect(uuidStr: "SIM0")
        var i = 0
        let context = DataController.shared.makeChildContext()
        let roast = Roast(context: context)
        roast.loadSampleCsv()
        DispatchQueue.main.async {
            self.simTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] (timer) in
                let context = context
                let (btSample, etSample) = (roast.btCurve!.object(at: i % roast.btCurve!.count) as! BtSample, roast.etCurve!.object(at: i % roast.etCurve!.count) as! EtSample)
                self?.delegate?.didUpdateTemperature1(tempC: Int(btSample.tempC))
                self?.delegate?.didUpdateTemperature2(tempC: Int(etSample.tempC))
                i += 1
            }
        }
    }
}

extension BleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            log.warning("central.state is .unknown")
        case .resetting:
            log.warning("central.state is .resetting")
        case .unsupported:
            log.warning("central.state is .unsupported")
            #if targetEnvironment(simulator)
            scan()
            #endif
        case .unauthorized:
            log.warning("central.state is .unauthorized")
        case .poweredOff:
            log.warning("central.state is .poweredOff")
        case .poweredOn:
            log.verbose("central.state is .poweredOn")
            scan()
        @unknown default:
            log.error("central.state is @unknown default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        log.verbose("Discovered coffee-spy, connecting...")
        coffeeSpyPeriph = peripheral
        coffeeSpyPeriph.delegate = self
        // TODO: enable ble backround mode
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.info("Connected to coffee-spy")
        delegate?.didConnect(uuidStr: peripheral.identifier.uuidString)
        coffeeSpyPeriph.discoverServices([coffeeSpyServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.error("Failed to connect to coffee-spy: \(String(describing: error))")
        coffeeSpyPeriph = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log.info("Disconnected from coffee-spy")
        coffeeSpyPeriph = nil
        delegate?.didDisconnect()
    }
}

extension BleManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        log.verbose("Discovered coffee-spy service")
        for service in services {
            print("   \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        log.verbose("Discovered characteristics")
        for char in chars {
            print("   \(char)")
            
            if char.uuid == coffeeTemp1CharServiceUUID {
                log.verbose("Found Temp 1 char")
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char)
                }
            } else if char.uuid == coffeeTemp2CharServiceUUID {
                log.verbose("Found Temp 2 char")
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else { return }
        
        let tempC: Int32 = value.withUnsafeBytes { $0.load(as: Int32.self) }.bigEndian
        log.verbose("Updated char \(characteristic) with \(tempC)")
        
        switch characteristic.uuid {
        case coffeeTemp1CharServiceUUID:
            delegate?.didUpdateTemperature1(tempC: Int(tempC))
        case coffeeTemp2CharServiceUUID:
            delegate?.didUpdateTemperature2(tempC: Int(tempC))
        default:
            log.warning("BLE: Notify on unknown char")
            break
        }
    }
}
