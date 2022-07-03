//
//  PowdersViewController.swift
//  PowderThrow
//
//  Created by David Veach on 6/18/22.
//

import UIKit
import CoreBluetooth

// MARK: - PowdersViewController

class  PowdersViewController: UIViewController, UITextFieldDelegate, PowderChangeListener {

    private var _isEditing = false

    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var powderFactorLabel: UILabel!
    @IBOutlet weak var lotNumberLabel: UILabel!
    @IBOutlet weak var powderNameField: UITextField!
    @IBOutlet weak var powderFactorField: UITextField!
    @IBOutlet weak var lotNumberField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var editSaveButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var powderPickerView: UIPickerView!
    
    
    // Custom back button action
    @objc func back(sender: UIBarButtonItem) {
        if _isEditing || selectButton.isHidden == false {
            let backAlert = UIAlertController(title: "Go Back", message: "Unsaved changes will be lost.", preferredStyle: UIAlertController.Style.alert)
            backAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                // user pressed Ok.  Pop view.
                _ = self.navigationController?.popViewController(animated: true)

            }))
            backAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                // Stay on current view.
            }))
            present(backAlert, animated: true, completion: nil)
            return
        }
        // No unsaved changes, ok to pop view.
        _ = self.navigationController?.popViewController(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let nav = self.navigationController {
            let isPopping = !nav.viewControllers.contains(self)
            if isPopping {
                // popping off nav
                BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SET_SYSTEM_STATE, parameter: Int8(RunDataManager.system_state.Presets.rawValue))
                g_powder_manager.removeListener(self)
            } 
        } else {
            // not on nav at all
            print("ERROR: View \(String(describing: self)) is not on nav controller at all!")
        }
    }

    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Powders"
        
        //custom back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< Presets", style: UIBarButtonItem.Style.plain, target: self, action: #selector(PresetsViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

        powderNameField.delegate = self
        powderFactorField.delegate = self
        lotNumberField.delegate = self
        // add self as listener for powder update events
        g_powder_manager.addListener(self)
        
        // Enable dismissing the keyboard popup by tapping outside
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)

        // style buttons
        editSaveButton.layer.cornerRadius = 8
        cancelButton.layer.cornerRadius = 8
        selectButton.layer.cornerRadius = 8

        //set up preset picker
        powderPickerView.layer.backgroundColor = UIColor.systemBlue.cgColor
        powderPickerView.layer.cornerRadius = 10
        powderPickerView.dataSource = self
        powderPickerView.delegate = self
        powderPickerView.selectRow(Int(g_powder_manager.currentPowder.powder_number-1), inComponent: 0, animated: false)
        powderNameField.text = g_powder_manager.currentPowder.powder_name
        let val = (g_powder_manager.currentPowder.powder_factor * 100000).rounded() / 100000  //5 decimal places
        powderFactorField.text = String(val)
        lotNumberField.text = "TODO"
        
        BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SET_SYSTEM_STATE, parameter: Int8(RunDataManager.system_state.Powders.rawValue))
    }
    
    // MARK: - Preset Change callback

    func powderChanged(to new_powder: PowderManager.PowderData) {
        //update UI fields
        powderNameField.text = new_powder.powder_name.trimmingCharacters(in: .whitespacesAndNewlines)
        let val = (new_powder.powder_factor * 100000).rounded() / 100000  //5 decimal places
        powderFactorField.text = String(val)
        lotNumberField.text = "TODO"
        powderPickerView.selectRow(Int(new_powder.powder_number-1), inComponent: 0, animated: false)
        selectButton.isHidden = false
    }
    
    // MARK: - Button Handlers

    @IBAction func editSaveButtonAction(_ sender: Any) {
        if _isEditing {
            if anyError() {
                return
            }
            editSaveButton.setTitle("Edit", for: UIControl.State.normal)
            cancelButton.isHidden = true
            print("TODO: save data in text fields")
            //set fields inactive for editing
            selectButton.isHidden = false
            powderNameField.backgroundColor = UIColor.black
            powderNameField.textColor = UIColor.white
            powderFactorField.backgroundColor = UIColor.black
            powderFactorField.textColor = UIColor.white
            //TODO: lotNumberField.backgroundColor = UIColor.black
            //TODO: lotNumberField.textColor = UIColor.white
            disableTextFields()
            _isEditing = false
            powderPickerView.isUserInteractionEnabled = true
            powderPickerView.layer.backgroundColor = UIColor.systemBlue.cgColor
            selectButton.isHidden = true // saved data is already selected
        } else {
            _isEditing = true
            powderNameField.backgroundColor = UIColor.white
            powderNameField.textColor = UIColor.black
            powderFactorField.backgroundColor = UIColor.white
            powderFactorField.textColor = UIColor.black
            //TODO: lotNumberField.backgroundColor = UIColor.white
            //TODO: lotNumberField.textColor = UIColor.black
            editSaveButton.setTitle("Save", for: UIControl.State.normal)
            if anyError() {
                editSaveButton.isHidden = true
            }
            cancelButton.isHidden = false
            enableTextFields()
            powderPickerView.isUserInteractionEnabled = false
            powderPickerView.layer.backgroundColor = UIColor.gray.cgColor
            selectButton.isHidden = true
        }
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        if _isEditing {
            _isEditing = false
            editSaveButton.setTitle("Edit", for: UIControl.State.normal)
            editSaveButton.isHidden = false
            cancelButton.isHidden = true
            powderNameField.text = g_preset_manager.currentPreset.preset_name
            let val = (g_powder_manager.currentPowder.powder_factor * 100000).rounded() / 100000  //5 decimal places
            powderFactorField.text = String(val)
            lotNumberField.text = "TODO"
            powderNameField.backgroundColor = UIColor.black
            powderNameField.textColor = UIColor.white
            powderFactorField.backgroundColor = UIColor.black
            powderFactorField.textColor = UIColor.white
            //TODO: lotNumberField.backgroundColor = UIColor.black
            //TODO: lotNumberField.textColor = UIColor.white
            disableTextFields()
            powderPickerView.isUserInteractionEnabled = true
            powderPickerView.layer.backgroundColor = UIColor.systemBlue.cgColor
            //check if picker row != current powder, show button if it's not
            if powderPickerView.selectedRow(inComponent: 0) + 1 != g_powder_manager.currentPowder.powder_number {
                selectButton.isHidden = false
            }
        }
    }
    
    @IBAction func selectButtonAction(_ sender: Any) {
        print("TODO: select powder button action")
        //TODO: update current preset pop viewcontroller
        selectButton.isHidden = true
        let index = Int32(powderPickerView.selectedRow(inComponent: 0))
        //BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SET_CURRENT_POWDER, parameter: Int8(row))
        g_preset_manager.setPresetPowder(index)
    }
    
    // MARK: - Form Validation
    
    @IBAction func powderNameChanged(_ sender: Any) {
        if let char_count = powderNameField.text?.count {
            if char_count == 0 || char_count > MAX_NAME_LEN {
                setTextFieldError(powderNameLabel)
            } else {
                let str = powderNameField.text?.uppercased()
                powderNameField.text = str
                let set = CharacterSet(charactersIn: str!)
                var testSet = CharacterSet.uppercaseLetters
                testSet = testSet.union(CharacterSet.decimalDigits)
                testSet = testSet.union(CharacterSet([" ",".","-"]))
                if !testSet.isSuperset(of: set) {
                    setTextFieldError(powderNameLabel)
                } else {
                    clearTextFieldError(powderNameLabel)
                }
            }
        } else {
            setTextFieldError(powderNameLabel)
        }
        _ = anyError()
    }

    @IBAction func powderFactorChanged(_ sender: Any) {
        if let char_count = powderFactorField.text?.count {
            if char_count == 0 || char_count > 7 {
                setTextFieldError(powderFactorLabel)
            } else {
                let str = powderFactorField.text
                let set = CharacterSet(charactersIn: str!)
                let testSet = CharacterSet.decimalDigits.union(CharacterSet(Array(["."])))
                let regexp = try! NSRegularExpression(pattern: "[0]\\.[0-9]{2,5}", options: [])
                let sourceRange = NSRange(str!.startIndex..<str!.endIndex, in: str!)
                let result = regexp.matches(in: str!,options: [],range: sourceRange)
                if result.count > 0 && testSet.isSuperset(of: set) {
                    clearTextFieldError(powderFactorLabel)
                } else {
                    setTextFieldError(powderFactorLabel)
                }
            }
        } else {
            setTextFieldError(powderFactorLabel)
        }
        _ = anyError()
    }

    @IBAction func lotNumberChanged(_ sender: Any) {
        //TODO: impliment when powder lot number implimented
    }

    // MARK: - Support Functions
    
    func anyError() -> Bool {
        //lot number field ignored, not yet implemented in device.  TODO: add checks when implimented
        if powderNameLabel.layer.borderWidth > 0 ||
            powderFactorLabel.layer.borderWidth > 0 ||
            powderNameField.text?.count == 0 ||
            powderFactorField.text?.count == 0
        {
            editSaveButton.isHidden = true
            return (true)
        } else {
            editSaveButton.isHidden = false
            return (false)
        }
    }

    func enableTextFields() {
        powderNameField.isEnabled = true
        powderFactorField.isEnabled = true
        //TODO: lotNumberField.isEnabled = true
    }
    
    func disableTextFields() {
        powderNameField.isEnabled = false
        powderFactorField.isEnabled = false
        //TODO: lotNumberField.isEnabled = true
        powderNameLabel.layer.borderWidth = 0
        powderFactorLabel.layer.borderWidth = 0
        lotNumberLabel.layer.borderWidth = 0
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

extension PowdersViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return g_powder_manager.count
    }
}

extension PowdersViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.white
        pickerLabel.text = "\(row+1) - \(g_powder_manager.getListItemAt(row))"
        pickerLabel.font = UIFont.boldSystemFont(ofSize: 30)
        pickerLabel.textAlignment = NSTextAlignment.center
        return pickerLabel
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("Powder Picker, selecting row: \(row), Powder: \(g_powder_manager.getListItemAt(row))")
        if row + 1 != g_powder_manager.currentPowder.powder_number {
            BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.POWDER_DATA_BY_INDEX, parameter: Int8(row+1))
        }
    }
}

