//
//  GameScoreOverlay.swift
//  ARZombie
//
//  Created by Tri Dang on 12/15/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import Foundation
import SpriteKit

class GameScoreOverlay: SKScene {
    var rootNode = SKNode()
    
    override init(size: CGSize) {
        super.init(size: size)
    
        scaleMode = .resizeFill
        
        rootNode = SKNode()
        addChild(rootNode)
    }
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func displayScore(score: Int) {
        // SCORE
        let score = SKLabelNode(text: "+ \(score)")
        score.horizontalAlignmentMode = .center
        score.verticalAlignmentMode = .center
        score.position = CGPoint(x: 0.0, y: 0.0)
        score.fontColor = .yellow
        score.fontName = "AmericanTypewriter-Bold"
        score.fontSize = 30
        score.zPosition = 2
        rootNode.addChild(score)
    }
}
