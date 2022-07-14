//
//  RunThrowerViewController.swift
//  PowderThrow
//
//  Created by David Veach on 7/1/22.
//

import UIKit
import CoreBluetooth

class RunThrowerViewController: UIViewController, RunDataChangeListener {

    @IBOutlet weak var scaleWeightLabel: UILabel!
    @IBOutlet weak var scaleCondLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var decelThreshSliderLabel: UILabel!
    @IBOutlet weak var decelThreshSlider: UISlider!
    @IBOutlet weak var presetNameLabel: UILabel!
    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var targetWeightLabel: UILabel!
    @IBOutlet weak var enableSwitch: UISwitch!

    @IBOutlet weak var estopButton: UIButton!
    
    // MARK: - Navigation
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let nav = self.navigationController {
            let isPopping = !nav.viewControllers.contains(self)
            if isPopping {
                // popping off nav
                BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_SET_STATE, parameter: Int8(RunDataManager.system_state.Menu.rawValue))
                g_rundata_manager.removeListener(self)
            }
        } else {
            // not on nav at all
            print("ERROR: View \(String(describing: self)) is not on nav controller at all!")
        }
    }

    // MARK: - View Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Powder Throw"

        // Setup objects
        scaleWeightLabel.layer.borderWidth = 8.0
        scaleWeightLabel.layer.borderColor = UIColor.systemGray.cgColor
        scaleWeightLabel.layer.cornerRadius = 10
        estopButton.layer.cornerRadius = 8
        estopButton.isHidden = true
        estopButton.isEnabled = false
        

        presetNameLabel.text = g_preset_manager.currentPreset.preset_name
        powderNameLabel.text = g_powder_manager.currentPowder.powder_name
        if g_rundata_manager.currentRunData.scale_in_grains {
            let val = (g_rundata_manager.currentRunData.target_weight * 100).rounded() / 100
            targetWeightLabel.text = "\(val) gn"
        } else {
            let val = (g_rundata_manager.currentRunData.target_weight * GM_TO_GN_FACTOR * 1000).rounded() / 1000
            targetWeightLabel.text = "\(val) g"
        }

        g_rundata_manager.addListener(self)

        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_SET_STATE, parameter: Int8(RunDataManager.system_state.Ready.rawValue))
    }
    
    // MARK: - Change Listener Callbacks
    
    // Update the slider label if value changed (by tenths)
    @IBAction func decelThreshSliderValueChanged(_ sender: Any) {
        let val = (decelThreshSlider.value * 10).rounded() / 10
        if (decelThreshSliderLabel.text != "\(val)") {
            decelThreshSliderLabel.text = "\(val)"
        }
    }
        
   func runDataChanged(to new_data: RunDataManager.RunData) {
        if new_data.scale_in_grains {
            let val = (new_data.scale_value * 100).rounded() / 100
            scaleWeightLabel.text = "\(String(format: "%-07.2f", val)) gn"
        } else {
            let val = (new_data.scale_value * 1000).rounded() / 1000
            scaleWeightLabel.text = "\(String(format: "%-07.3f", val)) g"
        }
        switch new_data.scale_cond {
        case RunDataManager.scale_cond.Pan_Off.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.systemBlue.cgColor
        case RunDataManager.scale_cond.On_Target.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.systemGreen.cgColor
        case RunDataManager.scale_cond.Over_Target.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.systemRed.cgColor
        case RunDataManager.scale_cond.Not_Ready.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.systemGray.cgColor
        case RunDataManager.scale_cond.Zero.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.systemGray.cgColor
        default:
            scaleWeightLabel.layer.borderColor = UIColor.systemOrange.cgColor
        }
        let cond = RunDataManager.scale_cond(rawValue: new_data.scale_cond)
        scaleCondLabel.text = cond?.description

        let state = RunDataManager.system_state(rawValue: new_data.system_state)
        stateLabel.text = state?.description
        
        switch new_data.system_state {
        case RunDataManager.system_state.Bumping.rawValue,
             RunDataManager.system_state.Throwing.rawValue,
             RunDataManager.system_state.Paused.rawValue,
             RunDataManager.system_state.Trickling.rawValue:
            estopButton.isHidden = false
            enableSwitch.isEnabled = false
        case RunDataManager.system_state.Ready.rawValue:
            estopButton.isHidden = true
            enableSwitch.isEnabled = true
            enableSwitch.setOn(true, animated: true)
        case RunDataManager.system_state.Disabled.rawValue:
            estopButton.isHidden = true
            enableSwitch.isEnabled = true
            enableSwitch.setOn(false, animated: true)
        default:
            estopButton.isHidden = true
            enableSwitch.isEnabled = false
        }
        
        //TODO: preset info doesn't really need to be updated every time
        //TODO: target weight will change for ladder mode
        presetNameLabel.text = g_preset_manager.currentPreset.preset_name
        powderNameLabel.text = g_powder_manager.currentPowder.powder_name
    
        if new_data.scale_in_grains {
            let val = (new_data.target_weight * 100).rounded() / 100
            targetWeightLabel.text = "\(String(format: "%-05.2f", val)) gn"
        } else {
            let val = (new_data.target_weight * GM_TO_GN_FACTOR * 1000).rounded() / 1000
            targetWeightLabel.text = "\(String(format: "%-05.3f", val)) g"
        }
        
        decelThreshSlider.value = new_data.decel_thresh
        let val = (new_data.decel_thresh * 10).rounded() / 10
        decelThreshSliderLabel.text = String(val)
    }

    // MARK: - Button Handlers
    
    @IBAction func enableSwitchChnaged(_ sender: UISwitch) {
        let ENABLED = Int8(0)
        let DISABLED = Int8(1)
        if sender.isOn {
            print("TODO: Enable switch on")
            BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_ENABLE, parameter: ENABLED)
        } else {
            print("TODO: Enable switch off")
            BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_ENABLE, parameter: DISABLED)
        }
    }
    
    // Update BLE when finger lifted anywhere (don't send every value change)
    @IBAction func decelThreshSliderTouchUpOutside(_ sender: Any) {
        decelThreshSliderEndEdit()
    }
    @IBAction func decelThreshSliderTouchUpInside(_ sender: Any) {
        decelThreshSliderEndEdit()
    }
    func decelThreshSliderEndEdit() {
        var val = (decelThreshSlider.value * 10).rounded() / 10
        if g_rundata_manager.currentRunData.decel_thresh != val {
            let float_data = Data(bytes: &val, count: MemoryLayout<Float32>.stride)
            BlePeripheral.connectedPeripheral?.writeValue(float_data, for: BlePeripheral.connectedDecelThreshChar!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    @IBAction func estopButtonAction(_ sender: Any) {
        print("---> Writing Emergency Stop")
        
        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_ESTOP, parameter: Int8(RunDataManager.system_state.Ready.rawValue))

    }

}
