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
    static let CALIBRATE_TRICKLER_START = Int8(0x41)
    static let CALIBRATE_TRICKLER_CANCEL = Int8(0x42)
    static let CALIBRATE_SCALE = Int8(0x43)
    static let SYSTEM_SET_STATE = Int8(0x50)
    static let SYSTEM_ESTOP = Int8(0x51)
    static let SYSTEM_ENABLE = Int8(0x52)
    static let MANUAL_THROW = Int8(0x61)
    static let MANUAL_TRICKLE = Int8(0x62)
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
    static var connectedTricklerCalDataChar: CBCharacteristic?

    func writeParameterCommand(cmd: Int8, parameter: Int8) {
        let _data: [Int8] = [cmd, parameter]
        let outgoingData = NSData(bytes: _data, length: _data.count)
        BlePeripheral.connectedPeripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedParameterCommandChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func writeParameterCommandWithoutResponse(cmd: Int8, parameter: Int8) {
        let _data: [Int8] = [cmd, parameter]
        let outgoingData = NSData(bytes: _data, length: _data.count)
        //HACK: for some reason during trickler calibration no response ever is recieved
        //      and connection is lost (some kind of timeout?).  Using withoutResponse
        //      seems to avoid the issue but I'd like to figure out why it *only* happens
        //      during trickler calibration.  I'm callign BLE.poll() in the calibration loop so...
        BlePeripheral.connectedPeripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedParameterCommandChar!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    func writePresetData(outgoingData: Data) {
        print("BlePeripheral::writePresetData()")
        print("outgoingData.count: \(outgoingData.count)")
        BlePeripheral.connectedPeripheral?.writeValue(outgoingData, for: BlePeripheral.connectedPresetDataChar!, type: CBCharacteristicWriteType.withResponse)
    }

    func writePowderData(outgoingData: Data) {
        print("BlePeripheral::writePowderData()")
        print("outgoingData.count: \(outgoingData.count)")
        BlePeripheral.connectedPeripheral?.writeValue(outgoingData, for: BlePeripheral.connectedPowderDataChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func writeConfigData(outgoingData: Data) {
        print("BlePeripheral::writeConfigData()")
        print("outgoingData.count: \(outgoingData.count)")
        BlePeripheral.connectedPeripheral?.writeValue(outgoingData, for: BlePeripheral.connectedConfigDataChar!, type: CBCharacteristicWriteType.withResponse)
    }
}

