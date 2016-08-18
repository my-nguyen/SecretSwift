//
//  ViewController.swift
//  SecretSwift
//
//  Created by My Nguyen on 8/17/16.
//  Copyright © 2016 My Nguyen. All rights reserved.
//

import UIKit

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
        unlockSecretMessage()
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

