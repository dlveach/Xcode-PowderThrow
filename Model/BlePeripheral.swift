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
}
