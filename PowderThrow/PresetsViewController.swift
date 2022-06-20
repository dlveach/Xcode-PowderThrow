//
//  PresetsViewController.swift
//  PowderThrow
//
//  Created by David Veach on 6/18/22.
//

import UIKit
import CoreBluetooth

class  PresetsViewController: UIViewController {
    
    private var myPeripheral = BlePeripheral.connectedPeripheral
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Presets"
        
        let p = BlePeripheral()
        
        if let c = BlePeripheral.connectedParameterCommandChar {
            print("Command Button Characteristic: \(c.uuid)")
        } else {
            print("Command button charactaristic is nil")
        }
        
        // Load preset list from peripheral
        p.writeParameterCommand(cmd: BLE_COMMANDS.PRESET_BY_INDEX, parameter: 2)
    }
    
    
}
