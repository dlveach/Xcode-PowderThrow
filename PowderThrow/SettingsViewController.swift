//
//  SettingsViewController.swift
//  PowderThrow
//
//  Created by David Veach on 6/18/22.
//

import UIKit
import CoreBluetooth

class  SettingsViewController: UIViewController, UITextFieldDelegate, ConfigDataChangeListener {
    
    private var _isEditing = false

    @IBOutlet weak var configVersionLabel: UILabel!
    @IBOutlet weak var decelThresholdLabel: UILabel!
    @IBOutlet weak var bumpThresholdLabel: UILabel!
    @IBOutlet weak var toleranceLabel: UILabel!
    @IBOutlet weak var FScalePLabel: UILabel!
    @IBOutlet weak var decelLimitLabel: UILabel!
    @IBOutlet weak var tricklerSpeedLabel: UILabel!
    
    @IBOutlet weak var decelThreshold: UITextField!
    @IBOutlet weak var bumpThreshold: UITextField!
    @IBOutlet weak var tolerance: UITextField!
    @IBOutlet weak var FScaleP: UITextField!
    @IBOutlet weak var decelLimit: UITextField!
    @IBOutlet weak var tricklerSpeed: UITextField!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var editSaveButton: UIButton!
    
    // MARK: - Custom View navigation
    
    // Custom back button action
    @objc func back(sender: UIBarButtonItem) {
        if _isEditing {
            let backAlert = UIAlertController(title: "Go Back", message: "Unsaved changes will be lost.", preferredStyle: UIAlertController.Style.alert)
            backAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in _ = self.navigationController?.popViewController(animated: true) }))
            backAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in }))
            present(backAlert, animated: true, completion: nil)
            return
        }
        _ = self.navigationController?.popViewController(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let nav = self.navigationController {
            let isPopping = !nav.viewControllers.contains(self)
            if isPopping {
                // popping off nav
                BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_SET_STATE, parameter: Int8(RunDataManager.system_state.Menu.rawValue))
                print("TODO: remove self from listeners when implemented for settings")
            } 
        } else {
            // not on nav at all
            print("ERROR: View \(String(describing: self)) is not on nav controller at all!")
        }
    }

    // MARK: - View Load/Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        
        // Custom back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< Main", style: UIBarButtonItem.Style.plain, target: self, action: #selector(PresetsViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

        // Enable dismissing the keyboard popup by tapping outside
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)

        // Add self as listener to manager(s)
        g_config_data_manager.addListener(self)
        
        // Set text field delagets
        decelThreshold.delegate = self
        bumpThreshold.delegate = self
        tolerance.delegate = self
        FScaleP.delegate = self
        decelLimit.delegate = self
        tricklerSpeed.delegate = self

        // Set up default view conditions
        editSaveButton.layer.cornerRadius = 8
        cancelButton.layer.cornerRadius = 8
        cancelButton.isHidden = true
        editSaveButton.setTitle("Edit", for: UIControl.State.normal)
        clearEditing(reset: true)

        // Set state on peripheral
        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_SET_STATE, parameter: Int8(RunDataManager.system_state.Settings.rawValue))
    }
    
    // MARK: - Data Listener callbacks
    
    func configDataChanged(to new_data: ConfigDataManager.ConfigData) {
        configVersionLabel.text = "Config Version: \(new_data.config_version)"
        decelThreshold.text = String(format: "%4.2f", new_data.decel_threshold)
        bumpThreshold.text = String(format: "%4.2f", new_data.bump_threshold)
        tolerance.text = String(format: "%.2f", new_data.gn_tolerance)
        FScaleP.text = String(format: "%.1f", new_data.fscaleP)
        decelLimit.text = String(format: "%d", new_data.decel_limit)
        tricklerSpeed.text = String(format: "%d", new_data.trickler_speed)
    }
    
    // MARK: - Button Handlers
    
    @IBAction func editSaveButtonAction(_ sender: Any) {
        if _isEditing {
            if anyError() { return }
            saveConfigData()
            clearEditing(reset: false)
        } else {
            if anyError() { editSaveButton.isHidden = true }
            setEditing()
        }
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        if _isEditing { clearEditing(reset: true) }
    }
    
    func setEditing() {
        _isEditing = true
        editSaveButton.setTitle("Save", for: UIControl.State.normal)
        cancelButton.isHidden = false
        decelThreshold.backgroundColor = UIColor.white
        decelThreshold.textColor = UIColor.black
        decelThreshold.isEnabled = true
        bumpThreshold.backgroundColor = UIColor.white
        bumpThreshold.textColor = UIColor.black
        bumpThreshold.isEnabled = true
        tolerance.backgroundColor = UIColor.white
        tolerance.textColor = UIColor.black
        tolerance.isEnabled = true
        FScaleP.backgroundColor = UIColor.white
        FScaleP.textColor = UIColor.black
        FScaleP.isEnabled = true
        decelLimit.backgroundColor = UIColor.white
        decelLimit.textColor = UIColor.black
        decelLimit.isEnabled = true
        tricklerSpeed.backgroundColor = UIColor.white
        tricklerSpeed.textColor = UIColor.black
        tricklerSpeed.isEnabled = true
    }
    
    func clearEditing(reset: Bool) {
        _isEditing = false
        editSaveButton.setTitle("Edit", for: UIControl.State.normal)
        cancelButton.isHidden = true
        decelThreshold.backgroundColor = UIColor.black
        decelThreshold.textColor = UIColor.white
        decelThreshold.isEnabled = false
        decelThresholdLabel.layer.borderWidth = 0
        bumpThreshold.backgroundColor = UIColor.black
        bumpThreshold.textColor = UIColor.white
        bumpThreshold.isEnabled = false
        bumpThresholdLabel.layer.borderWidth = 0
        tolerance.backgroundColor = UIColor.black
        tolerance.textColor = UIColor.white
        tolerance.isEnabled = false
        toleranceLabel.layer.borderWidth = 0
        FScaleP.backgroundColor = UIColor.black
        FScaleP.textColor = UIColor.white
        FScaleP.isEnabled = false
        FScalePLabel.layer.borderWidth = 0
        decelLimit.backgroundColor = UIColor.black
        decelLimit.textColor = UIColor.white
        decelLimit.isEnabled = false
        decelLimitLabel.layer.borderWidth = 0
        tricklerSpeed.backgroundColor = UIColor.black
        tricklerSpeed.textColor = UIColor.white
        tricklerSpeed.isEnabled = false
        tricklerSpeedLabel.layer.borderWidth = 0
        if reset {
            configVersionLabel.text = "Config Version: \(g_config_data_manager.currentConfigData.config_version)"
            decelThreshold.text = String(format: "%4.2f", g_config_data_manager.currentConfigData.decel_threshold)
            bumpThreshold.text = String(format: "%4.2f", g_config_data_manager.currentConfigData.bump_threshold)
            tolerance.text = String(format: "%.2f", g_config_data_manager.currentConfigData.gn_tolerance)
            FScaleP.text = String(format: "%.1f", g_config_data_manager.currentConfigData.fscaleP)
            decelLimit.text = String(format: "%d", g_config_data_manager.currentConfigData.decel_limit)
            tricklerSpeed.text = String(format: "%d", g_config_data_manager.currentConfigData.trickler_speed)
        }
    }
    
    // MARK: Save config data
    
    func saveConfigData() {
        print("savePresetData()")
        if anyError() { return }
        
        var new_config = ConfigDataManager.ConfigData()
        new_config.config_version = g_config_data_manager.currentConfigData.config_version
        new_config.preset = g_config_data_manager.currentConfigData.preset

        if let val = Float32(decelThreshold.text!) {
            new_config.decel_threshold = val
        } else {
            print("ERROR: decelThreshold.text is not a floating point number.")
            return
        }
        if let val = Float32(bumpThreshold.text!) {
            new_config.bump_threshold = val
        } else {
            print("ERROR: bumpThreshold.text is not a floating point number.")
            return
        }
        if let val = Float32(tolerance.text!) {
            new_config.gn_tolerance = val
        } else {
            print("ERROR: tolerance.text is not a floating point number.")
            return
        }
        if let val = Float32(FScaleP.text!) {
            new_config.fscaleP = val
        } else {
            print("ERROR: FScaleP.text is not a floating point number.")
            return
        }
        if let val = Int32(decelLimit.text!) {
            new_config.decel_limit = val
        } else {
            print("ERROR: decelLimit.text is not an integer number.")
            return
        }
        if let val = Int32(tricklerSpeed.text!) {
            new_config.trickler_speed = val
        } else {
            print("ERROR: tricklerSpeed.text is not an integer number.")
            return
        }

        g_config_data_manager.currentConfigData = new_config
        g_config_data_manager.BLEWriteConfigData()
    }
    
    // MARK: - Form Validation

    // TODO: remove these inline validations if not used
    @IBAction func decelThresholdChanged(_ sender: Any) {
    }
    @IBAction func bumpThresholdChanged(_ sender: Any) {
    }
    @IBAction func toleranceChanged(_ sender: Any) {
    }
    @IBAction func FScalePChanged(_ sender: Any) {
    }
    @IBAction func decelLimitChanged(_ sender: Any) {
    }
    @IBAction func tricklerSpeedChanged(_ sender: Any) {
    }
    
    // Text field End Edit validation actions
    @IBAction func decelThresholdEndEdit(_ sender: Any) {
    }
    @IBAction func bumpThresholdEndEdit(_ sender: Any) {
        print("bumpThreshold end edit validation")
        if let char_count = bumpThreshold.text?.count {
            if char_count != 4 {
                setTextFieldError(bumpThresholdLabel)
            } else {
                let str = bumpThreshold.text
                let set = CharacterSet(charactersIn: str!)
                let testSet = CharacterSet.decimalDigits.union(CharacterSet(Array(["."])))
                let regexp = try! NSRegularExpression(pattern: "0\\.[0-9]{2}", options: [])
                let sourceRange = NSRange(str!.startIndex..<str!.endIndex, in: str!)
                let result = regexp.matches(in: str!,options: [],range: sourceRange)
                if result.count > 0 && testSet.isSuperset(of: set) {
                    clearTextFieldError(bumpThresholdLabel)
                } else {
                    setTextFieldError(bumpThresholdLabel)
                }
            }
        } else {
            setTextFieldError(bumpThresholdLabel)
        }
        _ = anyError()
    }
    @IBAction func toleranceEndEdit(_ sender: Any) {
        print("toleranceEndEdit end edit validation")
    }
    @IBAction func FScalePEndEdit(_ sender: Any) {
        print("FScalePEndEdit end edit validation")
    }
    @IBAction func decelLimitEndEdit(_ sender: Any) {
        print("decelLimitEndEdit end edit validation")
    }
    @IBAction func tricklerSpeedEndEdit(_ sender: Any) {
        print("tricklerSpeedEndEdit end edit validation")
    }
    
    func anyError() -> Bool {

        //bullet name, wt and brass name optional:
        if bumpThresholdLabel.layer.borderWidth > 0 || toleranceLabel.layer.borderWidth > 0 || FScalePLabel.layer.borderWidth > 0 || decelLimitLabel.layer.borderWidth > 0 || tricklerSpeedLabel.layer.borderWidth > 0 ||  bumpThresholdLabel.text?.count == 0 || toleranceLabel.text?.count == 0 || FScalePLabel.text?.count == 0 || decelLimitLabel.text?.count == 0 || tricklerSpeedLabel.text?.count == 0
        {
            editSaveButton.isHidden = true
            return (true)
        } else {
            editSaveButton.isHidden = false
            return (false)
        }
    }

    func setTextFieldError(_ label: UILabel) {
        label.layer.borderWidth = 5
        label.layer.borderColor = UIColor.red.cgColor
    }
    
    func clearTextFieldError(_ label: UILabel) {
        label.layer.borderWidth = 0
        label.layer.borderColor = UIColor.black.cgColor
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
}
