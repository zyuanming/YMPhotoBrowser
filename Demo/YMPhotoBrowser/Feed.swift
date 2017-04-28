//
//  Feed.swift
//  YMPhotoBrowser
//
//  Created by Zhang Yuanming on 4/28/17.
//  Copyright © 2017 None. All rights reserved.
//

import Foundation

class Feed {
    var info: String = ""
    var medias: [FeedMedia] = []
}



class FeedMedia {
    var thumbnail: String = ""
    var mediaUrl: String = ""
    var width: Float = 0
    var height: Float = 0
    var thumbWidth: Float = 0
    var thumbHeight: Float = 0
}
