//
//  HealthBar.swift
//  ARZombie
//
//  Created by Tri Dang on 12/10/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import Foundation
import SpriteKit

class HealthBar:SKNode {
    var bar:SKSpriteNode?
    var _progress:CGFloat = 0
    var progress:CGFloat {
        get {
            return _progress
        }
        set {
            let value = max(min(newValue, 1.0), 0.0)
            if let bar = bar {
                bar.xScale = value
                _progress = value
            }
            updateColor()
        }
    }
    
    convenience init(color: UIColor, size: CGSize) {
        self.init()
        bar = SKSpriteNode(color: color, size: size)
        if let bar = bar {
            bar.xScale = 0.0
            bar.zPosition = 3
//            bar.position = CGPoint(x: -size.width / 2, y:0)
            bar.anchorPoint = CGPoint(x: 0.0, y: 0.5)
            addChild(bar)
        }
    }
    
    func updateColor() {
        if _progress <= 0.6 && _progress >= 0.2 {
            bar?.color = .yellow
        } else if _progress < 0.2 {
            bar?.color = .red
        }
    }
}
