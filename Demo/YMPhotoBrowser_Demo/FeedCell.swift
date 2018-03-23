//
//  FeedCell.swift
//  YMPhotoBrowser
//
//  Created by Zhang Yuanming on 4/28/17.
//  Copyright © 2017 None. All rights reserved.
//

import UIKit

class FeedCell: UITableViewCell {

    fileprivate lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    fileprivate lazy var imageViewContainer: ImageContainerView = {
        let container = ImageContainerView()

        return container
    }()
    lazy var lineView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.black
        return view
    }()
    fileprivate var feedModel: Feed?


    // MARK: - LifeCycle

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        initialize()
    }

    fileprivate func initialize() {

        contentView.addSubview(infoLabel)
        contentView.addSubview(imageViewContainer)
        contentView.addSubview(lineView)

        infoLabel.snp.makeConstraints { (make) in
            make.leftMargin.equalToSuperview()
            make.rightMargin.equalToSuperview()
            make.topMargin.equalToSuperview()
        }

        imageViewContainer.snp.makeConstraints { (maker) in
            maker.top.equalTo(self.infoLabel.snp.bottom).offset(17.0)
            maker.left.equalToSuperview().offset(10)
            maker.right.equalToSuperview().offset(-10.0)
        }

        lineView.snp.makeConstraints { (make) in
            make.top.equalTo(imageViewContainer.snp.bottom).offset(10)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalToSuperview()
        }

    }


    //MARK: - UI updates

    func setModel(_ model: Feed) {
        feedModel = model
        infoLabel.text = model.info
        imageViewContainer.displayImages(feed: model)
    }


}
