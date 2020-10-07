//
//  MyPagePostsViewController.swift
//  Original
//
//  Created by 藤井　孝輔 on 2020/05/24.
//  Copyright © 2020 fujii_kosuke. All rights reserved.
//

import UIKit
import NCMB
class MyPagePostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var posts: [Post]!
    var number: Int?
    @IBOutlet var postsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        postsTableView.delegate = self
        postsTableView.dataSource = self
        postsTableView.tableFooterView = UIView()
        postsTableView.rowHeight = 185
        postsTableView.reloadData()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(posts.count)
        return posts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print(number)
        if number == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            let userNameLabel = cell.viewWithTag(1) as! UILabel
            let titleLabel = cell.viewWithTag(2) as! UILabel
            let authorLabel = cell.viewWithTag(3) as! UILabel
            let genreLabel = cell.viewWithTag(4) as! UILabel
            userNameLabel.text = "投稿者名：" + posts[indexPath.row].user.userName
            titleLabel.text = posts[indexPath.row].title
            authorLabel.text = "著者名：" + posts[indexPath.row].author
            genreLabel.text = "ジャンル：" + posts[indexPath.row].genre
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            let userNameLabel = cell.viewWithTag(1) as! UILabel
            let titleLabel = cell.viewWithTag(2) as! UILabel
            let authorLabel = cell.viewWithTag(3) as! UILabel
            let genreLabel = cell.viewWithTag(4) as! UILabel
            userNameLabel.text = "投稿者名：" + posts[indexPath.row].user.userName
            titleLabel.text = posts[indexPath.row].title
            authorLabel.text = "著者名：" + posts[indexPath.row].author
            genreLabel.text = "ジャンル：" + posts[indexPath.row].genre
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let selectedIndex = postsTableView.indexPathForSelectedRow!
            detailViewController.selectedPost = posts[selectedIndex.row]
        }
    }
}

