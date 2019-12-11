//
//  SpawnedSCNNode.swift
//  ARZombie
//
//  Created by Tri Dang on 12/11/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import Foundation
import SceneKit

class SpawnedSCNNode: SCNNode {
    override init() {
        super.init()
        let colourArray: [UIColor] = [.red, .green, .yellow, .cyan, .white, .orange, .magenta, .purple]
        let randomColor = Int.random(in:0..<colourArray.count)
        let nodeGeometry = SCNCylinder(radius: 0.4, height: 2)
        // configure the shading model that we want to use
        nodeGeometry.firstMaterial?.lightingModel = SCNMaterial.LightingModel.physicallyBased
        nodeGeometry.firstMaterial?.diffuse.contents = colourArray[randomColor]
         
        // place it in the node
        geometry = nodeGeometry
        // configure the physics of the node for collision detection, using the same shape of the object we used
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: nodeGeometry, options:  [SCNPhysicsShape.Option.scale: scale]))
        physicsBody?.categoryBitMask = 1
        physicsBody?.contactTestBitMask = 0
        physicsBody?.collisionBitMask = -1
        
        name = "spawnedNode"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
