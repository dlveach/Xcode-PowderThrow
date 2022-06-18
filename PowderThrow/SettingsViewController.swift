//
//  SettingsViewController.swift
//  PowderThrow
//
//  Created by David Veach on 6/18/22.
//

import UIKit
import CoreBluetooth

class  SettingsViewController: UIViewController {
    
    @IBOutlet weak var bumpThresholdLabel: UILabel!
    @IBOutlet weak var toleranceLabel: UILabel!
    @IBOutlet weak var FScalePLabel: UILabel!
    @IBOutlet weak var decelLimitLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        
        bumpThresholdLabel.text = String(format: "Bump: %4.2f gn", ConfigData.bump_threshold)
        decelLimitLabel.text = "Dec Lim: \(ConfigData.decel_limit)"
        FScalePLabel.text = String(format: "FScaleP: %.1f", ConfigData.fscaleP)
        //TODO: handle mode change to grams!
        toleranceLabel.text = String(format: "Tol: %.2f gn", ConfigData.gn_tolerance)

    }
    
}
