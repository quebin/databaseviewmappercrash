//
//  HolderGenerationOperation.swift
//  DataMapperTester
//
//  Created by Kevin Elorza on 2019-05-10.
//  Copyright © 2019 Kevin Elorza. All rights reserved.
//

import UIKit

class HolderGenerationOperation: Operation {

    var holders: [Holder]
    private let limit: Int
    private let fill: Int

    init(topCap: Int, fill: Int) {
        self.limit = topCap
        self.fill = fill
        self.holders = []
        super.init()
    }

    override func main() {
        var holders = [Holder]()
        for _ in (0...limit) {
            let holder = Holder.init(identifier: String(Int.random(in: 0 ..< fill)), value: Int.random(in: 0 ..< fill))
            holders.append(holder)
        }
        self.holders = holders
    }

}
