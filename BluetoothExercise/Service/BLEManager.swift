//
//  BLEManager.swift
//  BluetoothExercise
//
//  Created by LoganMacMini on 2024/4/13.
//

import Foundation
import CoreBluetooth

protocol BLEMangerDelegate {
    func state(state: BLEManager.State)
    func list(list: [BLEManager.Peripheral])
    func value(data: Data)
}


final class BLEManager: NSObject {
    
    var characteristicData: [CBCharacteristic] = []
    var peripherals: [Peripheral] = []
    
    static let shared = BLEManager()
    var delegate: BLEMangerDelegate?
    var centralManager : CBCentralManager!
    var myPeripheral: CBPeripheral!
    
    var state: State = .unknown {
        didSet {
            delegate?.state(state: state)
        }
    }
    
    private var readCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    
    private override init() {}
    
    func setupBLE() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan() {
        print("Now scanning...")
        peripherals.removeAll()
        
        //掃描藍牙裝置
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerRestoredStateScanOptionsKey: true])
    }
    
    func stopScan() {
        print("stopScanning")
        peripherals.removeAll()
        centralManager.stopScan()
    }
    
    ///連線藍牙裝置
    func connect(_ peripheral: CBPeripheral) {
        if myPeripheral != nil {
            guard let myPeripheral = myPeripheral else { return }
            centralManager.cancelPeripheralConnection(myPeripheral)
            centralManager.connect(peripheral, options: nil)
        } else {
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func disconnect() {
        guard let myPeripheral = myPeripheral else { return }
        centralManager.cancelPeripheralConnection(myPeripheral)
    }
    
    ///將值寫入characteristic
    func send(_ value: [UInt8]) {//send value BLE
        guard let characteristic = writeCharacteristic else { return }
        myPeripheral?.writeValue(Data(value), for: characteristic, type: .withResponse)
    }
}

extension BLEManager {
    
    enum State {
        case unknown,
             resetting,
             unsupported,
             unauthorized,
             poweredOff,
             poweredOn,
             error,
             connected,
             disconnected
    }

    struct Peripheral: Identifiable {
        let id: Int
        let rssi: Int
        let uuid: String
        let peripheral: CBPeripheral
    }
    
    func convertState(peripheralState: CBPeripheralState) -> State {
        switch peripheralState {
        case .disconnected:
            return .disconnected
        case .connecting:
            return .unknown
        case .connected:
            return .connected
        case .disconnecting:
            return .disconnected
        @unknown default:
            return .unknown
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch centralManager.state {
        case .unknown:
            state = .unknown
        case .resetting:
            state = .resetting
        case .unsupported:
            state = .unsupported
        case .unauthorized:
            state = .unauthorized
        case .poweredOff:
            state = .poweredOff
        case .poweredOn:
            state = .poweredOn
        default: state = .unknown
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print(peripheral)
        
        let uuid = String(describing: peripheral.identifier)
        let filtered = peripherals.filter { $0.uuid == uuid }
        
        if filtered.count == 0 {
            guard let _ = peripheral.name else { return }
            let newPeripheral = Peripheral(id: peripherals.count, rssi: RSSI.intValue, uuid: uuid, peripheral: peripheral)
            peripherals.append(newPeripheral)
            delegate?.list(list: peripherals)
        }
    }
    
    ///若連線失敗後會觸發didConnect
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        guard let error = error else { return }
        print(error.localizedDescription)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        myPeripheral = nil
        state = .disconnected
    }
    
    ///若連線成功後會觸發didConnect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        myPeripheral = peripheral
        state = .connected
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        centralManager.stopScan()
    }
}

///當連線成功後，即可讀取peripheral的service、characteristic以及descriptor
extension BLEManager: CBPeripheralDelegate {
    
    ///讀取peripheral的service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print(peripheral.discoverCharacteristics(nil, for: service))
        }
    }
    
    ///讀取service底下的characterisitic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            //檢查characteristic支援哪些功能
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
                }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil else {
            print("Error write value for characteristic: \(error?.localizedDescription ?? "")")
            return
        }
        print("Write succeed")
    }
    
    ///接收數據
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            print("Error reading characteristic \(characteristic.uuid): \(error.localizedDescription)")
            return
        }
        
        if let data = characteristic.value {
            // 印出characteristic收到的data
            print("Received data from \(characteristic.uuid): \(data as NSData)")
            delegate?.value(data: data)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        myPeripheral = peripheral
        state = convertState(peripheralState: peripheral.state)
        
        peripheral.discoverServices(nil)
    }
}
