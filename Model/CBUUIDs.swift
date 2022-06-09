//
//  CBUUIDs.swift
//  BLEButton
//
//  Created by David Veach on 3/10/22.
//

import Foundation
import CoreBluetooth

struct CBUUIDs{

    static let kBLEService_UUID = "970a6f6e-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_Btn_UUID = "970a71b2-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_Weight_UUID = "970a745a-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_Target_UUID = "970a75a4-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_Cond_UUID = "970a769e-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_State_UUID = "970a77a2-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_Decel_Thresh_UUID = "970a7892-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_Config_Data_UUID = "970a798c-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_Preset_Name_UUID = "970a7aae-e01b-11ec-9d64-0242ac120002"
    static let kBLE_Characteristic_Powder_Name_UUID = "970a7c20-e01b-11ec-9d64-0242ac120002"
    
    static let MaxCharacters = 30

    static let BLEService_UUID = CBUUID(string: kBLEService_UUID)
    static let BLE_Characteristic_Btn_UUID = CBUUID(string: kBLE_Characteristic_Btn_UUID)
    static let BLE_Characteristic_Weight_UUID = CBUUID(string: kBLE_Characteristic_Weight_UUID)
    static let BLE_Characteristic_Target_UUID = CBUUID(string: kBLE_Characteristic_Target_UUID)
    static let BLE_Characteristic_Cond_UUID = CBUUID(string: kBLE_Characteristic_Cond_UUID)
    static let BLE_Characteristic_State_UUID = CBUUID(string: kBLE_Characteristic_State_UUID)
    static let BLE_Characteristic_Decel_Thresh_UUID = CBUUID(string: kBLE_Characteristic_Decel_Thresh_UUID)
    static let BLE_Characteristic_Config_Data_UUID = CBUUID(string: kBLE_Characteristic_Config_Data_UUID)
    static let BLE_Characteristic_Preset_Name_UUID = CBUUID(string: kBLE_Characteristic_Preset_Name_UUID)
    static let BLE_Characteristic_Powder_Name_UUID = CBUUID(string: kBLE_Characteristic_Powder_Name_UUID)
}

