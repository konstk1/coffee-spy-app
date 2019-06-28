//
//  RoastDetailViewController.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 6/27/19.
//  Copyright © 2019 KK. All rights reserved.
//

import UIKit
import Eureka

class RoastDetailViewController: FormViewController {
    
    var roast: Roast?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildForm()
    }
    
    @IBAction func cancelPushed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Form
extension RoastDetailViewController {
    func buildForm() {
        form
            +++ buildBeanSection()
            +++ buildRoastSection()
    }
    
    func buildBeanSection() -> Section {
        let section = Section("Bean")
        
        section
       
        <<< TextRow {
            $0.title = "Seller"
        }
        
        <<< PushRow<Country> {
            // TODO: make this pick from list sectioned by continent
            $0.title = "Country"
            $0.options = Country.availableCountries
            $0.selectorTitle = "Choose country"
        }.onPresent { from, to in
            to.dismissOnSelection = true
            to.dismissOnChange = true
            to.sectionKeyForValue = {
                return $0.region.rawValue
            }
        }
            
        <<< TextRow {
            // TODO: make this pick from list
            $0.title = "Process"
        }
            
        <<< SwitchRow {
            $0.title = "Decaf"
            $0.value = false
        }
        
        return section
    }
    
    func buildRoastSection() -> Section {
        let section = Section("Roast")
        
        section
        
        <<< TextRow {
            $0.title = "Weight"
        }
            
        <<< TextRow {
            $0.title = "Duration"
        }
        
        <<< TextRow {
            $0.title = "Drop"
        }
        
        <<< TextRow {
            $0.title = "First Crack"
        }
        
        <<< TextRow {
            $0.title = "Second Crack"
        }
        
        // TODO: add roast button (start or view)
        
        return section
    }
}
