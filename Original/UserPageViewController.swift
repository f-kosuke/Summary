//
//  UserPageViewController.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/20.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit
import NCMB
import NYXImagesKit
import SVProgressHUD
class UserPageViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var userNameTextField: UITextField!
    @IBOutlet var historyTableView: UITableView!
    var historys = [Post]()
    //var myPagePosts: [Post]!
    var myPosts = [Post]()
    var myFavPosts = [Post]()
    var number: Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.tableFooterView = UIView()
        historyTableView.rowHeight = 185
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        if let user = NCMBUser.current() {
            userNameTextField.text = user.userName
            let file = NCMBFile.file(withName: user.objectId, data: nil) as! NCMBFile
            file.getDataInBackground { (data, error) in
                if error != nil {
                    
                } else {
                    let image = UIImage(data: data!)
                    self.userImageView.image = image
                }
            }
        } else {
            let alert = UIAlertController(title: "ログインしますか？", message: "マイページを利用するにはログインが必要です。", preferredStyle: .alert)
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
        //閲覧履歴
        loadHistory()
        //自分の投稿
        getMyPostsData()
        //お気に入り投稿
        getFavoritePostsData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historys.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        let userNameLabel = cell.viewWithTag(1) as! UILabel
        let titleLabel = cell.viewWithTag(2) as! UILabel
        let authorLabel = cell.viewWithTag(3) as! UILabel
        let genreLabel = cell.viewWithTag(4) as! UILabel
        let history = historys[indexPath.row]
        userNameLabel.text = "投稿者名：" + history.user.userName
        titleLabel.text = history.title
        authorLabel.text = "著者名：" + history.author
        genreLabel.text = "ジャンル：" + history.genre
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

//        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
//        let detailViewController = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
//
//        detailViewController.selectedPost = historys[indexPath.row]

//        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "toDetail", sender: nil)
    }
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let selectedIndex = historyTableView.indexPathForSelectedRow!
            detailViewController.selectedPost = historys[selectedIndex.row]
            
            
        }
    }
    
    func getMyPostsData(){
        let query = NCMBQuery(className: "Post")
        query?.includeKey("user")
        query?.whereKey("user", equalTo: NCMBUser.current())
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                //self.myPagePosts = [Post]()
                var postObj: [String] = []
                for i in self.myPosts{
                    postObj.append(i.objectId)
                }
                for postObject in result as! [NCMBObject] {
                    let user = postObject.object(forKey: "user") as! NCMBUser
                    let userModel = User(objectId: user.objectId, userName: user.userName)
                    let title = postObject.object(forKey: "title") as! String
                    let author = postObject.object(forKey: "author") as! String
                    let genre = postObject.object(forKey: "genre") as! String
                    let text = postObject.object(forKey: "text") as! String
                    let post = Post(objectId: postObject.objectId, user: userModel, title: title, author: author, genre: genre, createDate: postObject.createDate, text: text)
                    if let publish = postObject.object(forKey: "publisher") {
                        post.publisher = publish as? String
                    }
                    if let date = postObject.object(forKey: "date") {
                        post.date = date as? String
                    }
                    if postObj.contains(post.objectId){
                        print("重複あるっぽい")
                    }else{
                        self.myPosts.append(post)
                    }
                }
            }
        })
    }
    func getFavoritePostsData(){
        let query = NCMBQuery(className: "Post")
        query?.includeKey("user")
        query?.whereKey("likeUser", equalTo: NCMBUser.current()?.objectId)
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                var postObj: [String] = []
                for i in self.myFavPosts{
                    postObj.append(i.objectId)
                }
                for likeObject in result as! [NCMBObject] {
                    let user = likeObject.object(forKey: "user") as! NCMBUser
                    let userModel = User(objectId: user.objectId, userName: user.userName)
                    let title = likeObject.object(forKey: "title") as! String
                    let author = likeObject.object(forKey: "author") as! String
                    let genre = likeObject.object(forKey: "genre") as! String
                    let text = likeObject.object(forKey: "text") as! String
                    let post = Post(objectId: likeObject.objectId, user: userModel, title: title, author: author, genre: genre, createDate: likeObject.createDate, text: text)
                    if let publish = likeObject.object(forKey: "publisher") {
                        post.publisher = publish as? String
                    }
                    if let date = likeObject.object(forKey: "date") {
                        post.date = date as? String
                    }
                    if postObj.contains(post.objectId){
                        print("重複あるっぽい")
                    }else{
                        self.myFavPosts.append(post)
                    }
                }
            }
        })
    }
    
    
    enum actionTag: Int {
        case action1 = 0
        case action2 = 1
    }
    
    @IBAction func toMyPost(_ sender: Any) {
        if let button = sender as? UIButton {
            if let tag = actionTag(rawValue: button.tag){
                switch tag {
                case .action1:
                    buttonAction1()
                case .action2:
                    buttonAction2()
                }
            }
        }
    }
    
    func buttonAction1(){
        let favVC = self.storyboard?.instantiateViewController(withIdentifier: "myPagePostsView") as! MyPagePostsViewController
        favVC.posts = self.myFavPosts
        self.navigationController?.pushViewController(favVC, animated: true)
    }
    
    func buttonAction2() {
        let historyVC = self.storyboard?.instantiateViewController(withIdentifier: "myPagePostsView") as! MyPagePostsViewController
        historyVC.posts = self.myPosts
        self.navigationController?.pushViewController(historyVC, animated: true)
    }
    
    
    
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        let resizedImage = selectedImage.scale(byFactor: 0.4)
        picker.dismiss(animated: true, completion: nil)
        let data = UIImage.pngData(resizedImage!)
        let file = NCMBFile.file(withName: NCMBUser.current()?.objectId, data: data()) as! NCMBFile
        file.saveInBackground({ (error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                self.userImageView.image = selectedImage
            }
        }) { (progress) in
            print(progress)
        }
    }
    @IBAction func selectImage() {
        let actionController = UIAlertController(title: "画像の選択", message: "選択してください", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "カメラ", style: .default) { (action) in
            //カメラ起動
            if UIImagePickerController.isSourceTypeAvailable(.camera) == true {
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            } else {
                print("この機種ではカメラが使用できません")
            }
        }
        let albumAction = UIAlertAction(title: "フォトライブラリ", style: .default) { (action) in
            //アルバム起動
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == true {
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            } else {
                print("この機種ではフォトライブラリが使用できません")
            }
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) {
            (action) in
            actionController.dismiss(animated: true, completion: nil)
        }
        actionController.addAction(cameraAction)
        actionController.addAction(albumAction)
        actionController.addAction(cancelAction)
        actionController.popoverPresentationController?.sourceView = self.view
        
        let screenSize = UIScreen.main.bounds
        // ここで表示位置を調整
        // xは画面中央、yは画面下部になる様に指定
        actionController.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)

        self.present(actionController, animated: true, completion: nil)
    }
    
    
    
    
    
    @IBAction func saveUserInfo() {
        let user = NCMBUser.current()
        user?.setObject(userNameTextField.text, forKey: "userName")
        user?.saveInBackground({ (error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func logOut(){
        let alertController = UIAlertController(title: "メニュー", message: "メニューを選択してください", preferredStyle: .actionSheet)
        let signOutAction = UIAlertAction(title: "ログアウト", style: .default) { (action) in
            NCMBUser.logOutInBackground({ (error) in
                if error != nil{
                    print(error)
                }else{
                    //ログアウト成功した場合
                    let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
                    let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
                    UIApplication.shared.keyWindow?.rootViewController = rootViewController
                    //ログアウト状態の保持
                    let ud = UserDefaults.standard
                    ud.set(false, forKey: "isLogin")
                    ud.synchronize()
                }
            })
        }
        let deleteAction = UIAlertAction(title: "退会", style: .default) { (action) in
            let user = NCMBUser.current()
            user?.deleteInBackground({ (error) in
                if error != nil{
                    print(error)
                }else{
                    //ログアウト成功した場合
                    let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
                    let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
                    UIApplication.shared.keyWindow?.rootViewController = rootViewController
                    //ログアウト状態の保持
                    let ud = UserDefaults.standard
                    ud.set(false, forKey: "isLogin")
                    ud.synchronize()
                }
            })
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(signOutAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        
        let screenSize = UIScreen.main.bounds
        // ここで表示位置を調整
        // xは画面中央、yは画面下部になる様に指定
        alertController.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)

        self.present(alertController, animated: true, completion: nil)
    }
    
    
//    func loadHistory() {
//        historys = [Post]()
//        let query = NCMBQuery(className: "History")
//        query?.includeKey("user")
//        query?.includeKey("post")
//        query?.whereKey("user", equalTo: NCMBUser.current())
//        query?.findObjectsInBackground({ (result, error) in
//            for historyObject in result as! [NCMBObject] {
//                let post = historyObject.object(forKey: "post") as! NCMBObject
//                let user = post.object(forKey: "user") as! NCMBUser
//                let userQuery = NCMBQuery(className: "user")
//                userQuery?.getObjectInBackground(withId: user.objectId, block: { (userObject, error) in
//                    let userName = userObject?.object(forKey: "userName") as! String
//                    let userModel = User(objectId: user.objectId, userName: userName)
//                    let title = post.object(forKey: "title") as! String
//                    let author = post.object(forKey: "author") as! String
//                    let genre = post.object(forKey: "genre") as! String
//                    let text = post.object(forKey: "text") as! String
//                    let post1 = Post(objectId: post.objectId, user: userModel, title: title, author: author, genre: genre, createDate: post.createDate, text: text)
//                    if let publish = post.object(forKey: "publisher") {
//                        post1.publisher = publish as? String
//                    }
//                    if let date = post.object(forKey: "date") {
//                        post1.date = date as? String
//                    }
//                    self.historys.append(post1)
//                    //処理を一歩遅らせる
//                    DispatchQueue.main.async {
//                        self.historyTableView.reloadData()
//                    }
//                })
//            }
//        })
//    }
    
    
    
    func loadHistory(){
        self.historys = [Post]()
        let query = NCMBQuery(className: "History")
        query?.includeKey("user")
        query?.includeKey("post")
        query?.whereKey("user", equalTo: NCMBUser.current())
        query?.order(byDescending: "createDate")
        query?.findObjectsInBackground({ (result, error) in
            for historyObject in result as! [NCMBObject] {
                let post = historyObject.object(forKey: "post") as! NCMBObject
                let user = post.object(forKey: "user") as! NCMBUser
                let userQuery = NCMBQuery(className: "user")
                //userQuery?.whereKey("userName", equalTo: user.object(forKey: "userName"))
                userQuery?.whereKey("objectId", equalTo: user.objectId)
                //userQuery?.related(to: "Post", objectId: user.objectId, key: "user")
                userQuery?.findObjectsInBackground({ (result, error) in
                    if error != nil{
                        print(error)
                    }else{
                    for userInfo in result as! [NCMBObject]{
                        let userName = userInfo.object(forKey: "userName") as! String
                        let userModel = User(objectId: user.objectId, userName: userName)
                        let title = post.object(forKey: "title") as! String
                        let author = post.object(forKey: "author") as! String
                        let genre = post.object(forKey: "genre") as! String
                        let text = post.object(forKey: "text") as! String
                        let post1 = Post(objectId: post.objectId, user: userModel, title: title, author: author, genre: genre, createDate: post.createDate, text: text)
                        if let publish = post.object(forKey: "publisher") {
                            post1.publisher = publish as? String
                        }
                        if let date = post.object(forKey: "date") {
                            post1.date = date as? String
                        }
                        self.historys.append(post1)
                        //処理を一歩遅らせる
                        DispatchQueue.main.async {
                            self.historyTableView.reloadData()
                        }
                    }
                    }
                })

            }
        })
    }
    
    
}
