//
//  ViewModel.swift
//  BluetoothExercise
//
//  Created by LoganMacMini on 2024/4/13.
//

import Foundation

final class ViewModel {
    
    var bluetooth: BLEManager = BLEManager.shared
    
    var list: [BLEManager.Peripheral] = []
    
    init(bluetooth: BLEManager = BLEManager.shared) {
        setupBLE()
    }
    
    func setupBLE() {
        bluetooth.setupBLE()
    }
    
    func startScan() {
        bluetooth.startScan()
    }
    
    func stopScan() {
        list.removeAll()
        bluetooth.stopScan()
    }
}
