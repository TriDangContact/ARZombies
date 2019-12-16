//
//  BallNode.swift
//  ARZombie
//
//  Created by Tri Dang on 12/10/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import Foundation
import SceneKit

final class BallNode: SCNNode {
    override init() {
        super.init()
        
        let ball = SCNSphere(radius: 0.05)
        ball.firstMaterial?.diffuse.contents = UIImage(named: "ball.png")

        // create the node for the ball
        geometry = ball

        // set the position of the node
        position = position

        // configure physics of the node so that it can handle collision properly
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: ball, options: nil))
        physicsBody?.categoryBitMask = 3
        physicsBody?.contactTestBitMask = 1
        physicsBody?.isAffectedByGravity = false
        physicsBody?.damping = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
