//
//  BlePeripheral.swift
//  PowderThrow
//
//  Created by David Veach on 3/10/22.
//

import Foundation
import CoreBluetooth

struct BLE_COMMANDS {
    static let SETTINGS = Int8(0x01)
    static let SET_CURRENT_PRESET = Int8(0x20)
    static let PRESET_DATA_BY_INDEX = Int8(0x21)
    static let PRESET_NAME_BY_INDEX = Int8(0x22)
    static let SET_CURRENT_POWDER = Int8(0x30)
    static let POWDER_DATA_BY_INDEX = Int8(0x31)
    static let POWDER_NAME_BY_INDEX = Int8(0x32)
    static let SET_SYSTEM_STATE = Int8(0x50)
}

class BlePeripheral {
    static var connectedPeripheral: CBPeripheral?
    static var connectedService: CBService?
    static var connectedParameterCommandChar: CBCharacteristic?
    static var connectedWeightChar: CBCharacteristic?
    static var connectedTargetChar: CBCharacteristic?
    static var connectedCondChar: CBCharacteristic?
    static var connectedStateChar: CBCharacteristic?
    static var connectedDecelThreshChar: CBCharacteristic?
    static var connectedConfigDataChar: CBCharacteristic?
    static var connectedPresetDataChar: CBCharacteristic?
    static var connectedPresetListItemChar: CBCharacteristic?
    static var connectedPowderDataChar: CBCharacteristic?
    static var connectedPowderListItemChar: CBCharacteristic?
    
    func writeParameterCommand(cmd: Int8, parameter: Int8) {
        let _data: [Int8] = [cmd, parameter]
        let outgoingData = NSData(bytes: _data, length: _data.count)
        BlePeripheral.connectedPeripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedParameterCommandChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func writePresetData(outgoingData: Data) {
        print("BlePeripheral::writePresetData()")
        print("outgoingData.count: \(outgoingData.count)")
        BlePeripheral.connectedPeripheral?.writeValue(outgoingData, for: BlePeripheral.connectedPresetDataChar!, type: CBCharacteristicWriteType.withResponse)
    }
}

