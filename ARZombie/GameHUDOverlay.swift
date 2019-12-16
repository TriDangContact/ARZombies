//
//  GameHUDOverlay.swift
//  ARZombie
//
//  Created by Tri Dang on 12/11/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import Foundation
import SpriteKit

class GameHUDOverlay: SKScene {
    // need this pointer to the viewController so we can perform segue
    var viewController: UIViewController?
    var rootNode = SKNode()
    var healthbar = HealthBar()
    var background = SKShapeNode()
    var hpLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var healthContainer = SKShapeNode()
    var scoreContainer = SKNode()
    var zombiesLabel = SKLabelNode()
    var zombiesCount:Int = 0 {
        didSet {
            updateZombieLabel()
        }
    }
    var score:Int = 0 {
        didSet {
            updateScoreLabel()
        }
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    
        scaleMode = .resizeFill
        
        rootNode = SKNode()
        addChild(rootNode)
        
        let healthShapeHeight:CGFloat = 20.0
        let actualSize = CGSize(width: size.width / 2, height: healthShapeHeight)
        
        healthbar = HealthBar(color: .green, size: actualSize)
            healthbar.position.x = 10 + healthbar.frame.width/2
            healthbar.position.y = size.height - healthbar .frame.size.height - 40
        
        healthbar.progress = 1.0
        rootNode.addChild(healthbar)
        
        var position = CGPoint(x: 105, y: healthbar.position.y)
        if let bar = healthbar.bar {
            position = CGPoint(x: healthbar.position.x + (bar.frame.size.width/2), y: healthbar.position.y)
        }
        
        background = SKShapeNode(rectOf: actualSize, cornerRadius: 5)
        background.position = position
        background.zPosition = 2
        background.strokeColor = .black
        background.fillColor = .gray
        rootNode.addChild(background)
        
        healthContainer = SKShapeNode(rectOf: actualSize, cornerRadius: 5)
        healthContainer.position = position
        healthContainer.zPosition = 4
        healthContainer.strokeColor = .lightGray
        healthContainer.lineWidth = 5
        rootNode.addChild(healthContainer)
        
        hpLabel = SKLabelNode(text: "HP")
        hpLabel.horizontalAlignmentMode = .center
        hpLabel.verticalAlignmentMode = .center
        hpLabel.position = position
        hpLabel.fontColor = .orange
        hpLabel.fontName = "AmericanTypewriter-Bold"
        hpLabel.fontSize = 12
        hpLabel.zPosition = 3
        rootNode.addChild(hpLabel)
        
        zombiesLabel = SKLabelNode(text: "Zombies Left: \(zombiesCount)")
        zombiesLabel.horizontalAlignmentMode = .right
        zombiesLabel.verticalAlignmentMode = .center
        zombiesLabel.position = CGPoint(x: position.x, y: position.y - zombiesLabel.frame.height)
        zombiesLabel.fontColor = .orange
        zombiesLabel.fontName = "AmericanTypewriter-Bold"
        zombiesLabel.fontSize = 12
        zombiesLabel.zPosition = 3
        rootNode.addChild(zombiesLabel)
        
        scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: position.x, y: position.y - zombiesLabel.frame.height - scoreLabel.frame.height)
        scoreLabel.fontColor = .orange
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 12
        scoreLabel.zPosition = 3
        rootNode.addChild(scoreLabel)
        
        scoreContainer = SKNode()
        scoreContainer.position = CGPoint(x: size.width/2, y: size.height/2)
        rootNode.addChild(scoreContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {

            let location = touch.location(in: self)
//            if pauseButton.contains(location) {
//                print("DB: Healthbar buttonTouch Began")
//                let view = viewController as! GameViewController
//            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {

            let location = touch.location(in: self)

            if healthbar.contains(location) {
                print("DB: Healthbar buttonTouch Ended")
            }
        }
    }
    
    func updateZombieLabel() {
        zombiesLabel.text = "Zombies Left: \(zombiesCount)"
    }
    
    func updateScoreLabel() {
        scoreLabel.text = "Score: \(score)"
    }
    
    func incScore(score: Int) {
        self.score += score
        let scoreNode = SKLabelNode(text: "+ \(score)")
        scoreNode.horizontalAlignmentMode = .center
        scoreNode.verticalAlignmentMode = .center
        scoreNode.position = CGPoint(x: 0.0, y: 0.0)
        scoreNode.fontColor = .yellow
        scoreNode.fontName = "AmericanTypewriter-Bold"
        scoreNode.fontSize = 30
        scoreNode.zPosition = 2
        
        // animation
        let fade = SKAction.fadeAlpha(to: 0, duration: 4)
        let move = SKAction.moveBy(x: CGFloat(80.0), y: CGFloat(80.0), duration: 4.0)
        scoreNode.run(fade)
        scoreNode.run(move)
        
        // cleanup
        let wait = SKAction.wait(forDuration: 4)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([wait,remove])
        scoreNode.run(sequence)
        scoreContainer.addChild(scoreNode)
    }
    
    func decHealth(health: Int) {
        let healthNode = SKLabelNode(text: "- \(health)")
        healthNode.horizontalAlignmentMode = .center
        healthNode.verticalAlignmentMode = .center
        healthNode.position = CGPoint(x: 0.0, y: 0.0)
        healthNode.fontColor = .red
        healthNode.fontName = "AmericanTypewriter-Bold"
        healthNode.fontSize = 30
        healthNode.zPosition = 2
        
        // animation
        let fade = SKAction.fadeAlpha(to: 0, duration: 4)
        let move = SKAction.moveBy(x: CGFloat(80.0), y: CGFloat(-80.0), duration: 4.0)
        healthNode.run(fade)
        healthNode.run(move)
        
        // cleanup
        let wait = SKAction.wait(forDuration: 4)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([wait,remove])
        healthNode.run(sequence)
        scoreContainer.addChild(healthNode)
    }
}
