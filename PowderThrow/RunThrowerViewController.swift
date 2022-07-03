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

    @IBOutlet weak var estopButton: UIButton!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let nav = self.navigationController {
            let isPopping = !nav.viewControllers.contains(self)
            if isPopping {
                // popping off nav
                BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SET_SYSTEM_STATE, parameter: Int8(RunDataManager.system_state.Menu.rawValue))
                g_rundata_manager.removeListener(self)
            }
        } else {
            // not on nav at all
            print("ERROR: View \(String(describing: self)) is not on nav controller at all!")
        }
    }

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

        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SET_SYSTEM_STATE, parameter: Int8(RunDataManager.system_state.Ready.rawValue))
    }
    
    @IBAction func decelThreshSliderValueChanged(_ sender: Any) {
        let val = (decelThreshSlider.value * 10).rounded() / 10
        //only do updates if rounded slider val is diff from label
        if (decelThreshSliderLabel.text == "\(val)") { return }
        decelThreshSliderLabel.text = "\(val)"
        //update the charactaristic
        let _data = ("\(val)" as NSString).data(using: String.Encoding.utf8.rawValue)
        BlePeripheral.connectedPeripheral?.writeValue(_data!, for: BlePeripheral.connectedDecelThreshChar!, type: CBCharacteristicWriteType.withResponse)
    }
    
    @IBAction func estopButtonAction(_ sender: Any) {
        print("TODO: Emergency Stop")
    }
    
   func runDataChanged(to new_data: RunDataManager.RunData) {
        if new_data.scale_in_grains {
            let val = (new_data.scale_value * 100).rounded() / 100
            scaleWeightLabel.text = "\(val) gn"
        } else {
            let val = (new_data.scale_value * GM_TO_GN_FACTOR * 1000).rounded() / 1000
            scaleWeightLabel.text = "\(val) g"
        }
        switch new_data.scale_cond {
        case RunDataManager.scale_cond.Pan_Off.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.blue.cgColor
        case RunDataManager.scale_cond.On_Target.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.green.cgColor
        case RunDataManager.scale_cond.Over_Target.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.red.cgColor
        case RunDataManager.scale_cond.Not_Ready.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.systemGray.cgColor
        case RunDataManager.scale_cond.Zero.rawValue:
            scaleWeightLabel.layer.borderColor = UIColor.systemGray.cgColor
        default:
            scaleWeightLabel.layer.borderColor = UIColor.orange.cgColor
        }
        let cond = RunDataManager.scale_cond(rawValue: new_data.scale_cond)
        scaleCondLabel.text = cond?.description

        let state = RunDataManager.system_state(rawValue: new_data.system_state)
        stateLabel.text = state?.description
        
        switch new_data.system_state {
        case RunDataManager.system_state.Bumping.rawValue,
             RunDataManager.system_state.Throwing.rawValue,
             RunDataManager.system_state.Trickling.rawValue:
            estopButton.isHidden = false
            estopButton.isEnabled = true
        default:
            estopButton.isHidden = true
            estopButton.isEnabled = false
        }
        
        //presetNameLabel.text = new_data.preset_name
        //powderNameLabel.text = new_data.powder_name
        presetNameLabel.text = g_preset_manager.currentPreset.preset_name
        powderNameLabel.text = g_powder_manager.currentPowder.powder_name
        if new_data.scale_in_grains {
            let val = (new_data.target_weight * 100).rounded() / 100
            targetWeightLabel.text = "\(val) gn"
        } else {
            let val = (new_data.target_weight * GM_TO_GN_FACTOR * 1000).rounded() / 1000
            targetWeightLabel.text = "\(val) g"
        }
        
        //TODO: enable estop if state == a running state
        
        decelThreshSlider.value = new_data.decel_thresh
        let val = (new_data.decel_thresh * 10).rounded() / 10
        decelThreshSliderLabel.text = String(val)
    }
    
}
