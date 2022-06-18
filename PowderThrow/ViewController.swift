//
//   ViewController.swift
//  BLEButton
//
//  Created by David Veach on 3/10/22.
//
//  TODO:
//      - add a model for storing config data (and other persisetnt stuffs)
//      - need a charactaristic for scale mode.  Store in model.

import UIKit
import CoreBluetooth

// MARK: -  ViewController
class  ViewController: UIViewController {

    //TODO: move to model? (make available to other view controllers)
    /*
    static let COMMAND_SETTINGS = Int8(0x01)
    static let COMMAND_CURRENT_PRESET = Int8(0x10)
    static let COMMAND_PRESET_BY_INDEX = Int8(0x20)
    static let COMMAND_CURENT_POWDER = Int8(0x30)
    static let COMMAND_POWDER_BY_INDEX = Int8(0x40)
*/
    //TODO: Move this to data model, also presets and powders
    private struct _configData {
        var preset = Int16(0)
        var fscaleP = Float32(0.0)
        var decel_threshold = Float32(0.0)
        var bump_threshold = Float32(0.0)
        var decel_limit = Int16(0)
        var gn_tolerance = Float32(0.0)
        var mg_tolerance = Float32(0.0)
        var config_version = Int16(0)
    }
        
    private var centralManager: CBCentralManager!
    private var myPeripheral: CBPeripheral!
    private var btnCharacteristic: CBCharacteristic!
    private var weightChar: CBCharacteristic!
    private var scaleTargetCharacteristic: CBCharacteristic!
    private var condCharacteristic: CBCharacteristic!
    private var stateChar: CBCharacteristic!
    private var decelThreshChar: CBCharacteristic!
    private var configDataChar: CBCharacteristic!
    private var presetDataChar: CBCharacteristic!
    private var powderDataChar: CBCharacteristic!
    private var presetListItemChar: CBCharacteristic!
    private var parameterCommandChar: CBCharacteristic!

    @IBOutlet weak var peripheralName: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var buffLabel: UILabel!
    @IBOutlet weak var condLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var decelThreshSliderLabel: UILabel!
    @IBOutlet weak var decelThreshSlider: UISlider!
    @IBOutlet weak var presetNameLabel: UILabel!
    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var targetWeightLabel: UILabel!
    @IBOutlet weak var settingsButtonOutlet: UIButton!
    @IBOutlet weak var presetButtonOutlet: UIButton!
    @IBOutlet weak var bumpThreshold: UILabel!
    @IBOutlet weak var Tollerance: UILabel!
    @IBOutlet weak var FScaleP: UILabel!
    @IBOutlet weak var DecelLimit: UILabel!
    
    // MARK: - Button handlers
    
    @IBAction func settingsButtonAction(_ sender: Any) {
        print("Settings button pressed.")
        print("TODO: navigate to settings screen")
        print("Just test commands for now")
        writeData(incomingValue: BLE_COMMANDS.SETTINGS)
    }
    
    @IBAction func presetButtonAction(_ sender: Any) {
        print("Settings button pressed.")
        print("TODO: navigate to presets screen")
        print("Just test commands for now")
        //writeData(incomingValue:  ViewController.COMMAND_CURRENT_PRESET)
        writeParameterCommand(cmd: BLE_COMMANDS.PRESET_BY_INDEX, parameter: 2)
    }
    
    @IBAction func decelThreshSliderValueChanged(_ sender: Any) {
        let val = (decelThreshSlider.value * 10).rounded() / 10
        //only do updates if rounded slider val is diff from label
        if (decelThreshSliderLabel.text == "\(val)") { return }
        decelThreshSliderLabel.text = "\(val)"
        //update the charactaristic
        let _data = ("\(val)" as NSString).data(using: String.Encoding.utf8.rawValue)
        myPeripheral?.writeValue(_data!, for: BlePeripheral.connectedDecelThreshChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func writeParameterCommand(cmd: Int8, parameter: Int8) {
        let _data: [Int8] = [cmd, parameter]
        print("_data is \(String(describing: _data))")
        print("Size of _data is \(_data.count)")
        let outgoingData = NSData(bytes: _data, length: _data.count)
        myPeripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedParameterCommandChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func writeData(incomingValue: Int8) {
        var val = incomingValue
        let outgoingData = NSData(bytes: &val, length: MemoryLayout<Int8>.size)
        myPeripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedBtnChar!, type: CBCharacteristicWriteType.withResponse)
     }
    
    //MARK: ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        //TODO: rename this (scale weight label)
        buffLabel.layer.borderWidth = 4.0
        buffLabel.layer.borderColor = UIColor.gray.cgColor
        buffLabel.layer.cornerRadius = 8
        settingsButtonOutlet.layer.cornerRadius = 8
        settingsButtonOutlet.isEnabled = false;
        presetButtonOutlet.layer.cornerRadius = 8
        presetButtonOutlet.isEnabled = false;
    }

    func startScanning() -> Void {
        // Start Scanning
        print("Start scanning ...")
        centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
        statusLabel.text = "Scanning..."
    }

    func stopScanning() -> Void {
        print("Stop Scanning.")
        centralManager?.stopScan()
        statusLabel.text = "Scanning stopped."
    }

}

// MARK: - CBCentralManagerDelegate
// A protocol that provides updates for the discovery and management of peripheral devices.
extension  ViewController: CBCentralManagerDelegate {

    // MARK: - Check
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
      switch central.state {
        case .poweredOff:
            print("Is Powered Off.")
            let alertVC = UIAlertController(title: "Bluetooth Required", message: "Check your Bluetooth Settings", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
                self.dismiss(animated: true, completion: nil)
            })
            alertVC.addAction(action)
            self.present(alertVC, animated: true, completion: nil)
        case .poweredOn:
            print("Is Powered On.")
            startScanning()
        case .unsupported:
            print("Is Unsupported.")
        case .unauthorized:
            print("Is Unauthorized.")
        case .unknown:
            print("Unknown")
        case .resetting:
            print("Resetting")
        @unknown default:
            print("Error")
        }
    }

    // MARK: - Discover
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Function: \(#function),Line: \(#line)")
        centralManager.stopScan()
        myPeripheral = peripheral
        myPeripheral.delegate = self
        statusLabel.text = "Peripheral found."
        peripheralName.text = "Device: \(peripheral.name ?? "Unnamed")"
        print("Peripheral Discovered: \(peripheral)")
        print("Connecting ...")
        statusLabel.text = "Connecting ..."
        centralManager.connect(peripheral, options: nil)
    }

    // MARK: - Connect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        print("Connected.")
        statusLabel.text = "Connected."
        print("Discovering services ...")
        myPeripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }
    
    // MARK: - Disconnect
    func centralManager(_ central: CBCentralManager, didDisconnect peripheral: CBPeripheral) {
        peripheralName.text = "Device: None."
        statusLabel.text = "Disconnected."
        buffLabel.text = ""
        condLabel.text = ""
    }
}

// MARK: - SERVICE DISCOVERY
extension  ViewController: CBPeripheralDelegate {
    // MARK: - Discover Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        BlePeripheral.connectedService = services[0]
    }
    // MARK: - Discover Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        print("Found \(characteristics.count) characteristics.")
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Btn_UUID)  {
                btnCharacteristic = characteristic
                BlePeripheral.connectedBtnChar = btnCharacteristic
                print("Command Button Characteristic: \(btnCharacteristic.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Parameter_Command_UUID) {
                parameterCommandChar = characteristic
                BlePeripheral.connectedParameterCommandChar = parameterCommandChar
                print("Parameter Command Characteristic: \(parameterCommandChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Weight_UUID) {
                weightChar = characteristic
                BlePeripheral.connectedWeightChar = weightChar
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("Scale Weight Characteristic: \(weightChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Target_UUID) {
                scaleTargetCharacteristic = characteristic
                BlePeripheral.connectedTargetChar = scaleTargetCharacteristic
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("Scale Target Characteristic: \(scaleTargetCharacteristic.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Cond_UUID) {
                condCharacteristic = characteristic
                BlePeripheral.connectedCondChar = condCharacteristic
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("Scale Cond Characteristic: \(condCharacteristic.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_State_UUID) {
                stateChar = characteristic
                BlePeripheral.connectedStateChar = stateChar
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("System State Characteristic: \(stateChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Decel_Thresh_UUID) {
                decelThreshChar = characteristic
                BlePeripheral.connectedDecelThreshChar = decelThreshChar
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("Decel Thresh Characteristic: \(decelThreshChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Config_Data_UUID) {
                configDataChar = characteristic
                BlePeripheral.connectedConfigDataChar = configDataChar
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("Configuration Data Characteristic: \(configDataChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Preset_Data_UUID) {
                presetDataChar = characteristic
                BlePeripheral.connectedPresetDataChar = presetDataChar
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("Preset Data Characteristic: \(presetDataChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Powder_Data_UUID) {
                powderDataChar = characteristic
                BlePeripheral.connectedPowderDataChar = powderDataChar
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("Powder Data Characteristic: \(powderDataChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Preset_List_Item_UUID) {
                presetListItemChar = characteristic
                BlePeripheral.connectedPresetListItemChar = presetListItemChar
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                print("Preset List Item Characteristic: \(presetListItemChar.uuid)")
            }
        }
    }

    // MARK: - Charactaristic  handlers
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let dd = characteristic.value {
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Weight_UUID) {
                let str = String(data: dd, encoding: String.Encoding.ascii)!
                let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
                buffLabel.text = (trimmed)
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Cond_UUID) {
                condLabel.text = (String(data: dd, encoding: String.Encoding.ascii)!)
                if condLabel.text == "Pan Off" {
                    buffLabel.layer.borderColor = UIColor.blue.cgColor
                } else if condLabel.text == "On Target" {
                    buffLabel.layer.borderColor = UIColor.green.cgColor
                } else if condLabel.text == "Over Target" {
                    buffLabel.layer.borderColor = UIColor.red.cgColor
                } else if condLabel.text == "Not Ready" || condLabel.text == "Undefined" {
                    buffLabel.layer.borderColor = UIColor.gray.cgColor
                } else if condLabel.text == "Zero" {
                    buffLabel.layer.borderColor = UIColor.white.cgColor
                } else {
                    buffLabel.layer.borderColor = UIColor.orange.cgColor
                }
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_State_UUID) {
                stateLabel.text = (String(data: dd, encoding: String.Encoding.ascii)!)
                if stateLabel.text == "Ready" || stateLabel.text == "Locked" {
                    settingsButtonOutlet.isEnabled = true;
                    settingsButtonOutlet.layer.backgroundColor = UIColor.systemBlue.cgColor
                    presetButtonOutlet.isEnabled = true;
                    presetButtonOutlet.layer.backgroundColor = UIColor.systemBlue.cgColor
                } else {
                    settingsButtonOutlet.isEnabled = false;
                    settingsButtonOutlet.layer.backgroundColor = UIColor.gray.cgColor
                    presetButtonOutlet.isEnabled = false;
                    presetButtonOutlet.layer.backgroundColor = UIColor.gray.cgColor
                }
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Decel_Thresh_UUID) {
                let str = (String(data: dd, encoding: String.Encoding.ascii)!)
                decelThreshSliderLabel.text = str
                if let val = Float(str) {
                    decelThreshSlider.value = val
                } else {
                    print("ERROR: Char Decel_Thresh does not contain Float")
                }
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Config_Data_UUID) {
                print("Unpacking Config Data Charactaristic")
                let config_data = configDataToStruct(data: dd)
                print("Config Version: \(config_data.config_version)")
                print("Bump Threshold: \(config_data.bump_threshold)")
                //TODO: handle mode change to grams!
                bumpThreshold.text = String(format: "Bump: %4.2f gn", config_data.bump_threshold)
                print("Decel Limit: \(config_data.decel_limit)")
                DecelLimit.text = "Dec Lim: \(config_data.decel_limit)"
                print("Decel Threshold: \(config_data.decel_threshold)")
                print("FScaleP: \(config_data.fscaleP)")
                FScaleP.text = String(format: "FScaleP: %.1f", config_data.fscaleP)
                print("Grain Tolerance: \(config_data.gn_tolerance)")
                //TODO: handle mode change to grams!
                Tollerance.text = String(format: "Tol: %.2f gn", config_data.gn_tolerance)
                print("Gram Tolerance: \(config_data.mg_tolerance)")
                print("Preset Index: \(config_data.preset)")
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Preset_Data_UUID) {
                print("Processing read value in Preset Data Charactaristic")
                print("Size of data: \(dd.count)")
                print("data as array values: \(String(describing: Array(dd)))")
                let preset_target_weight = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Float32.self) }
                print("Preset Chg weight: \(preset_target_weight)")
                //targetWeightLabel.text = (String(preset_target_weight))
                let powder_index = Array(dd[4...7]).withUnsafeBytes { $0.load(as: Int32.self) }
                print("Powder Index: \(powder_index)")
                let preset_name = String(cString: Array(dd[8...24]))
                print("Preset Name: '\(preset_name)'")
                presetNameLabel.text = preset_name.trimmingCharacters(in: .whitespacesAndNewlines)
                print("TODO: parse more preset data")
                
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Preset_List_Item_UUID) {
                // test preset list array
                //PresetList.append(PresetListItem(index: 0, name: preset_name))

            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Powder_Data_UUID) {
                print("Processing read value in Powder Data Charactaristic")
                print("Size of data: \(dd.count)")
                print("data as array values: \(String(describing: Array(dd)))")
                let powder_name = String(cString: Array(dd[0...17]))
                print("Powder Name: '\(powder_name)'")
                powderNameLabel.text = powder_name.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Target_UUID) {
                targetWeightLabel.text = (String(data: dd, encoding: String.Encoding.ascii))
            }
        } else {
            print("ERROR: could not unwrap charactaristic data on update.")
            return
        }
    }
    
    private func configDataToStruct(data: Data) -> _configData {
        let _data = data
        let converted:_configData = _data.withUnsafeBytes { $0.load(as: _configData.self) }
        return converted
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
          peripheral.readRSSI()
        //TODO anything?
    }
    
    // MARK: - DidWriteValueFor characteristic
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Function: \(#function),Line: \(#line)")
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        print("Function: \(#function),Line: \(#line)")
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
        } else {
            print("Characteristic's value subscribed")
        }
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
}


