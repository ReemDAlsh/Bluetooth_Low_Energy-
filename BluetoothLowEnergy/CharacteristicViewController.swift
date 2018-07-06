//
//  CharacteristicViewController.swift
//  BluetoothLowEnergy
//
//  Created by Reem alsharif on 4/26/18.
//  Copyright © 2018 Reem alsharif. All rights reserved.
//

import Foundation

import Foundation

import UIKit
import CoreBluetooth

/**
 This view talks to a Characteristic
 */
class CharacteristicViewController: UIViewController, CBCentralManagerDelegate, BlePeripheralDelegate {
    
    // MARK: UI elements
    @IBOutlet weak var advertisedNameLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var characteristicUuidlabel: UILabel!
    @IBOutlet weak var readCharacteristicButton: UIButton!
    @IBOutlet weak var characteristicValueText: UITextView!
    @IBOutlet weak var writeCharacteristicButton: UIButton!
    @IBOutlet weak var writeCharacteristicText: UITextField!
    @IBOutlet weak var subscribeToNotificationLabel: UILabel!
    @IBOutlet weak var subscribeToNotificationsSwitch: UISwitch!
    
    
    // MARK: Connected devices
    
    // Central Bluetooth Radio
    var centralManager:CBCentralManager!
    
    // Bluetooth Peripheral
    var blePeripheral:BlePeripheral!
    
    // Connected Characteristic
    var connectedService:CBService!
    
    // Connected Characteristic
    var connectedCharacteristic:CBCharacteristic!
    
    
    /**
     UIView loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Will connect to device \(blePeripheral.peripheral.identifier.uuidString)")
        print("Will connect to characteristic \(connectedCharacteristic.uuid.uuidString)")
        
        centralManager.delegate = self
        blePeripheral.delegate = self
        
        loadUI()
        
    }
    
    
    /**
     Load UI elements
     */
    func loadUI() {
        advertisedNameLabel.text = blePeripheral.advertisedName
        identifierLabel.text = blePeripheral.peripheral.identifier.uuidString
        
        characteristicUuidlabel.text = connectedCharacteristic.uuid.uuidString
        readCharacteristicButton.isEnabled = true
        
        // characteristic is not readable
        if !BlePeripheral.isCharacteristic(isReadable: connectedCharacteristic) {
            readCharacteristicButton.isHidden = true
            characteristicValueText.isHidden = true
        }
        
        // characteristic is not writeable
        if !BlePeripheral.isCharacteristic(isWriteable: connectedCharacteristic) {
            writeCharacteristicText.isHidden = true
            writeCharacteristicButton.isHidden = true
        }
        
        // characteristic is not writeable
        if !BlePeripheral.isCharacteristic(isNotifiable: connectedCharacteristic) {
            subscribeToNotificationsSwitch.isHidden = true
            subscribeToNotificationLabel.isHidden = true
        }
        
    }
    
    
    /**
     User touched Read button.  Request to read the Characteristic
     */
    @IBAction func onReadCharacteristicButtonTouched(_ sender: UIButton) {
        print("pressed button")
        
        readCharacteristicButton.isEnabled = false
        blePeripheral.readValue(from: connectedCharacteristic)
    }
    
    /**
     User touched write button. Request to write to the Characteristic
     */
    @IBAction func onWriteCharacteristicButtonTouched(_ sender: UIButton) {
        print("write button pressed")
        writeCharacteristicButton.isEnabled = false
        if let stringValue = writeCharacteristicText.text {
            print(stringValue)
            if stringValue.isValidHexNumber() {
                blePeripheral.writeValue(value: stringValue, to: connectedCharacteristic)
                writeCharacteristicText.text = ""
            } else {
                showAlert()
            }
            
        }
        
    }
    
    /**
     User toggled the notification switch. Request to subscribe or unsubscribe from the Characteristic
     */
    @IBAction func onSubscriptionToNotificationSwitchChanged(_ sender: UISwitch) {
        print("Notification Switch toggled")
        subscribeToNotificationsSwitch.isEnabled = false
        if sender.isOn {
            blePeripheral.subscribeTo(characteristic: connectedCharacteristic)
        } else {
            blePeripheral.unsubscribeFrom(characteristic: connectedCharacteristic)
        }
        
    }
    
    
    // MARK: BlePeripheralDelegate
    
    /**
     Characteristic was written to.  Update UI
     */
    func blePeripheral(valueWritten characteristic: CBCharacteristic, blePeripheral: BlePeripheral) {
        print("value written to characteristic!")
        writeCharacteristicButton.isEnabled = true
    }
    
    
    
    /**
     Characteristic subscription status changed.  Update UI
     */
    func blePeripheral(subscriptionStateChanged subscribed: Bool, characteristic: CBCharacteristic, blePeripheral: BlePeripheral) {
        if characteristic.isNotifying {
            subscribeToNotificationsSwitch.isOn = true
        } else {
            subscribeToNotificationsSwitch.isOn = false
        }
        subscribeToNotificationsSwitch.isEnabled = true
    }
    
    /**
     Characteristic was read.  Update UI
     */
    func blePeripheral(characteristicRead stringValue: String, characteristic: CBCharacteristic, blePeripheral: BlePeripheral) {
        print(stringValue)
        
      print(stringValue)
        
        
        readCharacteristicButton.isEnabled =  true
        characteristicValueText.insertText(stringValue + "\n")
        let stringLength = characteristicValueText.text.characters.count
        characteristicValueText.scrollRangeToVisible(NSMakeRange(stringLength-1, 0))
    }
    
    
    // MARK: CBCentralManagerDelegate
    
    /**
     Peripheral disconnected
     
     - Parameters:
     - central: the reference to the central
     - peripheral: the connected Peripheral
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // disconnected.  Leave
        print("disconnected")
        if let navController = navigationController {
            navController.popToRootViewController(animated: true)
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    
    /**
     Bluetooth radio state changed
     
     - Parameters:
     - central: the reference to the central
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager updated: checking state")
        
        switch (central.state) {
        case .poweredOn:
            print("bluetooth on")
        default:
            print("bluetooth unavailable")
        }
    }
    
    
    
    // MARK: - Navigation
    
    /**
     Animate the segue
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let connectedBlePeripheral = blePeripheral {
            centralManager.cancelPeripheralConnection(connectedBlePeripheral.peripheral)
        }
    }
    
    func showAlert() {
        let alertController = UIAlertController(title: "Valid Hex", message: "Please enter valid Hex Values", preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func hexToString(hex: String) -> String? {
        guard hex.characters.count % 2 == 0 else {
            return nil
        }
        
        var bytes = [CChar]()
        
        var startIndex = hex.index(hex.startIndex, offsetBy: 2)
        while startIndex < hex.endIndex {
            let endIndex = hex.index(startIndex, offsetBy: 2)
            let substr = hex[startIndex..<endIndex]
            
            if let byte = Int8(substr, radix: 16) {
                bytes.append(byte)
            } else {
                return nil
            }
            
            startIndex = endIndex
        }
        
        bytes.append(0)
        return String(cString: bytes)
    }
}
extension Data
{
    func toString() -> String
    {
        return String(data: self, encoding: .utf8)!
    }
}
