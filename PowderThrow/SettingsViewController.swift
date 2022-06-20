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
    
    @IBOutlet weak var settingsPicker: UIPickerView!
    
    let digits = ["0","1","2","3","4","5","6","7","8","9"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"

        //TODO: handle mode change to grams!

        configVersionLabel.text = "Config Version: \(ConfigData.config_version)"
        bumpThreshTextField.text = String(format: "%4.2f", ConfigData.bump_threshold)
        toleranceTextField.text = String(format: "%.2f", ConfigData.gn_tolerance)
        fscalepTextField.text = String(format: "%.1f", ConfigData.fscaleP)
        decelLimitTextField.text = String(format: "%d", ConfigData.decel_limit)
                
        settingsPicker.dataSource = self
        settingsPicker.delegate = self
    }
}

extension SettingsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 4
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return digits.count
    }
}

extension SettingsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return digits[row]
    }
}
