//
//  DetailViewController.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/10.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit
import NCMB
import SVProgressHUD

class DetailViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var selectedPost: Post!
    var comments = [Comment]()
    var array = [String]()
    
    @IBOutlet var titleNavigationTitle: UINavigationItem!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var genreLabel: UILabel!
    @IBOutlet var publisherLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var postTextView: UITextView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var createDateLabel: UILabel!
    @IBOutlet var commentTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTableView.delegate = self
        commentTableView.dataSource = self

        //textViewに枠線付加
        postTextView.layer.borderColor = UIColor.black.cgColor //枠線の色
        postTextView.layer.borderWidth = 0.5 //枠線の幅
        //枠を角丸にする
        postTextView.layer.cornerRadius = 10.0
        postTextView.layer.masksToBounds = true
        
        commentTableView.tableFooterView = UIView()
        commentTableView.estimatedRowHeight = 100
        commentTableView.rowHeight = UITableView.automaticDimension
        
        loadDetail()
        loadComments()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        //let userImageView = cell.viewWithTag(1) as! UIImageView
        let userNameLabel = cell.viewWithTag(2) as! UILabel
        let commentLabel = cell.viewWithTag(3) as! UILabel
        // let createDateLabel = cell.viewWithTag(4) as! UILabel

        // ユーザー画像を丸く
        //userImageView.layer.cornerRadius = userImageView.bounds.width / 2.0
        //userImageView.layer.masksToBounds = true

        let user = comments[indexPath.row].user
        /*let userImagePath = "https://mbaas.api.nifcloud.com/2013-09-01/applications/uJP7UoFSRIGNPM4X/publicFiles/" + user.objectId
        userImageView.kf.setImage(with: URL(string: userImagePath))*/
        userNameLabel.text = user.userName
        commentLabel.text = comments[indexPath.row].text

        return cell
    }
    

    func loadDetail() {
        titleNavigationTitle.title = selectedPost.title
        authorLabel.text = selectedPost.author
        genreLabel.text = selectedPost.genre
        if  selectedPost.publisher != "" {
            publisherLabel.text = selectedPost.publisher
        } else {
            publisherLabel.text = "出版社：不明"
        }
        if selectedPost.date != "" {
            dateLabel.text = selectedPost.date
        } else {
            dateLabel.text = "出版日時：不明"
        }
        postTextView.text = selectedPost.text
        userNameLabel.text = selectedPost.user.userName
        let createDate = selectedPost.createDate
        createDateLabel.text = stringFromDate(date: createDate, format: "yyyy年MM月dd日 HH時mm分ss秒")

    }
    
    func stringFromDate(date: Date, format: String) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    func loadComments() {
        comments = [Comment]()
        let query = NCMBQuery(className: "Comment")
        query?.whereKey("postId", equalTo: selectedPost.objectId)
        query?.includeKey("user")
        query?.findObjectsInBackground({ (result, error) in
            if error != nil {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
            } else {
                for commentObject in result as! [NCMBObject] {
                    // コメントをしたユーザーの情報を取得
                    let user = commentObject.object(forKey: "user") as! NCMBUser
                    let userModel = User(objectId: user.objectId, userName: user.userName)
                    userModel.userName = user.object(forKey: "userName") as! String

                    // コメントの文字を取得
                    let text = commentObject.object(forKey: "text") as! String

                    // Commentクラスに格納
                    let comment = Comment(postId: self.selectedPost.objectId, user: userModel, text: text)
                    self.comments.append(comment)

                    // テーブルをリロード
                    self.commentTableView.reloadData()
                }

            }
        })
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail" {
            let firstVC = self.presentingViewController as! TimelineViewController
            let previousVC = segue.destination as! TimelineViewController
            previousVC.getPostsBlockedData = self.selectedPost.objectId
//            self.present(firstVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func menu() {
        guard let currentUser = NCMBUser.current() else {
            //ログインに戻る
            let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
            let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
            let keyWindow = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive}).map({$0 as? UIWindowScene}).compactMap({$0}).first?.windows.filter({$0.isKeyWindow}).first
            keyWindow?.rootViewController = rootViewController
            
            //ログイン状態の保持
            let ud = UserDefaults.standard
            ud.set(false, forKey: "isLogin")
            ud.synchronize()
            return
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let likeAction = UIAlertAction(title: "お気に入り登録", style: .destructive) { (action) in
            let query = NCMBQuery(className: "Post")
            query?.getObjectInBackground(withId: self.selectedPost.objectId, block: { (post, error) in
                post?.addUniqueObject(currentUser.objectId, forKey: "likeUser")
                post?.saveEventually({ (error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error!.localizedDescription)
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "この投稿をお気に入り登録しました。")
                    }
                })
            })
        }
        
        let deleteLikeAction = UIAlertAction(title: "お気に入り登録を解除", style: .destructive) { (action) in
            let query = NCMBQuery(className: "Post")
            query?.getObjectInBackground(withId: self.selectedPost.objectId, block: { (post, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error!.localizedDescription)
                } else {
                    post?.removeObjects(in: [NCMBUser.current().objectId!], forKey: "likeUser")
                    post?.saveEventually({ (error) in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: error!.localizedDescription)
                        } else {
                            SVProgressHUD.showSuccess(withStatus: "この投稿をお気に入り登録から削除しました。")
                        }
                    })
                }
            })
        }
        
        let commentAction = UIAlertAction(title: "コメントを追加する", style: .destructive) { (action) in
            alertController.dismiss(animated: true, completion: nil)
            let alert = UIAlertController(title: "コメント", message: "コメントを入力して下さい", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "キャンセル", style: .default) { (action) in
                alert.dismiss(animated: true, completion: nil)
            }
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                alert.dismiss(animated: true, completion: nil)
                SVProgressHUD.show()
                let object = NCMBObject(className: "Comment")
                object?.setObject(self.selectedPost.objectId, forKey: "postId")
                object?.setObject(currentUser, forKey: "user")
                object?.setObject(alert.textFields?.first?.text, forKey: "text")
                object?.saveInBackground({ (error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error!.localizedDescription)
                    } else {
                        SVProgressHUD.dismiss()
                        self.loadComments()
                    }
                })
            }

            alert.addAction(cancelAction)
            alert.addAction(okAction)
            alert.addTextField { (textField) in
                textField.placeholder = "ここにコメントを入力"
            }
            self.present(alert, animated: true, completion: nil)
        }
        

        let blockAction = UIAlertAction(title: "この投稿を非表示", style: .destructive) { (action) in
            currentUser.addUniqueObject(self.selectedPost.objectId, forKey: "block")
            currentUser.saveEventually({ (error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error?.localizedDescription)
                    } else {
                        let blockAlert = UIAlertController(title: "完了", message: "この投稿を非表示にしました", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            blockAlert.dismiss(animated: true, completion: nil)
                            self.navigationController?.popViewController(animated: true)
                        }
                        blockAlert.addAction(okAction)
                        self.present(blockAlert, animated: true, completion: nil)
                    }
                })
            
            /*let query = NCMBQuery(className: "Post")
            query?.getObjectInBackground(withId: self.selectedPost.objectId, block: { (post, error) in
                post?.addUniqueObject(currentUser.objectId, forKey: "blockUser")
                post?.saveEventually({ (error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error!.localizedDescription)
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "この投稿を非表示にしました。")
                    }
                })
            })*/
            //let query = NCMBQuery(className: "Post")
            //UserDefaultで投稿のオブジェクトIDを取得。ログインしたときにこのオブジェクトIDを非表示にする
            
            
//            let nc = self.presentingViewController as! UINavigationController
//            let vc = nc.topViewController as! TimelineViewController

            //SVProgressHUD.showSuccess(withStatus: "この投稿を非表示にしました。")
            
//            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
//            let previousVC = storyboard.instantiateViewController(withIdentifier: "TimelineView") as! TimelineViewController
            
            //let newVC = self.navigationController?.viewControllers[0] as! TimelineViewController
//
//            var a = (self.presentingViewController as? TimelineViewController)?.getPostsBlockedData
            //newVC.getPostsBlockedData = self.selectedPost.objectId
            
            //self.navigationController?.popViewController(animated: true)
            //self.dismiss(animated: true, completion: nil)
        }
        
        let userBlockAction = UIAlertAction(title: "このユーザーの投稿をブロック", style: .destructive) { (action) in
            let alert = UIAlertController(title: "確認", message: "このユーザーの投稿を全てブロックしますか？", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                alert.dismiss(animated: true, completion: nil)
                currentUser.addUniqueObject(self.selectedPost.user.objectId, forKey: "blockUser")
                currentUser.saveEventually { (error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error?.localizedDescription)
                    } else {
                        let blockAlert = UIAlertController(title: "完了", message: "このユーザーを非表示にしました", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            blockAlert.dismiss(animated: true, completion: nil)
                            self.navigationController?.popViewController(animated: true)
                        }
                        blockAlert.addAction(okAction)
                        self.present(blockAlert, animated: true, completion: nil)
                    }
                }
            }
            let cancelAction = UIAlertAction(title: "キャンセル", style: .default) { (action) in
                alert.dismiss(animated: true, completion: nil)
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        
        let reportAction = UIAlertAction(title: "この投稿を報告する", style: .destructive) { (action) in
            let alert = UIAlertController(title: "報告", message: "この投稿を報告しますか？", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "キャンセル", style: .default) { (action) in
                alert.dismiss(animated: true, completion: nil)
            }
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                alert.dismiss(animated: true, completion: nil)
                SVProgressHUD.show()
                let reportObject = NCMBObject(className: "Report")
                reportObject?.setObject(self.selectedPost.user.objectId, forKey: "reportedUser")
                reportObject?.setObject(self.selectedPost.objectId, forKey: "reportedPostId")
                reportObject?.setObject(NCMBUser.current(), forKey: "user")
                reportObject?.saveInBackground({ (error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error?.localizedDescription)
                    } else {
                            currentUser.addUniqueObject(self.selectedPost.objectId, forKey: "block")
                            currentUser.saveEventually({ (error) in
                                if error != nil {
                                    SVProgressHUD.showError(withStatus: error?.localizedDescription)
                                }
                            })
                        
                        SVProgressHUD.dismiss()
                        let okAlert = UIAlertController(title: "報告完了！", message: "報告が完了しました。", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                            okAlert.dismiss(animated: true, completion: nil)
                        }
                        okAlert.addAction(okAction)
                        
                        self.present(okAlert, animated: true, completion: nil)
                    }
                })
            }

            alert.addAction(cancelAction)
            alert.addAction(okAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
        
        
        
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        if selectedPost.isLiked == false || selectedPost.isLiked == nil {
            alertController.addAction(likeAction)
        } else {
            alertController.addAction(deleteLikeAction)
        }
        
        
        
        
        alertController.addAction(commentAction)
        alertController.addAction(cancelAction)
        alertController.addAction(blockAction)
        alertController.addAction(reportAction)
        alertController.addAction(userBlockAction)
        alertController.popoverPresentationController?.sourceView = self.view
        
        let screenSize = UIScreen.main.bounds
        // ここで表示位置を調整
        // xは画面中央、yは画面下部になる様に指定
        alertController.popoverPresentationController?.sourceRect = CGRect(x: screenSize.size.width/2, y: screenSize.size.height, width: 0, height: 0)

        self.present(alertController, animated: true, completion: nil)
    }

}
