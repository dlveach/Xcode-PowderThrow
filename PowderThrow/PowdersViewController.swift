//
//  PowdersViewController.swift
//  PowderThrow
//
//  Created by David Veach on 6/18/22.
//

import UIKit
import CoreBluetooth

// MARK: - PowdersViewController

class  PowdersViewController: UIViewController, UITextFieldDelegate, PowderChangeListener, ScreenChangeListener {

    private var _isEditing = false
    var ble_nav = false

    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var powderFactorLabel: UILabel!
    @IBOutlet weak var powderLotLabel: UILabel!
    @IBOutlet weak var powderNameField: UITextField!
    @IBOutlet weak var powderFactorField: UITextField!
    @IBOutlet weak var powderLotField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var editSaveButton: UIButton!
    @IBOutlet weak var powderPickerView: UIPickerView!
    
    
    // Custom back button action
    @objc func back(sender: UIBarButtonItem) {
        if _isEditing {
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
                if !ble_nav {  // no dialog if navigating on peripheral
                    BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.SYSTEM_SET_STATE, parameter: Int8(RunDataManager.system_state.Presets.rawValue))
                }
                g_powder_manager.removeListener(self)
                g_screen_manager.removeListener(self)
            }
        } else {
            print("ERROR: View \(String(describing: self)) is not on nav controller at all!")
        }
    }

    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Powders"
        
        //custom back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< Presets", style: UIBarButtonItem.Style.plain, target: self, action: #selector(PowdersViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

        // Enable dismissing the keyboard popup by tapping outside
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)

        // Add self to managers as listener
        g_powder_manager.addListener(self)
        g_screen_manager.addListener(self)

        // Set delgates
        powderNameField.delegate = self
        powderFactorField.delegate = self
        powderLotField.delegate = self
        powderPickerView.dataSource = self
        powderPickerView.delegate = self

        //set up default view conditions
        editSaveButton.layer.cornerRadius = 8
        cancelButton.layer.cornerRadius = 8
        powderPickerView.layer.backgroundColor = UIColor.systemBlue.cgColor
        powderPickerView.layer.cornerRadius = 10
        clearEditing(reset: true)

        //Set picker to current powder.
        powderPickerView.selectRow(Int(g_powder_manager.currentPowder.powder_number-1), inComponent: 0, animated: false)
    }
    
    // MARK: - Data Listener Callbacks

    func screenChanged(to new_screen: ScreenChangeManager.Screen) {
        if new_screen == ScreenChangeManager.Screen.ViewController {
            _ = self.navigationController?.popToRootViewController(animated: true)
            ble_nav = true
        } else {
            print("Powders VC: ignoring screen change to view controller: \(new_screen.description)")
        }
    }

    func powderChanged(to new_powder: PowderManager.PowderData) {
        powderNameField.text = new_powder.powder_name.trimmingCharacters(in: .whitespacesAndNewlines)
        let val = (new_powder.powder_factor * 100000).rounded() / 100000  //5 decimal places
        powderFactorField.text = String(val)
        powderLotField.text = new_powder.powder_lot.trimmingCharacters(in: .whitespacesAndNewlines)
        powderPickerView.selectRow(Int(new_powder.powder_number-1), inComponent: 0, animated: false)
    }
    
    // MARK: - Button Handlers

    @IBAction func editSaveButtonAction(_ sender: Any) {
        if _isEditing {
            if anyError() { return }
            savePowderData()
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
        powderNameField.backgroundColor = UIColor.white
        powderNameField.textColor = UIColor.black
        powderFactorField.backgroundColor = UIColor.white
        powderFactorField.textColor = UIColor.black
        powderLotField.backgroundColor = UIColor.white
        powderLotField.textColor = UIColor.black
        editSaveButton.setTitle("Save", for: UIControl.State.normal)
        powderNameField.isEnabled = true
        powderFactorField.isEnabled = true
        powderLotField.isEnabled = true
        powderPickerView.isUserInteractionEnabled = false
        powderPickerView.layer.backgroundColor = UIColor.gray.cgColor
    }
    
    func clearEditing(reset: Bool) {
        _isEditing = false
        editSaveButton.setTitle("Edit", for: UIControl.State.normal)
        cancelButton.isHidden = true
        powderNameField.backgroundColor = UIColor.black
        powderNameField.textColor = UIColor.white
        powderFactorField.backgroundColor = UIColor.black
        powderFactorField.textColor = UIColor.white
        powderLotField.backgroundColor = UIColor.black
        powderLotField.textColor = UIColor.white
        powderNameField.isEnabled = false
        powderFactorField.isEnabled = false
        powderLotField.isEnabled = false
        powderNameLabel.layer.borderWidth = 0
        powderFactorLabel.layer.borderWidth = 0
        powderLotLabel.layer.borderWidth = 0
        _isEditing = false
        powderPickerView.isUserInteractionEnabled = true
        powderPickerView.layer.backgroundColor = UIColor.systemBlue.cgColor
        if reset {
            powderNameField.text = g_powder_manager.currentPowder.powder_name.trimmingCharacters(in: .whitespacesAndNewlines)
            let val = (g_powder_manager.currentPowder.powder_factor * 100000).rounded() / 100000  //5 decimal places
            powderFactorField.text = String(val)
            powderLotField.text = g_powder_manager.currentPowder.powder_lot.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
        
    // MARK: - Save Powder Data

    func savePowderData() {
        //print("savePowderData()")
        if anyError() { return }
        
        var new_powder = PowderManager.PowderData()
        new_powder.powder_version = g_powder_manager.currentPowder.powder_version
        new_powder.powder_number = g_powder_manager.currentPowder.powder_number
        if let str = powderNameField.text {
            let fmtstr = str.withCString { String(format: "%-16s", $0) }
            new_powder.powder_name = fmtstr
            //update picker view with new powder name
            g_powder_manager.updateListItem(str, index: Int(g_powder_manager.currentPowder.powder_number)-1)
            powderPickerView.reloadAllComponents()
        } else {
            print("Failed to get powderNameField.text")
            return
        }
        if let val = Float32(powderFactorField.text!) {
            new_powder.powder_factor = val
        } else {
            print("ERROR: Powder Factor field is not a floating point number!")
            return
        }
        if let str = powderLotField.text {
            let fmtstr = str.withCString { String(format: "%-16s", $0) }
            new_powder.powder_lot = fmtstr
        } else {
            print("Failed to get powderLotField.text")
            return
        }
        // Now update the current powder (triggers invoke on listeners)
        g_powder_manager.currentPowder = new_powder
        g_powder_manager.BLEWritePowderData()

    }
    
    // MARK: - Form Validation
    
    @IBAction func powderNameFieldEndEdit(_ sender: Any) {
        var err = true
        if powderNameField.text!.count > 0 || powderNameField.text!.count <= MAX_NAME_LEN {
            let str = powderNameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let set = CharacterSet(charactersIn: str)
            var testSet = CharacterSet.letters
            testSet = testSet.union(CharacterSet.decimalDigits)
            testSet = testSet.union(CharacterSet([" ",".","-"]))
            if testSet.isSuperset(of: set) { err = false }
        }
        if err { setTextFieldError(powderNameLabel)
        } else { clearTextFieldError(powderNameLabel) }
        _ = anyError()
    }

    @IBAction func powderFactorFieldEndEdit(_ sender: Any) {
        var err = true
        if powderFactorField.text!.count > 0 || powderFactorField.text!.count <= MAX_NAME_LEN {
            let str = powderFactorField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let set = CharacterSet(charactersIn: str)
            let testSet = CharacterSet.decimalDigits.union(CharacterSet(Array(["."])))
            let regexp = try! NSRegularExpression(pattern: "[0]\\.[0-9]{2,5}", options: [])
            let sourceRange = NSRange(str.startIndex..<str.endIndex, in: str)
            let result = regexp.matches(in: str,options: [],range: sourceRange)
            if result.count > 0 && testSet.isSuperset(of: set) { err = false }
        }
        if err { setTextFieldError(powderFactorLabel)
        } else { clearTextFieldError(powderFactorLabel) }
        _ = anyError()
    }

    @IBAction func powderLotFieldEndEdit(_ sender: Any) {
        var err = true
        if powderLotField.text!.count > 0 || powderLotField.text!.count <= MAX_NAME_LEN {
            let str = powderLotField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let set = CharacterSet(charactersIn: str)
            var testSet = CharacterSet.letters
            testSet = testSet.union(CharacterSet.decimalDigits)
            testSet = testSet.union(CharacterSet([" ",".","-"]))
            if testSet.isSuperset(of: set) { err = false }
        }
        if err { setTextFieldError(powderLotLabel)
        } else { clearTextFieldError(powderLotLabel) }
        _ = anyError()
    }

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
        if row + 1 != g_powder_manager.currentPowder.powder_number {
            BlePeripheral().writeParameterCommand(cmd: BLE_COMMANDS.POWDER_DATA_BY_INDEX, parameter: Int8(row+1))
        }
    }
}

