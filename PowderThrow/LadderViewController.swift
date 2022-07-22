//
//  LadderViewController.swift
//  PowderThrow
//
//  Created by David Veach on 7/15/22.
//

import UIKit
import CoreBluetooth

class LadderViewController: UIViewController, UITextFieldDelegate, ScreenChangeListener {

    private var _isEditing = false
    var ble_nav = false

    @IBOutlet weak var powderNameLabel: UILabel!
    @IBOutlet weak var startGrainsField: UITextField!
    @IBOutlet weak var numberOfStepsField: UITextField!
    @IBOutlet weak var grainsPerStepField: UITextField!
    @IBOutlet weak var startGrainsLabel: UILabel!
    @IBOutlet weak var numberOfStepsLabel: UILabel!
    @IBOutlet weak var grainsPerStepLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    
    // MARK: - Navigation

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
                g_screen_manager.removeListener(self)
            }
        } else {
            // not on nav at all
            print("ERROR: View \(String(describing: self)) is not on nav controller at all!")
        }
    }

    // MARK: - View Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ladder Setup"

        //custom back button
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "< System Run", style: UIBarButtonItem.Style.plain, target: self, action: #selector(LadderViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton

        // Enable dismissing the keyboard popup by tapping outside
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)

        // Set delgates
        startGrainsField.delegate = self
        numberOfStepsField.delegate = self
        grainsPerStepField.delegate = self

        //set up default view conditions
        saveButton.layer.cornerRadius = 8
        saveButton.isHidden = true
        clearButton.layer.cornerRadius = 8
        if g_ladder_data.is_configured {
            var str = String(format: "%7.2f", g_ladder_data.start_weight)
            str = str.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
            startGrainsField.text = str.trimmingCharacters(in: .whitespacesAndNewlines)
            numberOfStepsField.text = "\(g_ladder_data.step_count)"
            str = String(format: "%7.2f", g_ladder_data.step_interval)
            str = str.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
            grainsPerStepField.text = str.trimmingCharacters(in: .whitespacesAndNewlines)
            clearButton.isHidden = false
        } else {
            var str = String(format: "%7.2f", g_preset_manager.currentPreset.charge_weight)
            str = str.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
            startGrainsField.text = str.trimmingCharacters(in: .whitespacesAndNewlines)
            numberOfStepsField.text = ""
            grainsPerStepField.text = ""
            clearButton.isHidden = true
        }
        powderNameLabel.text = g_powder_manager.currentPowder.powder_name
        g_screen_manager.addListener(self)
    }

    // MARK: - Change Listener Callbacks

    func screenChanged(to new_screen: ScreenChangeManager.Screen) {
        if new_screen == ScreenChangeManager.Screen.ViewController {
            _ = self.navigationController?.popToRootViewController(animated: true)
            ble_nav = true
        } else {
            print("Ladder VC: ignoring screen change to view controller: \(new_screen.description)")
        }
    }

    
    // MARK: - Button Handlers

    @IBAction func saveButtonAction(_ sender: Any) {

        if anyError() { return }

        //TODO: does this need to be wrapped in error handling?
        g_ladder_data.is_configured = true
        g_ladder_data.step_count = Int32(numberOfStepsField.text!.trimmingCharacters(in: .whitespacesAndNewlines))!
        g_ladder_data.start_weight = Float32(startGrainsField.text!.trimmingCharacters(in: .whitespacesAndNewlines))!
        g_ladder_data.step_interval = Float32(grainsPerStepField.text!.trimmingCharacters(in: .whitespacesAndNewlines))!
        g_ladder_data.current_step = 1
        
        writeLadderDataToBLE()
                
        saveButton.isHidden = true
        clearButton.isHidden = false
        _isEditing = false

        //pop view back to run view controller
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clearButtonAction(_ sender: Any) {

        print("TODO: confirm dialog on clear ??")

        var str = String(format: "%7.2f", g_preset_manager.currentPreset.charge_weight)
        str = str.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
        startGrainsField.text = str.trimmingCharacters(in: .whitespacesAndNewlines)
        numberOfStepsField.text = ""
        grainsPerStepField.text = ""

        g_ladder_data.is_configured = false
        g_ladder_data.start_weight = 0
        g_ladder_data.step_count = 0
        g_ladder_data.current_step = 0
        g_ladder_data.step_interval = 0
        
        writeLadderDataToBLE()
        
        saveButton.isHidden = true
        clearButton.isHidden = true
        _isEditing = false
    }
    
    func writeLadderDataToBLE() {
        var _data: Data = Data(bytes: &g_ladder_data.is_configured, count: MemoryLayout<Bool>.stride)
        _data.append(Data(bytes: &g_ladder_data.step_count, count: MemoryLayout<Int32>.stride))
        _data.append(Data(bytes: &g_ladder_data.current_step, count: MemoryLayout<Int32>.stride))
        _data.append(Data(bytes: &g_ladder_data.start_weight, count: MemoryLayout<Float32>.stride))
        _data.append(Data(bytes: &g_ladder_data.step_interval, count: MemoryLayout<Float32>.stride))

        //print("bytes to send: \(_data.count)")
        //print("_data: \(String(describing: Array(_data)))")

        BlePeripheral().writeLadderData(outgoingData: _data)
    }
    
    // MARK: - Form Validation

    @IBAction func startGrainsFieldChanged(_ sender: Any) {
        if anyError() { saveButton.isHidden = true
        } else { saveButton.isHidden = false }
        _isEditing = true
    }
    
    @IBAction func numberOfStepsFieldChanged(_ sender: Any) {
        if anyError() { saveButton.isHidden = true
        } else { saveButton.isHidden = false }
        _isEditing = true
    }
    
    @IBAction func grainsPerStepFieldChanged(_ sender: Any) {
        if anyError() { saveButton.isHidden = true
        } else { saveButton.isHidden = false }
        _isEditing = true
    }
    
    @IBAction func startGrainsFieldEndEdit(_ sender: Any) {
        var err = true
        if startGrainsField.text!.count >= 3 && startGrainsField.text!.count <= 6 {
            var str = startGrainsField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            if let val = Float(str) {
                str = String(format: "%07.2f", val)
                str = str.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
                let set = CharacterSet(charactersIn: str)
                let testSet = CharacterSet.decimalDigits.union(CharacterSet(Array(["."])))
                let regexp = try! NSRegularExpression(pattern: "[0-9]{1,3}\\.[0-9]{1,2}", options: [])
                let sourceRange = NSRange(str.startIndex..<str.endIndex, in: str)
                let result = regexp.matches(in: str,options: [],range: sourceRange)
                if result.count > 0 && testSet.isSuperset(of: set) {
                    err = false
                    startGrainsField.text = str
                }
            }
        }
        if err { setTextFieldError(startGrainsLabel)
        } else { clearTextFieldError(startGrainsLabel) }
        _ = anyError()
    }
    
    @IBAction func numberOfStepsFieldEndEdit(_ sender: Any) {
        var err = true
        if numberOfStepsField.text!.count > 0 || numberOfStepsField.text!.count <= 2 {
            if let val = Int(numberOfStepsField.text ?? "0") {
                if val > 1 && val <= 20 { err = false }
            }
        }
        if err { setTextFieldError(numberOfStepsLabel)
        } else { clearTextFieldError(numberOfStepsLabel) }
        _ = anyError()
    }
    
    @IBAction func grainsPerStepFieldEndEdit(_ sender: Any) {
        var err = true
        if grainsPerStepField.text!.count > 2 || grainsPerStepField.text!.count < 5 {
            var str = grainsPerStepField.text
            if let val = Float(str!) {
                str = String(format: "%04.2f", val)
                let set = CharacterSet(charactersIn: str!)
                let testSet = CharacterSet.decimalDigits.union(CharacterSet(Array(["."])))
                let regexp = try! NSRegularExpression(pattern: "[0-9]\\.[0-9]{1,2}", options: [])
                let sourceRange = NSRange(str!.startIndex..<str!.endIndex, in: str!)
                let result = regexp.matches(in: str!,options: [],range: sourceRange)
                if result.count > 0 && testSet.isSuperset(of: set) {
                    err = false
                    grainsPerStepField.text = str
                }
            }
        }
        if err { setTextFieldError(grainsPerStepLabel)
        } else { clearTextFieldError(grainsPerStepLabel) }
        _ = anyError()
    }
    
    func anyError() -> Bool {
        if startGrainsLabel.layer.borderWidth > 0 ||
            numberOfStepsLabel.layer.borderWidth > 0 ||
            grainsPerStepLabel.layer.borderWidth > 0 ||
            startGrainsField.text?.count == 0 ||
            numberOfStepsField.text?.count == 0 ||
            grainsPerStepField.text?.count == 0
        {
            saveButton.isHidden = true
            return (true)
        } else {
            saveButton.isHidden = false
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
