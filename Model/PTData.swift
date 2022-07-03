//
//  PTData.swift
//  PowderThrow
//
//  Created by David Veach on 6/16/22.
//
//  TODO:
//      - align buffer size (stride) with Arduino bit sizes (I.E. Float32, Int32, etc.)

import Foundation

let MAX_NAME_LEN = 16
let GM_TO_GN_FACTOR: Float = Float(0.06479891)

// MARK: - Config Data
public struct _config_data {
    var preset = Int16(0)
    var fscaleP = Float32(0.0)
    var decel_threshold = Float32(0.0)
    var bump_threshold = Float32(0.0)
    var decel_limit = Int16(0)
    var gn_tolerance = Float32(0.0)
    var mg_tolerance = Float32(0.0)
    var config_version = Int16(0)
}

public var g_configData = _config_data()

// MARK: - Preset Manager
protocol PresetChangeListener: AnyObject {
    func presetChanged(to new_preset: PresetManager.PresetData)
}

let g_preset_manager = PresetManager()

class PresetManager {
    struct PresetData {
        var preset_number: Int32 = Int32(0)
        var charge_weight: Float = Float32(0.0)
        var powder_index: Int32 = Int32(0)
        var preset_name: String = String("                ")
        var bullet_name: String = String("                ")
        var bullet_weight: Int32 = Int32(0)
        var brass_name: String = String("                ")
        var preset_version: Int32 = Int32(0)
    }
        
    private var _currentPresetData: PresetData
    private(set) var loaded: Bool
    private(set) var isLoading: Bool
    private var preset_name_list: [String]
    private(set) var count: Int
    private var listeners: [PresetChangeListener]
    
    init() {
        loaded = false
        isLoading = true;
        preset_name_list = []
        _currentPresetData = PresetData()
        count = 0
        listeners = []
    }
    
    // Reset the object back to init() state
    func reset() {
        loaded = false
        isLoading = true;
        preset_name_list = []
        _currentPresetData = PresetData()
        count = 0
        listeners = []
    }
    
    // Invoke the "changed" method on all listeners
    func invoke() {
        print("PresetManager.invoke()")
        for listener in listeners {
            listener.presetChanged(to: currentPreset)
        }
    }
    
    // Add a listener to the list of listeners
    func addListener(_ listener: PresetChangeListener) {
        listeners.append(listener)
        print("---->  there are now \(listeners.count) preset listeners")
    }
    
    // Remove a specific listener from the list of listeners
    func removeListener(_ listener: PresetChangeListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }

    func setPresetPowder(_ index: Int32) {
        _currentPresetData.powder_index = index
        invoke()
    }
    
    var currentPreset: PresetData {
        get {
            return _currentPresetData
        }
        set {
            _currentPresetData = newValue
            invoke()
        }
    }
    
    func addListItem(_ name: String) {
        print("addListItem()")
        preset_name_list.append(name)
        count = preset_name_list.count
        if count == 50 {
            loaded = true
            isLoading = false
        }
    }

    func updateListItem(_ name: String, index: Int) {
        print("updateListItem()")
        if isLoading { return }
        if index > 0 && index < 50 {
            preset_name_list[index] = name
        } else {
            print("ERROR: updateListItemAt(): preset list index out of range.")
        }
    }
    
    func getListItemAt(_ index: Int) -> String {
        if index < 0 || index >= 50 {
            print("ERROR: getListItemAt(): preset list index out of range.")
            return "";  // better return val?  nil?
        }
        return preset_name_list[index]
    }

    func BLEWritePresetData() {
        print("BLEWritePresetData()")
        // trying a HACK: to get the preset data structure into bytes to send over BLE.
        let preset_number_data = Data(bytes: &_currentPresetData.preset_number, count: MemoryLayout<Int32>.stride)
        let charge_weight_data = Data(bytes: &_currentPresetData.charge_weight, count: MemoryLayout<Float32>.stride)
        let powder_index_data = Data(bytes: &_currentPresetData.powder_index, count: MemoryLayout<Int32>.stride)
        let bullet_weight_data = Data(bytes: &_currentPresetData.bullet_weight, count: MemoryLayout<Int32>.stride)
        let preset_version_data = Data(bytes: &_currentPresetData.preset_version, count: MemoryLayout<Int32>.stride)
        var preset_name_data = _currentPresetData.preset_name.data(using: String.Encoding.utf8)
        preset_name_data!.append(0)
        var bullet_name_data = _currentPresetData.bullet_name.data(using: String.Encoding.utf8)
        bullet_name_data!.append(0)
        var brass_name_data = _currentPresetData.brass_name.data(using: String.Encoding.utf8)
        brass_name_data!.append(0)

        var data_to_send: Data = preset_number_data
        data_to_send.append(charge_weight_data)
        data_to_send.append(powder_index_data)
        data_to_send.append(contentsOf: preset_name_data!)
        data_to_send.append(contentsOf: bullet_name_data!)
        data_to_send.append(bullet_weight_data)
        data_to_send.append(contentsOf: brass_name_data!)
        data_to_send.append(preset_version_data)
        
        print("bytes to send: \(data_to_send.count)")
        print("data_to_send: \(String(describing: Array(data_to_send)))")
        
        BlePeripheral().writePresetData(outgoingData: data_to_send)
    }

}

// MARK: - Powder Manager
protocol PowderChangeListener: AnyObject {
    func powderChanged(to new_powder: PowderManager.PowderData)
}

let g_powder_manager = PowderManager()

class PowderManager {
    struct PowderData {
        var powder_number: Int = Int(0) //<- TODO: fix Int32
        var powder_name: String = String("")
        var powder_factor: Float = Float(0.0) //<- TODO: fix Float32
        var powder_version: Int16 = Int16(0) //<- TODO: fix Int32
    }

    // Data for the current preset
    private var _currentPowder: PowderData
    private(set) var loaded: Bool
    private(set) var isLoading: Bool
    private var powder_name_list: [String]
    private(set) var count: Int
    private var listeners: [PowderChangeListener]
    
    init() {
        loaded = false
        isLoading = true;
        powder_name_list = []
        count = 0
        _currentPowder = PowderData()
        listeners = []
    }
    
    // Reset the object back to init() state
    func reset() {
        loaded = false
        isLoading = true;
        powder_name_list = []
        count = 0
        _currentPowder = PowderData()
        listeners = []
    }

    // Invoke the "changed" method on all listeners
    func invoke() {
        for listener in listeners {
            listener.powderChanged(to: _currentPowder)
        }
    }
    
    // Add a listener to the list of listeners
    func addListener(_ listener: PowderChangeListener) {
        listeners.append(listener)
    }
    
    // Remove a specific listener from the list of listeners
    func removeListener(_ listener: PowderChangeListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }

    // Access to current powder data
    var currentPowder: PowderData {
        get {
            return _currentPowder
        }
        set {
            _currentPowder = newValue
            invoke()
        }
    }

    func addListItem(_ name: String) {
        print("addListItem()")
        powder_name_list.append(name)
        count = powder_name_list.count
        if count == 25 {
            loaded = true
            isLoading = false
        }
    }

    func updateListItem(_ name: String, index: Int) {
        print("updateListItem()")
        if isLoading { return }
        if index >= 0 && index < 25 {
            powder_name_list[index] = name
        } else {
            print("ERROR: updateListItem(): powder list index out of range.")
        }
    }
    
    func getListItemAt(_ index: Int) -> String {
        if index < 0 || index >= 25 {
            print("ERROR: getListItemAt(): powder list index out of range.")
            return "";  // better return val?  nil?
        }
        return powder_name_list[index]
    }
}

// MARK: - RunData Manager
protocol RunDataChangeListener: AnyObject {
    func runDataChanged(to new_data: RunDataManager.RunData)
}

let g_rundata_manager = RunDataManager()

class RunDataManager {
    
    struct RunData {
        var system_state: Int32 = Int32(0)
        var scale_value: Float32 = Float32(0.0)
        var scale_in_grains: Bool = true
        var scale_cond: Int32 = Int32(0)
        var decel_thresh: Float32 = Float32(0.0)
        var target_weight: Float32 = Float32(0.0)
        var powder_name: String = String("")
        var preset_name: String = String("")
    }

    enum system_state: Int32 {
        case Undefined
        case Error
        case Setup
        case Ready
        case Throwing
        case Trickling
        case Bumping
        case Paused
        case Locked
        case Menu
        case Settings
        case Manual
        case Manual_Throw
        case Manual_Trickle
        case Calibrate_Trickler
        case Calibrate_Scale
        case Powders
        case Powders_Edit
        case Presets
        case Presets_Edit
        var description: String {
            return "\(self)".replacingOccurrences(of: "_", with: " ")
        }
    }
    
    enum scale_cond: Int32 {
        case Not_Ready
        case Zero
        case Pan_Off
        case Under_Target
        case Close
        case Very_Close
        case On_Target
        case Over_Target
        case Undefined
        var description: String {
            return "\(self)".replacingOccurrences(of: "_", with: " ")
        }
    }
    
    // Data for the current preset
    private var _current: RunData
    private var listeners: [RunDataChangeListener]

    init() {
        _current = RunData()
        listeners = []
    }
    
    // Reset the object back to init() state
    func reset() {
        _current = RunData()
        listeners = []
    }

    // Invoke the "changed" method on all listeners
    func invoke() {
        for listener in listeners {
            listener.runDataChanged(to: _current)
        }
    }
    
    // Add a listener to the list of listeners
    func addListener(_ listener: RunDataChangeListener) {
        listeners.append(listener)
    }
    
    // Remove a specific listener from the list of listeners
    func removeListener(_ listener: RunDataChangeListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }

    // Access to current powder data
    var currentRunData: RunData {
        get {
            return _current
        }
        set {
            _current = newValue
            invoke()
        }
    }

}
