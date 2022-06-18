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

    @IBOutlet weak var scaleWeightLabel: UILabel!
    @IBOutlet weak var scaleCondLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var decelThreshSliderLabel: UILabel!
    @IBOutlet weak var decelThreshSlider: UISlider!
    @IBOutlet weak var presetNameLabel: UILabel!
    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var targetWeightLabel: UILabel!
    @IBOutlet weak var settingsButtonOutlet: UIButton!
    @IBOutlet weak var presetButtonOutlet: UIButton!
    
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
        title = "PowderThrow: Loading ..."
        
        // Display object customization
        //TODO: rename this (scale weight label)
        scaleWeightLabel.layer.borderWidth = 4.0
        scaleWeightLabel.layer.borderColor = UIColor.gray.cgColor
        scaleWeightLabel.layer.cornerRadius = 8
        settingsButtonOutlet.layer.cornerRadius = 8
        settingsButtonOutlet.isEnabled = false;
        presetButtonOutlet.layer.cornerRadius = 8
        presetButtonOutlet.isEnabled = false;
    }

    func startScanning() -> Void {
        // Start Scanning
        print("Start scanning ...")
        centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
        title = "PowderThrow: Scanning..."
    }

    func stopScanning() -> Void {
        print("Stop Scanning.")
        centralManager?.stopScan()
        title = "PowderThrow: Scanning stopped."
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
        title = "PowderThrow: Peripheral found."
        //peripheralName.text = "Device: \(peripheral.name ?? "Unnamed")"
        print("Peripheral Discovered: \(peripheral)")
        print("Connecting ...")
        title = "PowderThrow: Connecting ..."
        centralManager.connect(peripheral, options: nil)
    }

    // MARK: - Connect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        print("Connected.")
        title = "PowderThrow: Connected."
        print("Discovering services ...")
        myPeripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }
    
    // MARK: - Disconnect
    func centralManager(_ central: CBCentralManager, didDisconnect peripheral: CBPeripheral) {
        print("Disconnected from device.")
        title = "PowderThrow: Disconnected."
        scaleWeightLabel.text = ""
        scaleCondLabel.text = ""
        
        //TODO: more here.
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
                scaleWeightLabel.text = (trimmed)
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Cond_UUID) {
                scaleCondLabel.text = (String(data: dd, encoding: String.Encoding.ascii)!)
                if scaleCondLabel.text == "Pan Off" {
                    scaleWeightLabel.layer.borderColor = UIColor.blue.cgColor
                } else if scaleCondLabel.text == "On Target" {
                    scaleWeightLabel.layer.borderColor = UIColor.green.cgColor
                } else if scaleCondLabel.text == "Over Target" {
                    scaleWeightLabel.layer.borderColor = UIColor.red.cgColor
                } else if scaleCondLabel.text == "Not Ready" || scaleCondLabel.text == "Undefined" {
                    scaleWeightLabel.layer.borderColor = UIColor.gray.cgColor
                } else if scaleCondLabel.text == "Zero" {
                    scaleWeightLabel.layer.borderColor = UIColor.white.cgColor
                } else {
                    scaleWeightLabel.layer.borderColor = UIColor.orange.cgColor
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
                let _data: Data = dd
                ConfigData = _data.withUnsafeBytes { $0.load(as: _config_data.self) }
                print("Config Version: \(ConfigData.config_version)")
                print("Bump Threshold: \(ConfigData.bump_threshold)")
                print("Decel Limit: \(ConfigData.decel_limit)")
                print("Decel Threshold: \(ConfigData.decel_threshold)")
                print("FScaleP: \(ConfigData.fscaleP)")
                print("Grain Tolerance: \(ConfigData.gn_tolerance)")
                print("Gram Tolerance: \(ConfigData.mg_tolerance)")
                print("Preset Index: \(ConfigData.preset)")
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
                presetNameLabel.text = "Preset:  \(preset_name.trimmingCharacters(in: .whitespacesAndNewlines))"
                //presetNameLabel.text = preset_name.trimmingCharacters(in: .whitespacesAndNewlines)
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
                //powderNameLabel.text = powder_name.trimmingCharacters(in: .whitespacesAndNewlines)
                powderNameLabel.text = "Powder:  \(powder_name.trimmingCharacters(in: .whitespacesAndNewlines))"
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Target_UUID) {
                if let target_name = (String(data: dd, encoding: String.Encoding.ascii)) {
                    targetWeightLabel.text = "Charge:  \(target_name.trimmingCharacters(in: .whitespacesAndNewlines))"
                } else {
                    print("Failed to decode charactaristic data: \(CBUUIDs.BLE_Characteristic_Target_UUID)")
                }
            }
        } else {
            print("ERROR: could not unwrap charactaristic data on update.")
            return
        }
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


