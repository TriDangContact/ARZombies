//
//  GameOverOverlay.swift
//  ARZombie
//
//  Created by Tri Dang on 12/11/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverOverlay: SKScene {
    // need this pointer to the viewController so we can perform segue 
    var viewController: UIViewController?
    var rootNode = SKNode()
    var background = SKShapeNode()
    var label:SKLabelNode = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var score = SKLabelNode()
    var backBtnNode = SKShapeNode()
    var backLabel = SKLabelNode()
    var replayBtnNode = SKShapeNode()
    var replayLabel = SKLabelNode()
    
    override init(size: CGSize) {
        super.init(size: size)
    
        scaleMode = .resizeFill
        
        rootNode = SKNode()
        addChild(rootNode)
        
        // BACKGROUND
        let position = CGPoint(x: size.width/2, y: size.height/2)
        background = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height), cornerRadius: 0.0)
        background.position = position
        background.zPosition = 1
        background.fillColor = .gray
        rootNode.addChild(background)
        
        // GAME OVER LABEL
        label = SKLabelNode(text: "Game Over")
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = position
        label.fontColor = .white
        label.fontName = "AmericanTypewriter-Bold"
        label.fontSize = 50
        label.zPosition = 2
        rootNode.addChild(label)
        
        // SCORE LABEL
        scoreLabel = SKLabelNode(text: "Score:")
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: position.x, y: position.y - label.frame.height - 10)
        scoreLabel.fontColor = .white
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 30
        scoreLabel.zPosition = 2
        rootNode.addChild(scoreLabel)
        
        // SCORE
        score = SKLabelNode(text: "0")
        score.horizontalAlignmentMode = .center
        score.verticalAlignmentMode = .center
        score.position = CGPoint(x: position.x, y: scoreLabel.position.y - scoreLabel.frame.height - 10)
        score.fontColor = .white
        score.fontName = "AmericanTypewriter-Bold"
        score.fontSize = 30
        score.zPosition = 2
        rootNode.addChild(score)
        
//        // BACK BUTTON
        backBtnNode = SKShapeNode(rectOf: CGSize(width: size.width/3, height: size.width/6), cornerRadius: 10)
        backBtnNode.name = "backBtnSKNode"
        backBtnNode.position = CGPoint(x: position.x/2, y: position.y/3)
        backBtnNode.zPosition = 2
        backBtnNode.fillColor = .orange
        rootNode.addChild(backBtnNode)

        backLabel = SKLabelNode(text: "Back")
        backLabel.horizontalAlignmentMode = .center
        backLabel.verticalAlignmentMode = .center
        backLabel.position = backBtnNode.position
        backLabel.fontColor = .white
        backLabel.fontName = "AmericanTypewriter-Bold"
        backLabel.fontSize = 30
        backLabel.zPosition = 3
        rootNode.addChild(backLabel)


        // REPLAY BUTTON
        replayBtnNode = SKShapeNode(rectOf: CGSize(width: size.width/3, height: size.width/6), cornerRadius: 10)
        replayBtnNode.name = "backBtnSKNode"
        replayBtnNode.position = CGPoint(x: position.x*1.5, y: position.y/3)
        replayBtnNode.zPosition = 2
        replayBtnNode.fillColor = .orange
        rootNode.addChild(replayBtnNode)

        // disabled until I can figure out how to reset the GameViewController
//        replayLabel = SKLabelNode(text: "Replay")
//        replayLabel.horizontalAlignmentMode = .center
//        replayLabel.verticalAlignmentMode = .center
//        replayLabel.position = replayBtnNode.position
//        replayLabel.fontColor = .white
//        replayLabel.fontName = "AmericanTypewriter-Bold"
//        replayLabel.fontSize = 30
//        replayLabel.zPosition = 3
//        rootNode.addChild(replayLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {

            let location = touch.location(in: self)
            if backBtnNode.contains(location) {
                print("DB: Back buttonTouch Began")
                let view = viewController as! GameViewController
                view.exitGame()
            }
            if replayBtnNode.contains(location) {
                print("DB: Replay buttonTouch Began")
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {

            let location = touch.location(in: self)

            if backBtnNode.contains(location) {
                print("DB: Back buttonTouch Ended")
            }
            if replayBtnNode.contains(location) {
                print("DB: Replay buttonTouch Ended")
            }
        }
    }
}
