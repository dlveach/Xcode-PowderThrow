//
//  PTData.swift
//  PowderThrow
//
//  Created by David Veach on 6/16/22.
//

import Foundation

struct _config_data {
    var preset = Int16(0)
    var fscaleP = Float32(0.0)
    var decel_threshold = Float32(0.0)
    var bump_threshold = Float32(0.0)
    var decel_limit = Int16(0)
    var gn_tolerance = Float32(0.0)
    var mg_tolerance = Float32(0.0)
    var config_version = Int16(0)
}
var ConfigData = _config_data()

struct PresetListItem {
     var index = Int16(0)
     var name = String("")
}

var PresetList: [PresetListItem] = []

struct BLE_COMMANDS {
    static let SETTINGS = Int8(0x01)
    static let CURRENT_PRESET = Int8(0x10)
    static let PRESET_BY_INDEX = Int8(0x20)
    static let CURRENT_POWDER = Int8(0x30)
    static let POWDER_BY_INDEX = Int8(0x40)

}
