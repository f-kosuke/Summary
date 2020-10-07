//
//  SignInViewController.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/06.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit
import NCMB
import SVProgressHUD

class SignInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        userNameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    @IBAction func signIn() {
        if (userNameTextField.text!.count) > 0 && (passwordTextField.text!.count) > 0 {
            NCMBUser.logInWithUsername(inBackground: userNameTextField.text!, password: passwordTextField.text!) { (user, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error?.localizedDescription)
                } else {
                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                    let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootTabBarController")
                    let keyWindow = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).map({$0 as? UIWindowScene}).compactMap({$0}).first?.windows.filter({$0.isKeyWindow}).first
                    keyWindow?.rootViewController = rootViewController
                    
                    //ログイン状態の保持
                    let ud = UserDefaults.standard
                    ud.set(true, forKey: "isLogin")
                    ud.synchronize()
                }}
        }
    }
    
    @IBAction func cancel() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootTabBarController")
        UIApplication.shared.keyWindow?.rootViewController = rootViewController
        
        //ログイン状態の保持
        let ud = UserDefaults.standard
        ud.set(false, forKey: "isLogin")
        ud.synchronize()
    }
    
}
