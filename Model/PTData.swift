//
//  PTData.swift
//  PowderThrow
//
//  Created by David Veach on 6/16/22.
//
//  TODO:
//      - align all buffer sizes (stride) with Arduino bit sizes (I.E. Float32, Int32, etc.)

import Foundation

// Constants and definitions (must match peripheral)
let MAX_NAME_LEN = 16
let MAX_PRESETS = 25
let MAX_POWDERS = 25
let GM_TO_GN_FACTOR: Float = Float(0.06479891)

// MARK: state variables

struct LadderData {
    var is_configured: Bool
    var step_count: Int32
    var current_step: Int32
    var start_weight: Float32
    var step_interval: Float32
}
var g_ladder_data = LadderData(is_configured: false, step_count: 0, current_step: 0, start_weight: 0.0, step_interval: 0.0)


// MARK: - Screen Manager
protocol ScreenChangeListener: AnyObject {
    func screenChanged(to new_screen: ScreenChangeManager.Screen)
}

let g_screen_manager = ScreenChangeManager()

class ScreenChangeManager {
    private var _screen: Screen
    private var listeners: [ScreenChangeListener]

    enum Screen: Int32 {
        case GoBack // maybe not gonna use this?
        case ViewController
        case RunThrowerViewController
        case SettingsViewController
        case PresetsViewController
        case PowdersViewController
        var description: String {
            return "\(self)"
        }
    }

    init() {
        _screen = Screen.ViewController
        listeners = []
    }
    func addListener(_ listener: ScreenChangeListener) {
        listeners.append(listener)
    }
    func removeListener(_ listener: ScreenChangeListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }
    func invoke() {
        for listener in listeners {
            listener.screenChanged(to: _screen)
        }
    }
    var currentScreen: Screen {
        get { return _screen }
        set {_screen = newValue; invoke() }
    }
}

// MARK: - Preset Manager

protocol PresetChangeListener: AnyObject {
    func presetChanged(to new_preset: PresetManager.PresetData)
}

let g_preset_manager = PresetManager()

class PresetManager {
    struct PresetData {
        var preset_version: Int32 = Int32(0)
        var preset_number: Int32 = Int32(0)
        var charge_weight: Float = Float32(0.0)
        var powder_index: Int32 = Int32(0)
        var bullet_weight: Int32 = Int32(0)
        var preset_name: String = String("--")
        var bullet_name: String = String("--")
        var brass_name: String = String("--")
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
        for listener in listeners {
            listener.presetChanged(to: currentPreset)
        }
    }
    
    // Add a listener to the list of listeners
    func addListener(_ listener: PresetChangeListener) {
        listeners.append(listener)
        //print("---->  there are now \(listeners.count) preset listeners")
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
        //print("addListItem()")
        preset_name_list.append(name)
        count = preset_name_list.count
        if count == MAX_PRESETS {
            loaded = true
            isLoading = false
        }
    }

    func updateListItem(_ name: String, index: Int) {
        //print("updateListItem() with name: \(name), index: \(index)")
        if isLoading { return }
        if index >= 0 && index < MAX_PRESETS {
            preset_name_list[index] = name
        } else {
            print("ERROR: updateListItemAt(): preset list index out of range.")
        }
    }
    
    func getListItemAt(_ index: Int) -> String {
        if index < 0 || index >= MAX_PRESETS {
            print("ERROR: getListItemAt(): preset list index out of range.")
            return "";  // better return val?  nil?
        }
        return preset_name_list[index]
    }

    func BLEWritePresetData() {
        print("BLEWritePresetData()")
        // Serialize preset data into bytes to send over BLE.
        let preset_version_data = Data(bytes: &_currentPresetData.preset_version, count: MemoryLayout<Int32>.stride)
        let preset_number_data = Data(bytes: &_currentPresetData.preset_number, count: MemoryLayout<Int32>.stride)
        let charge_weight_data = Data(bytes: &_currentPresetData.charge_weight, count: MemoryLayout<Float32>.stride)
        let powder_index_data = Data(bytes: &_currentPresetData.powder_index, count: MemoryLayout<Int32>.stride)
        let bullet_weight_data = Data(bytes: &_currentPresetData.bullet_weight, count: MemoryLayout<Int32>.stride)
        var preset_name_data = _currentPresetData.preset_name.data(using: String.Encoding.utf8)
        preset_name_data!.append(0)
        var bullet_name_data = _currentPresetData.bullet_name.data(using: String.Encoding.utf8)
        bullet_name_data!.append(0)
        var brass_name_data = _currentPresetData.brass_name.data(using: String.Encoding.utf8)
        brass_name_data!.append(0)

        var _data: Data = preset_version_data
        _data.append(preset_number_data)
        _data.append(charge_weight_data)
        _data.append(powder_index_data)
        _data.append(bullet_weight_data)
        _data.append(contentsOf: preset_name_data!)
        _data.append(contentsOf: bullet_name_data!)
        _data.append(contentsOf: brass_name_data!)
        
        print("bytes to send: \(_data.count)")
        print("_data: \(String(describing: Array(_data)))")
        
        BlePeripheral().writePresetData(outgoingData: _data)
    }
}

// MARK: - Powder Manager
protocol PowderChangeListener: AnyObject {
    func powderChanged(to new_powder: PowderManager.PowderData)
}

let g_powder_manager = PowderManager()

class PowderManager {
    struct PowderData {
        var powder_version: Int32 = Int32(0)
        var powder_number: Int32 = Int32(0)
        var powder_factor: Float32 = Float32(0.0)
        var powder_name: String = String("--")
        var powder_lot: String = String("--")
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
        print("PowderManager invoke()")
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
        //print("addListItem()")
        powder_name_list.append(name)
        count = powder_name_list.count
        if count == MAX_POWDERS {
            loaded = true
            isLoading = false
        }
    }

    func updateListItem(_ name: String, index: Int) {
        print("updateListItem() with name: \(name), index: \(index)")
        if isLoading { return }
        if index >= 0 && index < MAX_POWDERS {
            powder_name_list[index] = name
        } else {
            print("ERROR: updateListItem(): powder list index out of range.")
        }
    }
    
    func getListItemAt(_ index: Int) -> String {
        if index < 0 || index >= MAX_POWDERS {
            print("ERROR: getListItemAt(): powder list index out of range.")
            return "";  // better return val?  nil?
        }
        return powder_name_list[index]
    }
    
    func BLEWritePowderData() {
        print("BLEWritePowderData()")
        // Serialize powder data into bytes to send over BLE.
        let powder_version_data = Data(bytes: &_currentPowder.powder_version, count: MemoryLayout<Int32>.stride)
        let powder_number_data = Data(bytes: &_currentPowder.powder_number, count: MemoryLayout<Int32>.stride)
        let powder_factor_data = Data(bytes: &_currentPowder.powder_factor, count: MemoryLayout<Float32>.stride)
        var powder_name_data = _currentPowder.powder_name.data(using: String.Encoding.utf8)
        powder_name_data!.append(0)
        var powder_lot_data = _currentPowder.powder_lot.data(using: String.Encoding.utf8)
        powder_lot_data!.append(0)

        var _data: Data = powder_version_data
        _data.append(powder_number_data)
        _data.append(powder_factor_data)
        _data.append(contentsOf: powder_name_data!)
        _data.append(contentsOf: powder_lot_data!)
        
        print("bytes to send: \(_data.count)")
        print("_data: \(String(describing: Array(_data)))")
        
        BlePeripheral().writePowderData(outgoingData: _data)
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
        case Manual
        case Manual_Run
        case Ladder
        case Ladder_Run
        case Throwing
        case Trickling
        case Bumping
        case Paused
        case Locked
        case Menu
        case Settings
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

// MARK: - ConfigData Manager

protocol ConfigDataChangeListener: AnyObject {
    func configDataChanged(to new_data: ConfigDataManager.ConfigData)
}

let g_config_data_manager = ConfigDataManager()

class ConfigDataManager {
    
    //Data from storage
    struct ConfigData {
        var preset: Int32 = Int32(0)
        var fscaleP: Float32 = Float32(0.0)
        var decel_threshold: Float32 = Float32(0.0)
        var bump_threshold: Float32 = Float32(0.0)
        var decel_limit: Int32 = Int32(0)
        var gn_tolerance: Float32 = Float32(0.0)
        var trickler_speed: Int32 = Int32(0)
        var config_version: Int32 = Int32(0)
    }

    // Data for the current preset
    private var _current: ConfigData
    private var listeners: [ConfigDataChangeListener]

    init() {
        _current = ConfigData()
        listeners = []
    }

    // Invoke the "changed" method on all listeners
    func invoke() {
        for listener in listeners {
            listener.configDataChanged(to: _current)
        }
    }
    
    // Add a listener to the list of listeners
    func addListener(_ listener: ConfigDataChangeListener) {
        listeners.append(listener)
    }
    
    // Remove a specific listener from the list of listeners
    func removeListener(_ listener: ConfigDataChangeListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }

    // Access to current powder data
    var currentConfigData: ConfigData {
        get {
            return _current
        }
        set {
            _current = newValue
            invoke()
        }
    }

    func BLEWriteConfigData() {
        print("BLEWriteConfigData()")
        // Serialize config data into bytes to send over BLE.
        let preset_number_data = Data(bytes: &_current.preset, count: MemoryLayout<Int32>.stride)
        let fscalep_data = Data(bytes: &_current.fscaleP, count: MemoryLayout<Float32>.stride)
        let decel_thresh_data = Data(bytes: &_current.decel_threshold, count: MemoryLayout<Int32>.stride)
        let bump_thresh_data = Data(bytes: &_current.bump_threshold, count: MemoryLayout<Float32>.stride)
        let decel_limit_data = Data(bytes: &_current.decel_limit, count: MemoryLayout<Int32>.stride)
        let gn_tolerance_data = Data(bytes: &_current.gn_tolerance, count: MemoryLayout<Float32>.stride)
        let trickler_speed_data = Data(bytes: &_current.trickler_speed, count: MemoryLayout<Int32>.stride)
        let config_version_data = Data(bytes: &_current.config_version, count: MemoryLayout<Int32>.stride)

        var _data: Data = preset_number_data
        _data.append(fscalep_data)
        _data.append(decel_thresh_data)
        _data.append(bump_thresh_data)
        _data.append(decel_limit_data)
        _data.append(gn_tolerance_data)
        _data.append(trickler_speed_data)
        _data.append(config_version_data)

        print("bytes to send: \(_data.count)")
        print("_data: \(String(describing: Array(_data)))")
        
        BlePeripheral().writeConfigData(outgoingData: _data)
    }

}

// MARK: - Trickler Cal Data Manager

protocol TricklerCalDataChangeListener: AnyObject {
    func tricklerCalDataChanged(to new_data: TricklerCalDataManager.TricklerCalData)
}

let g_trickler_cal_data_manager = TricklerCalDataManager()

class TricklerCalDataManager {
    
    //Data from storage
    struct TricklerCalData {
        var count: Int32 = Int32(0)
        var average: Float32 = Float32(0.0)
        var speed: Int32 = Int32(0)
    }

    // Data for the current preset
    private var _current: TricklerCalData
    private var listeners: [TricklerCalDataChangeListener]

    init() {
        _current = TricklerCalData()
        listeners = []
    }

    // Invoke the "changed" method on all listeners
    func invoke() {
        for listener in listeners {
            listener.tricklerCalDataChanged(to: _current)
        }
    }
    
    // Add a listener to the list of listeners
    func addListener(_ listener: TricklerCalDataChangeListener) {
        listeners.append(listener)
    }
    
    // Remove a specific listener from the list of listeners
    func removeListener(_ listener: TricklerCalDataChangeListener) {
        if let index = listeners.firstIndex(where: { $0 === listener }) {
            listeners.remove(at: index)
        }
    }

    // Access to current powder data
    var currentData: TricklerCalData {
        get {
            return _current
        }
        set {
            _current = newValue
            invoke()
        }
    }
}

