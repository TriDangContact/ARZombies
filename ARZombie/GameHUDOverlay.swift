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
    var label = SKLabelNode()
    var healthContainer = SKShapeNode()
    var zombiesLabel = SKLabelNode()
    var zombiesCount:Int = 0 {
        didSet {
            updateZombieLabel()
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
        
        label = SKLabelNode(text: "HP")
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = position
        label.fontColor = .orange
        label.fontName = "AmericanTypewriter-Bold"
        label.fontSize = 12
        label.zPosition = 3
        rootNode.addChild(label)
        
        label = SKLabelNode(text: "HP")
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = position
        label.fontColor = .orange
        label.fontName = "AmericanTypewriter-Bold"
        label.fontSize = 12
        label.zPosition = 3
        rootNode.addChild(label)
        
        zombiesLabel = SKLabelNode(text: "Zombies Left: \(zombiesCount)")
        zombiesLabel.horizontalAlignmentMode = .center
        zombiesLabel.verticalAlignmentMode = .center
        zombiesLabel.position = CGPoint(x: position.x, y: position.y - zombiesLabel.frame.height)
        zombiesLabel.fontColor = .orange
        zombiesLabel.fontName = "AmericanTypewriter-Bold"
        zombiesLabel.fontSize = 12
        zombiesLabel.zPosition = 3
        rootNode.addChild(zombiesLabel)
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
}
