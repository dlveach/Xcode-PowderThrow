//
//  RunThrowerViewController.swift
//  PowderThrow
//
//  Created by David Veach on 7/1/22.
//

import UIKit
import CoreBluetooth

class RunThrowerViewController: UIViewController, RunDataChangeListener {

    var _isLoading: Bool = true
    
    @IBOutlet weak var scaleWeightLabel: UILabel!
    @IBOutlet weak var scaleCondLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var decelThreshSliderLabel: UILabel!
    @IBOutlet weak var decelThreshSlider: UISlider!
    @IBOutlet weak var presetNameLabel: UILabel!
    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var targetWeightLabel: UILabel!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var ladderSetupButton: UIButton!
    
    @IBOutlet weak var estopButton: UIButton!
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
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
        _isLoading = true

        // Setup objects
        scaleWeightLabel.layer.borderWidth = 8.0
        scaleWeightLabel.layer.borderColor = UIColor.systemGray.cgColor
        scaleWeightLabel.layer.cornerRadius = 10
        estopButton.layer.cornerRadius = 8
        ladderSetupButton.layer.cornerRadius = 8
        runButton.layer.cornerRadius = 8
        
        //estopButton.isHidden = true
        //estopButton.isEnabled = false
        //ladderSetupButton.isHidden = true

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
        
        /* needed?
        estopButton.isHidden = true
        enableSwitch.isEnabled = true
        enableSwitch.setOn(true, animated: true)
        ladderSetupButton.isHidden = true
        runButton.isHidden = true
        runButton.isEnabled = false
         */
        _isLoading = false
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
             RunDataManager.system_state.Locked.rawValue,
             RunDataManager.system_state.Trickling.rawValue:
            if new_data.system_state == RunDataManager.system_state.Locked.rawValue {
                estopButton.isHidden = true
            } else {
                estopButton.isHidden = false
            }
            runButton.isHidden = true
            enableSwitch.isEnabled = false
            ladderSetupButton.isHidden = true
            previousButton.isEnabled = false
            nextButton.isEnabled = false
        case RunDataManager.system_state.Ready.rawValue:
            presetNameLabel.text = g_preset_manager.currentPreset.preset_name
            estopButton.isHidden = true
            enableSwitch.isEnabled = true
            enableSwitch.setOn(true, animated: true)
            ladderSetupButton.isHidden = true
            runButton.isHidden = true
            previousButton.isHidden = true
            nextButton.isHidden = true
        case RunDataManager.system_state.Manual.rawValue,
             RunDataManager.system_state.Ladder.rawValue:
            estopButton.isHidden = true
            enableSwitch.isEnabled = true
            enableSwitch.setOn(false, animated: true)
            ladderSetupButton.isHidden = false
            runButton.isHidden = false
            if new_data.scale_cond == RunDataManager.scale_cond.Pan_Off.rawValue ||
                new_data.scale_cond == RunDataManager.scale_cond.Not_Ready.rawValue ||
                new_data.scale_cond == RunDataManager.scale_cond.Undefined.rawValue
            {
                runButton.isEnabled = false
                runButton.layer.backgroundColor = UIColor.systemGray.cgColor
            } else {
                runButton.isEnabled = true
                runButton.layer.backgroundColor = UIColor.systemBlue.cgColor
            }
            if new_data.system_state == RunDataManager.system_state.Manual.rawValue {
                presetNameLabel.text = g_preset_manager.currentPreset.preset_name
                previousButton.isHidden = true
                nextButton.isHidden = true
            } else {
                presetNameLabel.text = "--- Ladder ---"
                previousButton.isHidden = false
                nextButton.isHidden = false
                previousButton.isEnabled = true
                nextButton.isEnabled = true
            }
        case RunDataManager.system_state.Manual_Run.rawValue,
             RunDataManager.system_state.Ladder_Run.rawValue:
            estopButton.isHidden = true
            enableSwitch.isEnabled = false
            ladderSetupButton.isHidden = true
            runButton.isEnabled = false
            runButton.layer.backgroundColor = UIColor.systemGray.cgColor
            previousButton.isEnabled = false
            nextButton.isEnabled = false
        default:
            //estopButton.isHidden = true
            //enableSwitch.isEnabled = false
            //runButton.isEnabled = false
            //_ = self.navigationController?.popViewController(animated: true)
            if _isLoading {
                print("Unandled state during loading, ignore")
            } else {
                print("Unhandled state: \(state?.description ?? "INVALID STATE VALUE")")
            }
        }
        
        //TODO: preset info doesn't really need to be updated every time
        //TODO: target weight will change for ladder mode
        //presetNameLabel.text = g_preset_manager.currentPreset.preset_name
        //powderNameLabel.text = g_powder_manager.currentPowder.powder_name
    
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
        let AUTO = Int8(0), MANUAL = Int8(1)
        if sender.isOn {
            BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_AUTO_ENABLE, parameter: AUTO)
            ladderSetupButton.isHidden = true
            runButton.isHidden = true
        } else {
            BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_AUTO_ENABLE, parameter: MANUAL)
            ladderSetupButton.isHidden = false
            runButton.isHidden = false
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
    
    @IBAction func runButtonAction(_ sender: Any) {
        print("run button pressed")
        runButton.isHidden = true
        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_MANUAL_RUN, parameter: Int8(RunDataManager.system_state.Ready.rawValue))
    }
    @IBAction func prevButtonAction(_ sender: Any) {
        print("TODO: ladder previous button.  Decrement step and write ladder BLE data")
    }
    @IBAction func nextButtonAction(_ sender: Any) {
        print("TODO: ladder next button.  Increment step and write ladder BLE data")
    }
    
}
