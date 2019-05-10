//
//  CollectionViewCell.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {

    private(set) var textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            textLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10)])
    }
}
