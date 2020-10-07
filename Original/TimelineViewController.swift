//
//  TimelineViewController.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/09.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit
import NCMB
import SVProgressHUD

class TimelineViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate {
    
    var posts = [Post]()
    var searchBar: UISearchBar!
    var array:[String] = []
    var arrayUser:[String] = []
    var getPostsBlockedData:String?
    @IBOutlet var timelineTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSearchBar()
        
        navigationController?.delegate = self
        
        timelineTableView.dataSource = self
        timelineTableView.delegate = self
        timelineTableView.tableFooterView = UIView()
        timelineTableView.rowHeight = 185

        /*//ログアウト成功した場合
        let storyboard = UIStoryboard(name: "SignIn", bundle: Bundle.main)
        let rootViewController = storyboard.instantiateViewController(withIdentifier: "RootNavigationController")
        UIApplication.shared.keyWindow?.rootViewController = rootViewController
        //ログアウト状態の保持
        let ud = UserDefaults.standard
        ud.set(false, forKey: "isLogin")
        ud.synchronize()*/
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadTimeline(searchText: nil)
    }
    
    func setSearchBar() {
        // NavigationBarにSearchBarをセット
        if let navigationBarFrame = self.navigationController?.navigationBar.bounds {
            let searchBar: UISearchBar = UISearchBar(frame: navigationBarFrame)
            searchBar.delegate = self
            searchBar.placeholder = "タイトル、著者名で検索"
            searchBar.autocapitalizationType = UITextAutocapitalizationType.none
            navigationItem.titleView = searchBar
            navigationItem.titleView?.frame = searchBar.frame
            self.searchBar = searchBar
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        loadTimeline(searchText: nil)
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        loadTimeline(searchText: searchBar.text)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        let userNameLabel = cell.viewWithTag(1) as! UILabel
        let titleLabel = cell.viewWithTag(2) as! UILabel
        let authorLabel = cell.viewWithTag(3) as! UILabel
        let genreLabel = cell.viewWithTag(4) as! UILabel
        
        let post = posts[indexPath.row]
        userNameLabel.text = "投稿者名：" + posts[indexPath.row].user.userName
        titleLabel.text = post.title
        authorLabel.text = "著者名：" + post.author
        genreLabel.text = "ジャンル：" + post.genre
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedIndex = timelineTableView.indexPathForSelectedRow!
        let query = NCMBQuery(className: "History")
        query?.includeKey("user")
        query?.includeKey("post")
        query?.whereKey("user", equalTo: NCMBUser.current())
        query?.whereKey("postId", equalTo: posts[selectedIndex.row].objectId)
        query?.countObjectsInBackground({ (count, error) in
            if count >= 1 {
                query?.findObjectsInBackground({ (result, error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error?.localizedDescription)
                    } else {
                        let history = result as! [NCMBObject]
                        for objects in history {
                            objects.deleteInBackground { (error) in
                                if error != nil {
                                    SVProgressHUD.showError(withStatus: error?.localizedDescription)
                                }
                            }
                        }
                    }
                })
            }
        })
        let query2 = NCMBQuery(className: "History")
        query2?.includeKey("user")
        query2?.whereKey("user", equalTo: NCMBUser.current())
        query2?.countObjectsInBackground({ (count2, error) in
            if count2 == 5 {
                query2?.findObjectsInBackground({ (result, error) in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: error?.localizedDescription)
                    } else {
                        let objects = result as! [NCMBObject]
                        let delete = objects.last
                        delete?.deleteInBackground({ (error) in
                            if error != nil {
                                SVProgressHUD.showError(withStatus: error?.localizedDescription)
                            }
                        })
                    }
                })
            }
        })
        
        if NCMBUser.current() == nil {
            performSegue(withIdentifier: "toDetail", sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            let historyQuery = NCMBQuery(className: "Post")
            historyQuery?.whereKey("objectId", equalTo: posts[selectedIndex.row].objectId)
            historyQuery?.getFirstObjectInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error?.localizedDescription)
                } else {
                    let historyObject = NCMBObject(className: "History")
                    historyObject?.setObject(NCMBUser.current(), forKey: "user")
                    historyObject?.setObject(self.posts[selectedIndex.row].objectId, forKey: "postId")
                    historyObject?.setObject(result, forKey: "post")
                    historyObject?.saveInBackground({ (error) in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: error?.localizedDescription)
                        } else {
                            self.performSegue(withIdentifier: "toDetail", sender: nil)
                            tableView.deselectRow(at: indexPath, animated: true)
                        }
                    })

                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let selectedIndex = timelineTableView.indexPathForSelectedRow!
            detailViewController.selectedPost = posts[selectedIndex.row]
        }
    }
    
    func loadTimeline(searchText: String?) {
        if let text = searchText {
            let query1 = NCMBQuery(className: "Post")
            query1?.whereKey("title", equalTo: text)
            
            let query2 = NCMBQuery(className: "Post")
            query2?.whereKey("author", equalTo: text)
            let query = NCMBQuery.orQuery(withSubqueries: [query1!, query2!])
            query?.includeKey("user")
            query?.limit = 20
            query?.order(byDescending: "createDate")
            
            if let currentUser = NCMBUser.current() {
                if currentUser.object(forKey: "block") != nil {
                    array = currentUser.object(forKey: "block") as! [String]
                    }
                if currentUser.object(forKey: "blockUser") != nil {
                    arrayUser = currentUser.object(forKey: "blockUser") as! [String]
                }
            }
            if array != [] {
                query?.whereKey("objectId", notContainedIn: array)
            }
            if arrayUser != [] {
                query?.whereKey("userId", notContainedIn: arrayUser)
            }
            
            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error?.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        let user = postObject.object(forKey: "user") as! NCMBUser
                        let userModel = User(objectId: user.objectId, userName: user.userName)
                        let title = postObject.object(forKey: "title") as! String
                        let author = postObject.object(forKey: "author") as! String
                        let genre = postObject.object(forKey: "genre") as! String
                        let text = postObject.object(forKey: "text") as! String
                        let post = Post(objectId: postObject.objectId, user: userModel, title: title, author: author, genre: genre, createDate: postObject.createDate, text: text)
                        
                        let likeUsers = postObject.object(forKey: "likeUser") as? [String]
                        if NCMBUser.current() != nil {
                            if likeUsers?.contains(NCMBUser.current().objectId) == true {
                                post.isLiked = true
                            } else {
                                post.isLiked = false
                            }
                        }
                        
                        if let publish = postObject.object(forKey: "publisher") {
                            post.publisher = publish as? String
                        }
                        if let date = postObject.object(forKey: "date") {
                            post.date = date as? String
                        }
                        self.posts.append(post)
                        self.timelineTableView.reloadData()
                    }
                }
            })
        } else {
            let query = NCMBQuery(className: "Post")
            query?.includeKey("user")
            query?.limit = 20
            query?.order(byDescending: "createDate")
            
            if let currentUser = NCMBUser.current() {
                if currentUser.object(forKey: "block") != nil {
                    array = currentUser.object(forKey: "block") as! [String]
                    }
                if currentUser.object(forKey: "blockUser") != nil {
                    arrayUser = currentUser.object(forKey: "blockUser") as! [String]
                }
            }
            if array != [] {
                query?.whereKey("objectId", notContainedIn: array)
            }
            
            if arrayUser != [] {
                query?.whereKey("userId", notContainedIn: arrayUser)
            }
            
            
//~~~非表示にした投稿
            /*if let objValue = getPostsBlockedData{
                if array.contains(objValue){
                    print("重複あるっぽい")
                }else{
                    array.append(objValue)
                    UserDefaults.standard.set(array, forKey: "arrayObjId")
                }
            }
            
            let arrayObjId = UserDefaults.standard.array(forKey: "arrayObjId") as? [String]
        
            if arrayObjId != [] && arrayObjId != nil{
                query?.whereKey("objectId", notContainedIn: arrayObjId)
            }else{
                print(arrayObjId)
            }*/
            

            query?.findObjectsInBackground({ (result, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: error?.localizedDescription)
                } else {
                    self.posts = [Post]()
                    for postObject in result as! [NCMBObject] {
                        let user = postObject.object(forKey: "user") as! NCMBUser
                        let userModel = User(objectId: user.objectId, userName: user.userName)
                        let title = postObject.object(forKey: "title") as! String
                        let author = postObject.object(forKey: "author") as! String
                        let genre = postObject.object(forKey: "genre") as! String
                        let text = postObject.object(forKey: "text") as! String
                        let post = Post(objectId: postObject.objectId, user: userModel, title: title, author: author, genre: genre, createDate: postObject.createDate, text: text)
                        
                        let likeUsers = postObject.object(forKey: "likeUser") as? [String]
                        if NCMBUser.current() != nil {
                            if likeUsers?.contains(NCMBUser.current().objectId) == true {
                                post.isLiked = true
                            } else {
                                post.isLiked = false
                            }
                        }
                        
                        
                        if let publish = postObject.object(forKey: "publisher") {
                            post.publisher = publish as? String
                        }
                        if let date = postObject.object(forKey: "date") {
                            post.date = date as? String
                        }
                        self.posts.append(post)
                        self.timelineTableView.reloadData()
                    }
                }
            })
        }
        
    }

}
