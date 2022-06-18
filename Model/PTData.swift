//
//  PTData.swift
//  PowderThrow
//
//  Created by David Veach on 6/16/22.
//

import Foundation

struct Config {
    static var preset = Int16(0)
    static var fscaleP = Float32(0.0)
    static var decel_threshold = Float32(0.0)
    static var bump_threshold = Float32(0.0)
    static var decel_limit = Int16(0)
    static var gn_tolerance = Float32(0.0)
    static var mg_tolerance = Float32(0.0)
    static var config_version = Int16(0)

}

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
