//
//  ViewController.swift
//  SecretSwift
//
//  Created by My Nguyen on 8/17/16.
//  Copyright © 2016 My Nguyen. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    @IBOutlet weak var secret: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationCenter = NSNotificationCenter.defaultCenter()
        // receive notification when the keyboard hides
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIKeyboardWillHideNotification, object: nil)
        // receive notification when the keyboard changes
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIKeyboardWillChangeFrameNotification, object: nil)
        // call saveSecretMessage() upon receiving notification that the app becomes inactive
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplicationWillResignActiveNotification, object: nil)

        title = "Nothing to see here"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // tapping the button will unlock secret message
    @IBAction func authenticateUser(sender: AnyObject) {
        let context = LAContext()
        var error: NSError?

        // check whether the device is capable of supporting biometric authentication (fingerprint)
        if context.canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            // if so request that the Touch ID begin a check now, giving it a string containing the reason
            let reason = "Identify yourself!"
            context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [unowned self] (success: Bool, authenticationError: NSError?) -> Void in
                // make sure to operate on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    // before performing operations accordingly depending on the authentication's success
                    if success {
                        self.unlockSecretMessage()
                    } else {
                        // special case when the user requested to enter password instead; Touch ID
                        // includes this option on the screen as a fallback for users who are unable
                        // to user fingerprint scanning at this time
                        if let error = authenticationError {
                            // unwrap the optional error received and check to see if it equals
                            // LAError.UserFallback.rawValue; if so it means the user asked to enter a
                            // password, in which case we send a derisory message and return
                            if error.code == LAError.UserFallback.rawValue {
                                let ac = UIAlertController(title: "Passcode? Ha!", message: "It's Touch ID or nothing – sorry!", preferredStyle: .Alert)
                                ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                                self.presentViewController(ac, animated: true, completion: nil)
                                return
                            }
                        }

                        // at this point it means the error wasn't a fallback request, so show a generic
                        // error message to the user
                        let ac = UIAlertController(title: "Authentication failed", message: "Your fingerprint could not be verified; please try again.", preferredStyle: .Alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self.presentViewController(ac, animated: true, completion: nil)
                    }
                }
            }
        } else {
            // no Touch ID available: show an error
            let ac = UIAlertController(title: "Touch ID not available", message: "Your device is not configured for Touch ID.", preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(ac, animated: true, completion: nil)
        }
    }

    // see project Javascript-Safari for a detailed explanation of this method
    func adjustForKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!

        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)

        if notification.name == UIKeyboardWillHideNotification {
            secret.contentInset = UIEdgeInsetsZero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }

        secret.scrollIndicatorInsets = secret.contentInset

        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }

    // load the secret message into the text view
    func unlockSecretMessage() {
        secret.hidden = false
        title = "Secret stuff!"

        if let text = KeychainWrapper.stringForKey("SecretMessage") {
            secret.text = text
        }
    }

    // write the text view's message to the keychain, then hide it
    func saveSecretMessage() {
        if !secret.hidden {
            KeychainWrapper.setString(secret.text, forKey: "SecretMessage")
            // relinquish input focus on this view, to hide the keyboard
            secret.resignFirstResponder()
            secret.hidden = true
            title = "Nothing to see here"
        }
    }
}

