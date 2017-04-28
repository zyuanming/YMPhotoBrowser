//
//  ViewController.swift
//  YMPhotoBrowser
//
//  Created by Zhang Yuanming on 4/27/17.
//  Copyright © 2017 None. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    fileprivate var datas: [Feed] = []
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FeedCell.self, forCellReuseIdentifier: "FeedCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 200

        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        datas = getFakeData()

        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FeedCell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedCell
        let feed = datas[indexPath.row]
        cell.setModel(feed)
        return cell
    }



    // MARK: - create Fake data

    fileprivate func getFakeData() -> [Feed] {
        let filePath = Bundle.main.path(forResource: "weibo", ofType: "json")
        let fileUrl = URL(fileURLWithPath: filePath!)
        var result: [Feed] = []
        if let data: Data = try? Data(contentsOf: fileUrl),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {

            if let jsonArray = json?["statuses"] as? [[String: Any]] {
                for jsonObject in jsonArray {
                    let feed = Feed()

                    let picIds = jsonObject["pic_ids"] as? [String] ?? []
                    let text = jsonObject["text"] as? String ?? ""
                    let picInfos = jsonObject["pic_infos"] as? [String: Any] ?? [:]
                    var mediaArray: [FeedMedia] = []
                    for picId in picIds {
                        if let picInfo = picInfos[picId] as? [String: Any],
                            let thumbnailInfo = picInfo["thumbnail"] as? [String: Any],
                            let large = picInfo["large"] as? [String: Any] {

                            let media = FeedMedia()
                            media.thumbnail = thumbnailInfo["url"] as? String ?? ""
                            media.thumbHeight = thumbnailInfo["height"] as? Float ?? 0
                            media.thumbWidth = thumbnailInfo["width"] as? Float ?? 0
                            media.mediaUrl = large["url"] as? String ?? ""
                            media.width = Float(large["width"] as? String ?? "0") ?? 0
                            media.height = Float(large["height"] as? String ?? "0") ?? 0

                            if media.width == 0 || media.height == 0 {
                                media.width = large["width"] as? Float ?? 0
                                media.height = large["height"] as? Float ?? 0
                            }

                            mediaArray.append(media)
                        }
                    }

                    feed.medias = mediaArray
                    feed.info = text
                    result.append(feed)

                }
            }
        }

        return result

    }
}









