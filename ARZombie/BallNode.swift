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
        let ballNode = SCNNode(geometry: ball)

        // set the position of the node
        ballNode.position = SCNVector3(x: 0, y: 0.5, z: 0)

        // configure physics of the node so that it can handle collision properly
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ballNode.physicsBody?.categoryBitMask = 3
        ballNode.physicsBody?.contactTestBitMask = 1
        ballNode.physicsBody?.isAffectedByGravity = false
        ballNode.physicsBody?.damping = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
