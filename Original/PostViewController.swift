//
//  PostViewController.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/07.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit
import NCMB
import SVProgressHUD
import UITextView_Placeholder

class PostViewController: UIViewController, UINavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var authorTextField: UITextField!
    @IBOutlet var genreTextField: UITextField!
    @IBOutlet var publisherTextField: UITextField?
    @IBOutlet var dateTextField: UITextField?
    @IBOutlet var postTextView: UITextView!
    @IBOutlet var postButton: UIBarButtonItem!

    override func viewWillAppear(_ animated: Bool) {
        if NCMBUser.current() == nil {
            let alert = UIAlertController(title: "ログインしますか？", message: "投稿機能を利用するにはログインが必要です。", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "ログインする", style: .default) { (action) in
                let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
                let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
                let keyWindow = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).map({$0 as? UIWindowScene}).compactMap({$0}).first?.windows.filter({$0.isKeyWindow}).first
                keyWindow?.rootViewController = rootViewController
                //ログイン状態の保持
                let ud = UserDefaults.standard
                ud.set(false, forKey: "isLogin")
                ud.synchronize()
            }
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
                alert.dismiss(animated: true, completion: nil)
                let UINavigationController = self.tabBarController?.viewControllers?[0]
                self.tabBarController?.selectedViewController = UINavigationController
                
                let ud = UserDefaults.standard
                ud.set(false, forKey: "isLogin")
                ud.synchronize()
            }
            
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        postButton.isEnabled = false
        postTextView.placeholder = "要約本文"
        postTextView.delegate = self
        titleTextField.delegate = self
        authorTextField.delegate = self
        genreTextField.delegate = self
        publisherTextField?.delegate = self
        dateTextField?.delegate = self
        
        //textViewに枠線付加
        postTextView.layer.borderColor = UIColor.black.cgColor //枠線の色
        postTextView.layer.borderWidth = 0.5 //枠線の幅
        //枠を角丸にする
        postTextView.layer.cornerRadius = 10.0
        postTextView.layer.masksToBounds = true
        
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        confirmContent()
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        confirmContent()
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    @IBAction func post() {
        SVProgressHUD.show()
        
        let postObject = NCMBObject(className: "Post")
        postObject?.setObject(self.postTextView.text!, forKey: "text")
        postObject?.setObject(self.titleTextField.text!, forKey: "title")
        postObject?.setObject(self.authorTextField.text!, forKey: "author")
        postObject?.setObject(self.genreTextField.text!, forKey: "genre")
        postObject?.setObject(self.publisherTextField?.text, forKey: "publisher")
        postObject?.setObject(self.dateTextField?.text, forKey: "date")
        postObject?.setObject(NCMBUser.current(), forKey: "user")
        postObject?.setObject(NCMBUser.current()?.objectId, forKey: "userId")
        postObject?.saveInBackground({ (error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                SVProgressHUD.dismiss()
                self.postTextView.text = nil
                self.titleTextField.text = nil
                self.authorTextField.text = nil
                self.genreTextField.text = nil
                self.publisherTextField?.text = nil
                self.dateTextField?.text = nil
                let alert = UIAlertController(title: "投稿完了！", message: "投稿が完了しました。", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    self.confirmContent()
                    alert.dismiss(animated: true, completion: nil)
                }
                alert.addAction(okAction)
                
                self.present(alert, animated: true, completion: nil)
            }
        })
    }

    func confirmContent() {
        if postTextView.text!.count > 0 && titleTextField.text!.count > 0 && authorTextField.text!.count > 0 && genreTextField.text!.count > 0 {
            postButton.isEnabled = true
        } else {
            postButton.isEnabled = false
        }
    }

}
