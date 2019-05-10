//
//  CollectionSectionHeaderView.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import UIKit

class CollectionSectionHeaderView: UICollectionReusableView {

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
        backgroundColor = .lightGray
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10)])
    }
        
}
