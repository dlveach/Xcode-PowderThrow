//
//  BlePeripheral.swift
//  BLEButton
//
//  Created by David Veach on 3/10/22.
//

import Foundation
import CoreBluetooth

class BlePeripheral {
    static var connectedPeripheral: CBPeripheral?
    static var connectedService: CBService?
    static var connectedBtnChar: CBCharacteristic?
    static var connectedRespChar: CBCharacteristic?
    static var connectedWeightChar: CBCharacteristic?
    static var connectedTargetChar: CBCharacteristic?
    static var connectedCondChar: CBCharacteristic?
    static var connectedStateChar: CBCharacteristic?
    static var connectedDecelThreshChar: CBCharacteristic?
    static var connectedConfigDataChar: CBCharacteristic?
    static var connectedPresetDataChar: CBCharacteristic?
    static var connectedPowderDataChar: CBCharacteristic?
    static var connectedParameterCommandChar: CBCharacteristic?
    static var connectedPresetListItemChar: CBCharacteristic?
    
    func writeParameterCommand(cmd: Int8, parameter: Int8) {
        let _data: [Int8] = [cmd, parameter]
        print("TRACE: BlePerhipheral:writeParameterCommand()")
        print("_data is \(String(describing: _data))")
        print("Size of _data is \(_data.count)")
        let outgoingData = NSData(bytes: _data, length: _data.count)
        BlePeripheral.connectedPeripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedParameterCommandChar!, type: CBCharacteristicWriteType.withResponse)
    }

}
