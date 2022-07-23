//
//  PresetsViewController.swift
//  PowderThrow
//
//  Created by David Veach on 6/18/22.
//
//  TODO:
//  - Change Powder Name field to picker, load from PTData powders

import UIKit
import CoreBluetooth

class  PresetsViewController: UIViewController, UITextFieldDelegate, PresetChangeListener, PowderChangeListener, ScreenChangeListener {
    
    private var _isEditing = false
    
    @IBOutlet weak var powdersButton: UIButton!
    @IBOutlet weak var presetsPickerView: UIPickerView!
    @IBOutlet weak var editSaveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var presetNameTextField: UITextField!
    @IBOutlet weak var chargeWtTextField: UITextField!
    @IBOutlet weak var PowderNameTextField: UITextField!
    @IBOutlet weak var bulletNameTextField: UITextField!
    @IBOutlet weak var bulletWtTextField: UITextField!
    @IBOutlet weak var brassNameTextField: UITextField!
    
    @IBOutlet weak var presetNameLabel: UILabel!
    @IBOutlet weak var chargeWtLabel: UILabel!
    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var bulletNameLabel: UILabel!
    @IBOutlet weak var bulletWtLabel: UILabel!
    @IBOutlet weak var brassNameLabel: UILabel!
    
    // MARK: - Custom View Navigation

    var ble_nav = false

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
                if !ble_nav {
                    // it's local nav, send state change
                    BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_SET_STATE, parameter: Int8(RunDataManager.system_state.Menu.rawValue))
                    ble_nav = false;  //TODO: set false should not be needed if object is destroyed
                }
                g_preset_manager.removeListener(self)
                g_screen_manager.removeListener(self)
            } 
        } else {
            print("ERROR: View \(String(describing: self)) is not on nav controller at all!")
        }
    }
    
    // MARK: - View Load / Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Presets"

        //custom back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< Main", style: UIBarButtonItem.Style.plain, target: self, action: #selector(PresetsViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

        // Enable dismissing the keyboard popup by tapping outside
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)

        // Add self to managers as listener
        g_preset_manager.addListener(self)
        g_powder_manager.addListener(self)
        g_screen_manager.addListener(self)

        // Set delgates
        presetNameTextField.delegate = self
        chargeWtTextField.delegate = self
        bulletNameTextField.delegate = self
        bulletWtTextField.delegate = self
        brassNameTextField.delegate = self
        presetsPickerView.dataSource = self
        presetsPickerView.delegate = self

        //set up default view conditions
        editSaveButton.layer.cornerRadius = 8
        cancelButton.layer.cornerRadius = 8
        powdersButton.layer.cornerRadius = 8
        presetsPickerView.layer.backgroundColor = UIColor.systemBlue.cgColor
        presetsPickerView.layer.cornerRadius = 10
        clearEditing(reset: true)
        
        //Set picker to current preset.
        presetsPickerView.selectRow(Int(g_preset_manager.currentPreset.preset_number-1), inComponent: 0, animated: false)
    }
        
    // MARK: - Data Listener Callbacks
    
    func screenChanged(to new_screen: ScreenChangeManager.Screen) {
        if new_screen == ScreenChangeManager.Screen.ViewController {
            ble_nav = true //flag to avoid writing BLE state changes
            _ = self.navigationController?.popViewController(animated: true)
        } else {
            print("Presets VC: ignoring screen change to view controller: \(new_screen.description)")
        }
    }
    
    func presetChanged(to new_preset: PresetManager.PresetData) {
        presetNameTextField.text = new_preset.preset_name.trimmingCharacters(in: .whitespacesAndNewlines)
        let val = (new_preset.charge_weight * 100).rounded() / 100  //two decimal places
        chargeWtTextField.text = String(val)
        if new_preset.powder_index < 0 {
            PowderNameTextField.text = "--"
        }
        bulletNameTextField.text = new_preset.bullet_name.trimmingCharacters(in: .whitespacesAndNewlines)
        bulletWtTextField.text = String(new_preset.bullet_weight)
        brassNameTextField.text = new_preset.brass_name.trimmingCharacters(in: .whitespacesAndNewlines)
        presetsPickerView.selectRow(Int(new_preset.preset_number-1), inComponent: 0, animated: false)
    }
        
    func powderChanged(to new_powder: PowderManager.PowderData) {
        PowderNameTextField.text = new_powder.powder_name
    }
    
    // MARK: - Button Handlers
    
    @IBAction func powdersButtonAction(_ sender: Any) {
        let screen = ScreenChangeManager.Screen.PowdersViewController
        if let nextView = self.storyboard?.instantiateViewController(identifier: screen.description) {
            self.navigationController?.pushViewController(nextView, animated: true)
        } else {
            print("ERROR: unknown screen view controller: \(screen.description)")
        }
        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_SET_STATE, parameter: Int8(RunDataManager.system_state.Powders.rawValue))
    }
    
    @IBAction func editSaveButtonAction(_ sender: Any) {
        if _isEditing {
            if anyError() { return }
            savePresetData()
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
        presetNameTextField.backgroundColor = UIColor.white
        presetNameTextField.textColor = UIColor.black
        chargeWtTextField.backgroundColor = UIColor.white
        chargeWtTextField.textColor = UIColor.black
        bulletNameTextField.backgroundColor = UIColor.white
        bulletNameTextField.textColor = UIColor.black
        bulletWtTextField.backgroundColor = UIColor.white
        bulletWtTextField.textColor = UIColor.black
        brassNameTextField.backgroundColor = UIColor.white
        brassNameTextField.textColor = UIColor.black
        presetNameTextField.isEnabled = true
        chargeWtTextField.isEnabled = true
        bulletNameTextField.isEnabled = true
        bulletWtTextField.isEnabled = true
        brassNameTextField.isEnabled = true
        powdersButton.isHidden = false
        presetsPickerView.isUserInteractionEnabled = false
        presetsPickerView.layer.backgroundColor = UIColor.gray.cgColor
    }
    
    func clearEditing(reset: Bool) {
        _isEditing = false
        editSaveButton.setTitle("Edit", for: UIControl.State.normal)
        cancelButton.isHidden = true
        presetNameTextField.backgroundColor = UIColor.black
        presetNameTextField.textColor = UIColor.white
        chargeWtTextField.backgroundColor = UIColor.black
        chargeWtTextField.textColor = UIColor.white
        bulletNameTextField.backgroundColor = UIColor.black
        bulletNameTextField.textColor = UIColor.white
        bulletWtTextField.backgroundColor = UIColor.black
        bulletWtTextField.textColor = UIColor.white
        brassNameTextField.backgroundColor = UIColor.black
        brassNameTextField.textColor = UIColor.white
        presetNameTextField.isEnabled = false
        chargeWtTextField.isEnabled = false
        bulletNameTextField.isEnabled = false
        bulletWtTextField.isEnabled = false
        brassNameTextField.isEnabled = false
        presetNameLabel.layer.borderWidth = 0
        chargeWtLabel.layer.borderWidth = 0
        powderNameLabel.layer.borderWidth = 0
        bulletNameLabel.layer.borderWidth = 0
        bulletWtLabel.layer.borderWidth = 0
        brassNameLabel.layer.borderWidth = 0
        powdersButton.isHidden = true
        presetsPickerView.isUserInteractionEnabled = true
        presetsPickerView.layer.backgroundColor = UIColor.systemBlue.cgColor
        if reset {
            presetNameTextField.text = g_preset_manager.currentPreset.preset_name.trimmingCharacters(in: .whitespacesAndNewlines)
            let val = (g_preset_manager.currentPreset.charge_weight * 100).rounded() / 100
            chargeWtTextField.text = String(val)
            if g_preset_manager.currentPreset.powder_index >= 0 {
                PowderNameTextField.text = g_powder_manager.getListItemAt(Int(g_preset_manager.currentPreset.powder_index))
            } else {
                PowderNameTextField.text = "--"
            }
            bulletNameTextField.text = g_preset_manager.currentPreset.bullet_name.trimmingCharacters(in: .whitespacesAndNewlines)
            bulletWtTextField.text = String(g_preset_manager.currentPreset.bullet_weight)
            brassNameTextField.text = g_preset_manager.currentPreset.brass_name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    // MARK: - Save Preset Data
    
    // Update current preset with view field data.  Write current preset to BLE to save on peripheral.
    // TODO: figure out better way than padding blanks.  Pad with null chars?  Would be better maybe.
    func savePresetData() {
        print("savePresetData()")
        if anyError() { return }
        // make a temp copy of the data to avoid triggering "invoke" on every change
        var new_preset = PresetManager.PresetData()
        new_preset.preset_version = g_preset_manager.currentPreset.preset_version
        new_preset.preset_number = g_preset_manager.currentPreset.preset_number
        new_preset.powder_index = Int32(g_powder_manager.currentPowder.powder_number - 1)
        if let str = presetNameTextField.text {
            let fmtstr = str.withCString { String(format: "%-16s", $0) }
            new_preset.preset_name = fmtstr
            //update picker view with new preset name
            g_preset_manager.updateListItem(str, index: Int(g_preset_manager.currentPreset.preset_number)-1)
            presetsPickerView.reloadAllComponents()
        } else {
            print("Failed to get presetNameTextField.text")
            return
        }
        if let str = bulletNameTextField.text {
            let fmtstr = str.withCString { String(format: "%-16s", $0) }
            new_preset.bullet_name = fmtstr
        } else {
            print("Failed to get bulletNameTextField.text")
            return
        }
        if let str = brassNameTextField.text {
            let fmtstr = str.withCString { String(format: "%-16s", $0) }
            new_preset.brass_name = fmtstr
        } else {
            print("Failed to get brassNameTextField.text")
            return
        }
        if let val = Float32(chargeWtTextField.text!) {
            new_preset.charge_weight = val
        } else {
            print("ERROR: charge weight field is not a floating point number!")
            return
        }
        if let val = Int32(bulletWtTextField.text!) {
            new_preset.bullet_weight = val
        } else {
            print("ERROR: bullet weight field is not an integer number!")
            return
        }
        // Now update the current preset (triggers invoke on listeners)
        g_preset_manager.currentPreset = new_preset
        g_preset_manager.BLEWritePresetData()
    }

    // MARK: - Form Validation
    
    @IBAction func presetNameFieldEndEdit(_ sender: Any) {
        var err = true
        if presetNameTextField.text!.count > 0 || presetNameTextField.text!.count <= MAX_NAME_LEN {
            let str = presetNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let set = CharacterSet(charactersIn: str)
            var testSet = CharacterSet.letters
            testSet = testSet.union(CharacterSet.decimalDigits)
            testSet = testSet.union(CharacterSet([" ",".","-"]))
            if testSet.isSuperset(of: set) { err = false }
        }
        if err { setTextFieldError(presetNameLabel)
        } else { clearTextFieldError(presetNameLabel) }
        _ = anyError()
    }

    @IBAction func chargeWtFieldEndEdit(_ sender: Any) {
        var err = true
        if chargeWtTextField.text!.count > 0 || chargeWtTextField.text!.count <= MAX_NAME_LEN {
            let str = chargeWtTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let set = CharacterSet(charactersIn: str)
            let testSet = CharacterSet.decimalDigits.union(CharacterSet(Array(["."])))
            let regexp = try! NSRegularExpression(pattern: "[0-9]{1,3}\\.[0-9]{1,2}", options: [])
            let sourceRange = NSRange(str.startIndex..<str.endIndex, in: str)
            let result = regexp.matches(in: str,options: [],range: sourceRange)
            if result.count > 0 && testSet.isSuperset(of: set) { err = false }
        }
        if err { setTextFieldError(chargeWtLabel)
        } else { clearTextFieldError(chargeWtLabel) }
        _ = anyError()
    }

    @IBAction func bulletNameFieldEndEdit(_ sender: Any) {
        var err = true
        if bulletNameTextField.text!.count > 0 || bulletNameTextField.text!.count <= MAX_NAME_LEN {
            let str = bulletNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let set = CharacterSet(charactersIn: str)
            var testSet = CharacterSet.letters
            testSet = testSet.union(CharacterSet.decimalDigits)
            testSet = testSet.union(CharacterSet([" ",".","-"]))
            if testSet.isSuperset(of: set) { err = false }
        }
        if err { setTextFieldError((bulletNameLabel))
        } else { clearTextFieldError((bulletNameLabel)) }
        _ = anyError()
    }

    @IBAction func bulletWtFieldEndEdit(_ sender: Any) {
        var err = true
        if bulletWtTextField.text!.count > 0 || bulletWtTextField.text!.count <= 2 {
            if let val = Int(bulletWtTextField.text ?? "0") {
                if val > 1 && val < 1000 { err = false }
            }
        }
        if err { setTextFieldError(bulletWtLabel)
        } else { clearTextFieldError(bulletWtLabel) }
        _ = anyError()
    }

    @IBAction func brassNameFieldEndEdit(_ sender: Any) {
        var err = true
        if brassNameTextField.text!.count > 0 || brassNameTextField.text!.count <= MAX_NAME_LEN {
            let str = brassNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let set = CharacterSet(charactersIn: str)
            var testSet = CharacterSet.letters
            testSet = testSet.union(CharacterSet.decimalDigits)
            testSet = testSet.union(CharacterSet([" ",".","-"]))
            if testSet.isSuperset(of: set) { err = false }
        }
        if err { setTextFieldError((brassNameLabel))
        } else { clearTextFieldError((brassNameLabel)) }
        _ = anyError()
    }

    func anyError() -> Bool {
        //bullet name, wt and brass name required:
        //if presetNameLabel.layer.borderWidth > 0 || chargeWtLabel.layer.borderWidth > 0 || powderNameLabel.layer.borderWidth > 0 || bulletNameLabel.layer.borderWidth > 0 || bulletWtLabel.layer.borderWidth > 0 || brassNameLabel.layer.borderWidth > 0 || presetNameTextField.text?.count == 0 || chargeWtTextField.text?.count == 0 || PowderNameTextField.text?.count == 0 || bulletNameTextField.text?.count == 0 || bulletWtTextField.text?.count == 0 || brassNameTextField.text?.count == 0

        //bullet name, wt and brass name optional:
        if presetNameLabel.layer.borderWidth > 0 || chargeWtLabel.layer.borderWidth > 0 || powderNameLabel.layer.borderWidth > 0 || bulletNameLabel.layer.borderWidth > 0 || bulletWtLabel.layer.borderWidth > 0 || brassNameLabel.layer.borderWidth > 0 || presetNameTextField.text?.count == 0 || chargeWtTextField.text?.count == 0 || PowderNameTextField.text?.count == 0
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

// MARK: - Extensions

extension PresetsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return g_preset_manager.count
    }
}

extension PresetsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.white
        pickerLabel.text = "\(row+1) - \(g_preset_manager.getListItemAt(row))"
        pickerLabel.font = UIFont.boldSystemFont(ofSize: 30)
        pickerLabel.textAlignment = NSTextAlignment.center
        return pickerLabel
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row + 1 != g_preset_manager.currentPreset.preset_number {
            BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.PRESET_DATA_BY_INDEX, parameter: Int8(row+1))
        }
    }
}

