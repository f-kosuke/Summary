//
//  SignUpViewController.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/06.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit
import NCMB
import SVProgressHUD

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var confirmTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmTextField.delegate = self
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func signUp() {
        let user = NCMBUser()
        let groupACL = NCMBACL()
        
        if (userNameTextField.text?.count)! < 4 {
            print("文字数が足りません")
            return
        }
        
        user.userName = userNameTextField.text!
        user.mailAddress = emailTextField.text!
        
        if passwordTextField.text == confirmTextField.text {
            user.password = passwordTextField.text!
        } else {
            print("パスワードの不一致")
        }
        
        user.signUpInBackground { (error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootTabBarController")
                let keyWindow = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).map({$0 as? UIWindowScene}).compactMap({$0}).first?.windows.filter({$0.isKeyWindow}).first
                keyWindow?.rootViewController = rootViewController
                
                
                //会員本人（currentUser）の権限
                //for: userは、自分（currentUser）に対してacl情報を書き換える
                groupACL.setReadAccess(true, for: user)
                groupACL.setWriteAccess(true, for: user)
                
                //全てのユーザの権限
                //setPublicReadAccessをtrueにすれば他人の情報を取得可能！
                //基本的にsetPublicWriteAccessをtrueにすると、他人でもユーザ消したり、情報変更できてしまうから注意
                groupACL.setPublicReadAccess(true)
                groupACL.setPublicWriteAccess(false)
                
                //userクラスにこれまで設定してきたACL情報をセット
                user.acl = groupACL
                
                //userデータ(設定したacl情報)を保存する
                user.save(nil)
                
                
                
                //ログイン状態の保持
                let ud = UserDefaults.standard
                ud.set(true, forKey: "isLogin")
                ud.synchronize()
            }
        }
        
    }
    
}
