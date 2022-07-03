//
//  SettingsViewController.swift
//  PowderThrow
//
//  Created by David Veach on 6/18/22.
//

import UIKit
import CoreBluetooth

class  SettingsViewController: UIViewController {
    
    @IBOutlet weak var configVersionLabel: UILabel!

    @IBOutlet weak var bumpThreshTextField: UITextField!
    @IBOutlet weak var toleranceTextField: UITextField!
    @IBOutlet weak var fscalepTextField: UITextField!
    @IBOutlet weak var decelLimitTextField: UITextField!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let nav = self.navigationController {
            let isPopping = !nav.viewControllers.contains(self)
            if isPopping {
                // popping off nav
                BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SET_SYSTEM_STATE, parameter: Int8(RunDataManager.system_state.Menu.rawValue))
                print("TODO: remove self from listeners when implemented for settings")
            } 
        } else {
            // not on nav at all
            print("ERROR: View \(String(describing: self)) is not on nav controller at all!")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"

        //TODO: handle mode change to grams!

        configVersionLabel.text = "Config Version: \(g_configData.config_version)"
        bumpThreshTextField.text = String(format: "%4.2f", g_configData.bump_threshold)
        toleranceTextField.text = String(format: "%.2f", g_configData.gn_tolerance)
        fscalepTextField.text = String(format: "%.1f", g_configData.fscaleP)
        decelLimitTextField.text = String(format: "%d", g_configData.decel_limit)
                
        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SET_SYSTEM_STATE, parameter: Int8(RunDataManager.system_state.Settings.rawValue))
    }
}
