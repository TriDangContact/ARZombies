//
//  GameView.swift
//  ARZombie
//
//  Created by Tri Dang on 12/10/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import Foundation
import SceneKit
import SpriteKit

class GameView: SCNView {
    override func awakeFromNib() {
         super.awakeFromNib()
        
        setup2DOverlay()
    }
    
    func setup2DOverlay() {
        let viewHeight = bounds.size.height
        let viewWidth = bounds.size.width
        
        let sceneSize = CGSize(width: viewWidth, height: viewHeight)
        
        // set overlay to be same size as our scene
        let skScene = SKScene(size: sceneSize)
        
        skScene.scaleMode = .resizeFill
        
        // create circle shape
        let dpadShape = SKShapeNode(circleOfRadius: 75)
        
        // configure how it looks where to place it
        dpadShape.strokeColor = .white
        dpadShape.lineWidth = 2.0
        dpadShape.position.x = dpadShape.frame.size.width / 2 + 10
        dpadShape.position.y = dpadShape.frame.size.height / 2 + 10
        
        skScene.addChild(dpadShape)
        skScene.isUserInteractionEnabled = false
        
        overlaySKScene = skScene
    }
}
