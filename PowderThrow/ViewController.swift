//
//   ViewController.swift
//  PowderThrow
//
//  Created by David Veach on 3/10/22.
//
//  TODO:
//      - timeout on connect

import UIKit
import CoreBluetooth

// MARK: -  Class: ViewController
//class  ViewController: UIViewController, RunDataChangeListener, PresetChangeListener, PowderChangeListener
class  ViewController: UIViewController, PresetChangeListener, PowderChangeListener {

    private var centralManager: CBCentralManager!
    private var myPeripheral: CBPeripheral!
    private var parameterCommandChar: CBCharacteristic!
    private var weightChar: CBCharacteristic!
    private var scaleTargetCharacteristic: CBCharacteristic!
    private var condCharacteristic: CBCharacteristic!
    private var stateChar: CBCharacteristic!
    private var decelThreshChar: CBCharacteristic!
    private var configDataChar: CBCharacteristic!
    private var presetDataChar: CBCharacteristic!
    private var presetListItemChar: CBCharacteristic!
    private var powderDataChar: CBCharacteristic!
    private var powderListItemChar: CBCharacteristic!
    private var tricklerCalDataChar: CBCharacteristic!
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var presetsButton: UIButton!
    @IBOutlet weak var presetNameLabel: UILabel!
    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var targetWeightLabel: UILabel!

    var isLoadingData: Bool = true
    
    
    // MARK: - UI handlers
    
    // MARK: - Support Functions
        
    //MARK: ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        title = "PowderThrow: Starting ..."
        
        // Display object customization
        spinnerView.style = UIActivityIndicatorView.Style.large
        spinnerView.hidesWhenStopped = true
        connectButton.layer.cornerRadius = 8
        connectButton.isEnabled = false
        connectButton.isHidden = false
        runButton.layer.cornerRadius = 8
        settingsButton.layer.cornerRadius = 8
        presetsButton.layer.cornerRadius = 8

        runButton.isEnabled = false
        runButton.isHidden = true
        settingsButton.isEnabled = false;
        settingsButton.isHidden = true
        presetsButton.isEnabled = false;
        presetsButton.isHidden = true
        progressView.isHidden = true
        presetNameLabel.isHidden = true
        powderNameLabel.isHidden = true
        targetWeightLabel.isHidden = true
        
        //TODO: parameter command to request config (and current preset/powder?).  Is this needed?
    }
    
    // MARK: - Change Listener Callbacks

    func presetChanged(to new_preset: PresetManager.PresetData) {
        print("main screen setting preset field")
        print("new preset charge weight: \(new_preset.charge_weight)")
        print("g_powder_manager current powder.powder_factor: \(g_powder_manager.currentPowder.powder_factor)")
        //check preset data & enable run button
        if new_preset.charge_weight > 0 && g_powder_manager.currentPowder.powder_factor > 0 {
            presetNameLabel.text = new_preset.preset_name
            powderNameLabel.text = g_powder_manager.currentPowder.powder_name
            if g_rundata_manager.currentRunData.scale_in_grains {
                let val = (new_preset.charge_weight * 100).rounded() / 100
                targetWeightLabel.text = "\(val) gn"
            } else {
                let val = (new_preset.charge_weight * GM_TO_GN_FACTOR * 1000).rounded() / 1000
                targetWeightLabel.text = "\(val) g"
            }
            //target weight in run data needs update when preset changed
            //TODO: should peripheral be setting this????
            g_rundata_manager.currentRunData.target_weight = new_preset.charge_weight
            
            runButton.isEnabled = true
            runButton.layer.backgroundColor = UIColor.systemBlue.cgColor
        } else {
            presetNameLabel.text = "--"
            powderNameLabel.text = "--"
            targetWeightLabel.text = "--"
            runButton.isEnabled = false
            runButton.layer.backgroundColor = UIColor.systemGray.cgColor
        }
    }
    
    func powderChanged(to new_powder: PowderManager.PowderData) {
        print("main screen setting powder field")
        powderNameLabel.text = new_powder.powder_name
    }

    @IBAction func connectButtonAction(_ sender: Any) {
        // start connecting
        connectButton.isHidden = true
        connectButton.isEnabled = false
        spinnerView.isHidden = false
        spinnerView.startAnimating()
        startScanning()
        progressView.progress = 1.0/55.0
        progressView.isHidden = false
        isLoadingData = true
        g_preset_manager.addListener(self)
        g_powder_manager.addListener(self)
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
    
    func setNotConnectedView() {
        title = "PowderThrow: Not Connected."

        connectButton.isEnabled = true
        connectButton.layer.backgroundColor = UIColor.systemBlue.cgColor
        connectButton.isHidden = false
        runButton.isEnabled = false
        runButton.isHidden = true
        settingsButton.isEnabled = false;
        settingsButton.isHidden = true
        presetsButton.isEnabled = false;
        presetsButton.isHidden = true
        progressView.isHidden = true
        presetNameLabel.isHidden = true
        powderNameLabel.isHidden = true
        targetWeightLabel.isHidden = true
        g_rundata_manager.reset()
        g_powder_manager.reset()
        g_preset_manager.reset()
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
            setNotConnectedView()
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
        print("Peripheral Discovered: \(peripheral)")
        BlePeripheral.connectedPeripheral = myPeripheral
        print("Connecting ...")
        
        print("---> TODO: impliment timeout on connect")
        
        title = "PowderThrow: Connecting ..."
        centralManager.connect(peripheral, options: nil)
        
        progressView.progress = 2.0/55.0
    }

    // MARK: - Connect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        print("Connected.")
        title = "PowderThrow: Reading Services ...."
        print("Discovering services ...")
        myPeripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }
    
    // MARK: - Disconnect
    
    func centralManager (_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Perhipheral disconnected.")
        title = "PowderThrow: Disconnected."
        print("TODO: pop screens back to main and reset for reconnection.")
        
        if let nav = self.navigationController {
            let targetVC = nav.viewControllers.first{$0 is ViewController}
            if let targetVC = targetVC {
                nav.popToViewController(targetVC, animated: true)
                setNotConnectedView()
            } else {
                print("ERROR: Was not able to locate ViewController in navigation controller.first")
            }
        } else {
            print("ERROR: not in navigation controller?!?")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension  ViewController: CBPeripheralDelegate {
    // MARK: - Discover Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        BlePeripheral.connectedService = services[0]
        
        progressView.progress = 3.0/80
    }
    
    // MARK: - Discover Characteristics
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        print("Found \(characteristics.count) characteristics.")
        for characteristic in characteristics {
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
                print("Preset List Item Characteristic: \(presetListItemChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Powder_List_Item_UUID)  {
                powderListItemChar = characteristic
                BlePeripheral.connectedPowderListItemChar = powderListItemChar
                peripheral.setNotifyValue(true, for: characteristic)
                print("Command Button Characteristic: \(powderListItemChar.uuid)")
            }
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Trickler_Cal_Data_UUID)  {
                tricklerCalDataChar = characteristic
                BlePeripheral.connectedTricklerCalDataChar = tricklerCalDataChar
                peripheral.setNotifyValue(true, for: characteristic)
                print("Command Button Characteristic: \(tricklerCalDataChar.uuid)")
            }
        }
        print("All Characteristics registered, start loading preset data.")
        title = "PowderThrow: Loading Data ...."
        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.PRESET_NAME_BY_INDEX, parameter: Int8(1))
        
        progressView.progress = 4.0/55.0
    }

    // MARK: - Charactaristic  handlers
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let dd = characteristic.value {
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Weight_UUID) {
                let grains = Array(dd[0...0]).withUnsafeBytes { $0.load(as: Bool.self) }
                g_rundata_manager.currentRunData.scale_in_grains = grains
                let val = Array(dd[1...4]).withUnsafeBytes { $0.load(as: Float32.self) }
                g_rundata_manager.currentRunData.scale_value = val
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Cond_UUID) {
                let val = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Int32.self) }
                g_rundata_manager.currentRunData.scale_cond = val
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_State_UUID) {
                let val = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Int32.self) }
                g_rundata_manager.currentRunData.system_state = val
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Decel_Thresh_UUID) {
                let val = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Float32.self) }
                g_rundata_manager.currentRunData.decel_thresh = val
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Target_UUID) {
                let grains = Array(dd[0...0]).withUnsafeBytes { $0.load(as: Bool.self) }
                g_rundata_manager.currentRunData.scale_in_grains = grains
                let val = Array(dd[1...4]).withUnsafeBytes { $0.load(as: Float32.self) }
                g_rundata_manager.currentRunData.target_weight = val
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Trickler_Cal_Data_UUID) {
                print("Trickler Calibration Data")
                print("Size of data: \(dd.count)")
                print("data as array values: \(String(describing: Array(dd)))")
                let count = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Int32.self) }
                let avg = Array(dd[4...7]).withUnsafeBytes { $0.load(as: Float32.self) }
                let speed = Array(dd[8...11]).withUnsafeBytes { $0.load(as: Int32.self) }
                print("Sample Count: \(count)")
                print("Avgerage: \(avg)")
                print("Speed: \(speed)")
                let data = TricklerCalDataManager.TricklerCalData(
                    count: count,
                    average: avg,
                    speed: speed)
                g_trickler_cal_data_manager.currentData = data
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Config_Data_UUID) {
                print("Config Data Charactaristic")
                print("Size of data: \(dd.count)")
                print("data as array values: \(String(describing: Array(dd)))")
                let _data: Data = dd
                g_config_data_manager.currentConfigData = _data.withUnsafeBytes { $0.load(as: ConfigDataManager.ConfigData.self) }
                print("Config Version: \(g_config_data_manager.currentConfigData.config_version)")
                print("Bump Threshold: \(g_config_data_manager.currentConfigData.bump_threshold)")
                print("Decel Limit: \(g_config_data_manager.currentConfigData.decel_limit)")
                print("Decel Threshold: \(g_config_data_manager.currentConfigData.decel_threshold)")
                print("FScaleP: \(g_config_data_manager.currentConfigData.fscaleP)")
                print("Grain Tolerance: \(g_config_data_manager.currentConfigData.gn_tolerance)")
                print("Trickler Speed: \(g_config_data_manager.currentConfigData.trickler_speed)")
                print("Preset Index: \(g_config_data_manager.currentConfigData.preset)")
                                
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Preset_Data_UUID) {
                print("Preset Data Charactaristic")
                print("Size of data: \(dd.count)")
                print("data as array values: \(String(describing: Array(dd)))")
                let preset_version = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Int32.self) }
                let preset_number = Array(dd[4...7]).withUnsafeBytes { $0.load(as: Int32.self) }
                let preset_charge_weight = Array(dd[8...11]).withUnsafeBytes { $0.load(as: Float32.self) }
                let powder_index = Array(dd[12...15]).withUnsafeBytes { $0.load(as: Int32.self) }
                let bullet_weight = Array(dd[16...19]).withUnsafeBytes { $0.load(as: Int32.self) }
                let preset_name = String(cString: Array(dd[20...36]))
                let bullet_name = String(cString: Array(dd[37...53]))
                let brass_name = String(cString: Array(dd[54...70]))
                print("Preset Version: \(preset_version)")
                print("Preset Number: \(preset_number)")
                print("Preset Chg weight: \(preset_charge_weight)")
                print("Powder Index: \(powder_index)")
                print("Bullet Weight: \(bullet_weight)")
                print("Preset Name: '\(preset_name)'")
                print("Bullet Name: '\(bullet_name)'")
                print("Brass Name: '\(brass_name)'")
                let preset = PresetManager.PresetData(
                    preset_version: preset_version,
                    preset_number: preset_number,
                    charge_weight: preset_charge_weight,
                    powder_index: powder_index,
                    bullet_weight: bullet_weight,
                    preset_name: preset_name,
                    bullet_name: bullet_name,
                    brass_name: brass_name
                )
                g_preset_manager.currentPreset = preset
                
            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Preset_List_Item_UUID) {
                //print("Preset List Item Charactaristic")
                let preset_index = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Int32.self) }
                //print("preset_index: \(preset_index)")
                let preset_empty = dd[4...4].withUnsafeBytes { $0.load(as: Bool.self) }
                var preset_name: String
                if preset_empty {
                    preset_name = "EMPTY"
                } else {
                    preset_name = String(cString: Array(dd[5...23]))
                }
                if g_preset_manager.isLoading {
                    print("Add '\(preset_name)' to preset list, index: \(preset_index)")
                    g_preset_manager.addListItem(preset_name)
                    let progress: Float = (Float(preset_index) + 5.0)/55.0
                    progressView.progress = progress
                    let next_index = preset_index + 1
                    if g_preset_manager.loaded {
                        print("Loaded \(g_preset_manager.count) preset list items.")
                        print("Start loading powder data ...")
                        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.POWDER_NAME_BY_INDEX, parameter: Int8(1))
                    } else {
                        let _data: [Int8] = [BLE_COMMANDS.PRESET_NAME_BY_INDEX, Int8(next_index)]
                        let outgoingData = NSData(bytes: _data, length: _data.count)
                        BlePeripheral.connectedPeripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedParameterCommandChar!, type: CBCharacteristicWriteType.withResponse)
                    }
                } else {
                    print("Update preset at \(preset_index) with '\(preset_name)")
                    g_preset_manager.updateListItem(preset_name, index: Int(preset_index))
                }

            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Powder_Data_UUID) {
                print("Processing Powder Data charactaristic")
                print("Size of data: \(dd.count)")
                print("data as array values: \(String(describing: Array(dd)))")
                let powder_version = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Int32.self) }
                let powder_number = Array(dd[4...7]).withUnsafeBytes { $0.load(as: Int32.self) }
                let powder_factor = Array(dd[8...11]).withUnsafeBytes { $0.load(as: Float32.self) }
                let powder_name = String(cString: Array(dd[12...28]))
                let powder_lot = String(cString: Array(dd[29...45]))
                print("Powder Version: \(powder_version)")
                print("Powder Number: \(powder_number)")
                print("Powder Factor: '\(powder_factor)'")
                print("Powder Name: '\(powder_name)'")
                print("Powder Lot: \(powder_lot)")
                let powder = PowderManager.PowderData(
                    powder_version: powder_version,
                    powder_number: powder_number,
                    powder_factor: powder_factor,
                    powder_name: powder_name,
                    powder_lot: powder_lot
                )
                g_powder_manager.currentPowder = powder

            } else if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_Powder_List_Item_UUID) {
                //print("Powder List Item Charactaristic")
                //print("Size of data: \(dd.count)")
                //print("data as array values: \(String(describing: Array(dd)))")
                let powder_index = Array(dd[0...3]).withUnsafeBytes { $0.load(as: Int32.self) }
                //print("preset_index: \(preset_index)")
                let powder_empty = dd[4...4].withUnsafeBytes { $0.load(as: Bool.self) }
                var powder_name: String
                if powder_empty {
                    powder_name = "EMPTY"
                } else {
                    powder_name = String(cString: Array(dd[5...23]))
                }
                if g_powder_manager.isLoading {
                    print("Add '\(powder_name)' to powder list at index \(powder_index)")
                    g_powder_manager.addListItem(powder_name)
                    let progress: Float = Float(30 + powder_index)/55.0
                    progressView.progress = progress
                    let next_index = powder_index + 1
                    if g_powder_manager.loaded {
                        print("Loaded \(g_powder_manager.count) powder names.")
                        print("All data loaded, setup the screen.")
                        title = "PowderThrow: Ready."
                        spinnerView.stopAnimating()
                        progressView.isHidden = true
                        isLoadingData = false
                        presetNameLabel.isHidden = false
                        powderNameLabel.isHidden = false
                        targetWeightLabel.isHidden = false
                        //runButton.isEnabled = true
                        runButton.isHidden = false
                        //runButton.layer.backgroundColor = UIColor.systemBlue.cgColor
                        presetsButton.isEnabled = true
                        presetsButton.layer.backgroundColor = UIColor.systemBlue.cgColor
                        presetsButton.isHidden = false
                        settingsButton.isEnabled = true
                        settingsButton.layer.backgroundColor = UIColor.systemBlue.cgColor
                        settingsButton.isHidden = false
                        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.PRESET_DATA_BY_INDEX, parameter: Int8(g_config_data_manager.currentConfigData.preset+1))
                    } else {
                        let _data: [Int8] = [BLE_COMMANDS.POWDER_NAME_BY_INDEX, Int8(next_index)]
                        let outgoingData = NSData(bytes: _data, length: _data.count)
                        BlePeripheral.connectedPeripheral?.writeValue(outgoingData as Data, for: BlePeripheral.connectedParameterCommandChar!, type: CBCharacteristicWriteType.withResponse)
                    }
                } else {
                    print("update powder at \(powder_index) with '\(powder_name)")
                    g_powder_manager.updateListItem(powder_name, index: Int(powder_index))
                }
            } else {
                print("ERROR *************************************************")
                print("Could not unwrap charactaristic data on update.")
                print("Unknown characteristic UUID \(characteristic.uuid)")
            }
        } else {
            print("ERROR *************************************************")
            print("Could not unwrap charactaristic \(characteristic.uuid): No Data")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
          peripheral.readRSSI()
        //TODO anything?
    }
    
    // MARK: - DidWriteValueFor characteristic
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("ERROR *************************************************")
            print("Function: \(#function),Line: \(#line)")
            print("Error discovering services: \(String(describing: error?.localizedDescription))")
            return
        }
        //print("Message sent")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        //print("Function: \(#function),Line: \(#line)")
        if (error != nil) {
            print("ERROR *************************************************")
            print("Function: \(#function),Line: \(#line)")
            print("Problem changing notification state:\(String(describing: error?.localizedDescription))")
        } else {
            print("Characteristic: \(characteristic.uuid) value subscribed.")
        }
        if (characteristic.isNotifying) {
            print ("Notification has begun for Characteristic: \(characteristic.uuid).")
        }
    }
}


