//
//  ViewController.swift
//  ARBowling
//
//  Created by Tri Dang on 12/9/19.
//  Copyright © 2019 Tri Dang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class GameViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {

    let colourArray: [UIColor] = [.red, .green, .yellow, .cyan, .white, .orange, .magenta, .purple]
    let randomObjectsGenerated = 1
    var currentScore = 0
    var currentHealth = 100
    var timer:Timer?
    var difficulty = 3.0
    var spawnDistance = 3
    var spawnSideDistance:Float = 15.0
    var spawnFrontDistance:Float = 3.0
    let threshold:Float = 1.0
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    // for tracking purposes
    var trackerNode: SCNNode?
    var foundSurface = false
    var isTracking = true
    
    var possiblePlane:SCNPlane?
    var directionalLightNode: SCNNode?
    var ambientLightNode: SCNNode?
    var container: SCNNode!
    var scoreNode: SCNNode?
    var healthNode: SCNNode?
    var backNode: SCNNode?
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/game.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.session.delegate = self
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        startSpawnTimer()
        feedbackGenerator.prepare()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        saveScore()
        // Pause the view's session
        sceneView.session.pause()
        stopSpawnTimer()
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // once our AR view has been loaded, we can remove the loading screen
        removeLoadingScreen()
        
        // do we need to find a surface?
        guard isTracking else {
            return
        }
        
        // make call on main thread
//        var hitTest:[ARHitTestResult]?
//        DispatchQueue.main.async {
            // detect in the middle of the screen
         let hitTest = self.sceneView.hitTest(CGPoint(x: self.view.frame.midX, y: self.view.frame.midY), types: .featurePoint)
//        }
        
        guard let result = hitTest.first else {
            return
        }
        
        // once we have a hit, we convert it to 3D position
        let translation =  SCNMatrix4(result.worldTransform)
        let position = SCNVector3Make(translation.m41, translation.m42, translation.m43)
        
        // if we don't have a tracker yet, we need to create one
        if trackerNode == nil {
            possiblePlane = SCNPlane(width: 0.5, height: 0.5)
            guard let plane = possiblePlane else {
                return
            }
            plane.firstMaterial?.diffuse.contents = UIImage(named: "tracker.png")
            plane.firstMaterial?.isDoubleSided = true
            
            // create the trackernode using the plane object we created
            trackerNode = SCNNode(geometry: plane)
            // make it lay flat
            trackerNode?.eulerAngles.x = -.pi * 0.5
            
            // add it to the scene
            self.sceneView.scene.rootNode.addChildNode(self.trackerNode!)
            
            foundSurface = true
        }
        self.trackerNode?.position = position
    }
    
    // we check to see if zombie reached player
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        print("DB Checking zombie")
        if currentHealth == 0 {
            print("DB: Game Over")
            exitGame()
        }
        
        let (_, position) = getCameraDirectionAndPosition()
        sceneView.scene.rootNode.childNodes
            .filter({ $0.name == "spawnedNode" })
            .forEach({
                let distance = findDistance(from: $0.position, to: position)
                if (distance < threshold) {
                    print("DB: ZOMBIE NEARBY")
                    feedbackGenerator.impactOccurred()
                    $0.removeFromParentNode()
                    decreaseHealth()
                }
            })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isTracking {
            //SETTING UP THE SCENE
            
            // have we already found the surface?
            guard foundSurface else {
                return
            }
            
            // get the position from the tracker and remove the tracker since we no longer need it
            let trackingPosition = trackerNode!.position
            trackerNode?.removeFromParentNode()
            
            // retrieve our container
            container = sceneView.scene.rootNode.childNode(withName: "container", recursively: false)
            
            // we can now show the game, after we have found a surface
            container.position = trackingPosition
            container.isHidden = false
            
            directionalLightNode = container.childNode(withName: "directionalLight", recursively: false)
            ambientLightNode = container.childNode(withName: "ambientLight", recursively: false)
            
            // setting up the labels and buttons
            scoreNode = container.childNode(withName: "scoreLabel", recursively: false)
            setScore(score: currentScore)
            healthNode = container.childNode(withName: "healthLabel", recursively: false)
            setHealth(health: currentHealth)

            
            backNode = container.childNode(withName: "backBtn", recursively: false)
            
            // allows us to handle collisions
            sceneView.scene.physicsWorld.contactDelegate = self
            
            // move to playing state
            isTracking = false
            
        } else {
            //PLAY STATE
            // start the spawning
            
            let touch = touches.first as! UITouch
            if(touch.view == self.sceneView) {
                let viewTouchLocation = touch.location(in: sceneView)
                guard let result = sceneView.hitTest(viewTouchLocation, options: nil).first else {
                        return
                    }
                if let backNode = backNode, backNode == result.node {
                    debugPrint("Back pressed")
                    exitGame()
                }
            }
            
            let (direction, position) = getCameraDirectionAndPosition()
            
            let ball = createBall(position: position)
            sceneView.scene.rootNode.addChildNode(ball)
            
            // telling the ball to wait for specified amount of time and remove itself from the scene
            ball.runAction(SCNAction.sequence([SCNAction.wait(duration: 5.0), SCNAction.removeFromParentNode()]))
            
            // actually shooting the ball
            ball.physicsBody?.applyForce(direction, asImpulse: true)
//            decreaseHealth()
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // we get both objects involved in the collision, add scores, and remove them
        let ball = contact.nodeA.physicsBody!.contactTestBitMask == 3 ? contact.nodeA : contact.nodeB
        
        // render an explosion when we have a collision
        let explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
        let explosionNode = SCNNode()
        explosionNode.position = ball.presentation.position
        sceneView.scene.rootNode.addChildNode(explosionNode)
        explosionNode.addParticleSystem(explosion)
        
        let object = contact.nodeA.physicsBody!.contactTestBitMask == 0 ? contact.nodeA : contact.nodeB
        incScore()
        ball.removeFromParentNode()
        object.removeFromParentNode()
    }
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        saveScore()
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let lightEstimate = frame.lightEstimate else {
            return
        }
        
        guard !isTracking else {
            return
        }
        
        directionalLightNode?.light?.intensity = lightEstimate.ambientIntensity
        ambientLightNode?.light?.intensity = lightEstimate.ambientIntensity * 0.5
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @objc func spawnRandomNodes(){
        let number = randomObjectsGenerated
        
        if !isTracking {
            
            // need to figure out where we started the game at so we can generated new objects based on the game's vertical (y) position
            guard let tracker = trackerNode else {
                return
            }
            let yPosition = tracker.position.y
            
            let scale = SCNVector3(0.25, 0.25, 0.25)
            
            // create x number of objects with different colors and position
            for _ in 0...number{
                let randomColor = Int.random(in:0..<colourArray.count)
                var randomDistanceX = Float.random(min: -(spawnSideDistance), max: spawnSideDistance)
                var randomDistanceZ = Float.random(min: -(spawnFrontDistance), max: spawnFrontDistance)
                
                // ensure that we spawn objects at a certain distance away from the player
                if randomDistanceX < 0 {
                    randomDistanceX = randomDistanceX - Float(spawnDistance)
                } else {
                    randomDistanceX = randomDistanceX + Float(spawnDistance)
                }
                
                if randomDistanceZ < 0 {
                    randomDistanceZ = randomDistanceZ - Float(spawnDistance)
                } else {
                    randomDistanceZ = randomDistanceZ + Float(spawnDistance)
                }
                
                let spawnedNode = SCNNode()
                let nodeGeometry = SCNCylinder(radius: 0.4, height: 2)
                
                // configure the shading model that we want to use
                nodeGeometry.firstMaterial?.lightingModel = SCNMaterial.LightingModel.physicallyBased
                nodeGeometry.firstMaterial?.diffuse.contents = colourArray[randomColor]
               
                // place it in the node
                spawnedNode.geometry = nodeGeometry
                spawnedNode.name = "spawnedNode"
                
                // configure the physics of the node for collision detection, using the same shape of the object we used
                spawnedNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: nodeGeometry, options:  [SCNPhysicsShape.Option.scale: scale]))
                spawnedNode.physicsBody?.categoryBitMask = 1
                spawnedNode.physicsBody?.contactTestBitMask = 0
                spawnedNode.physicsBody?.collisionBitMask = -1

                // specify random position where the node should be placed
                let randomVector =  SCNVector3(randomDistanceX, yPosition, randomDistanceZ)

                // set node's positon
                spawnedNode.position = randomVector
                spawnedNode.scale = scale
                
                moveNodeTowardsCamera(node: spawnedNode)
                
                // add to scene
                sceneView.scene.rootNode.addChildNode(spawnedNode)
            }
        }
    }
    
    func createBall(position: SCNVector3) -> SCNNode {
        // create the ball
        let ball = SCNSphere(radius: 0.05)
        ball.firstMaterial?.diffuse.contents = UIImage(named: "ball.png")

        // create the node for the ball
        let ballNode = SCNNode(geometry: ball)

        // set the position of the node
        ballNode.position = position

        // configure physics of the node so that it can handle collision properly
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ballNode.physicsBody?.categoryBitMask = 3
        ballNode.physicsBody?.contactTestBitMask = 1
        ballNode.physicsBody?.isAffectedByGravity = false
        ballNode.physicsBody?.damping = 0

        return ballNode
    }
    
    // need to implement Bresenham's line
    func moveNodeTowardsCamera(node: SCNNode) {
        // move the node towards the camera
        print("DB---------------------------------------")
        let (_, position) = getCameraDirectionAndPosition()
        print("Camera Position: \(position)")
        lookAt(node: node, target: position)
        let slope = findSlope(x1: node.position.x, y1: node.position.y, x2: position.x, y2: position.y)
        let distance = findDistance(from: node.position, to: position)
        let delta = slope / distance
        print("DB Start: \(node.position), End: \(position)")
        print("DB Slope: \(slope), Distance: \(distance), Delta: \(delta)")
        print("DB---------------------------------------")
        let moveAmount = SCNVector3(x: delta, y: 0.0, z: slope*delta)
        
        let move = SCNAction.move(by: moveAmount, duration: 1.0)
        let repeatForever = SCNAction.repeatForever(move)
        node.runAction(repeatForever)
    }
    
    func getCameraDirectionAndPosition() -> (SCNVector3,SCNVector3) {
        // get position and direction so the scene knows where to display the object
        var direction = SCNVector3Zero
        var position = SCNVector3Zero
        guard let frame = sceneView.session.currentFrame else {
            return (direction, position)
        }
        let camMatrix = SCNMatrix4(frame.camera.transform)
        direction = SCNVector3Make(-camMatrix.m31 * 5.0, -camMatrix.m32 * 10.0, -camMatrix.m33 * 5.0)
        position = SCNVector3Make(camMatrix.m41, camMatrix.m42, camMatrix.m43)
        return (direction, position)
    }
    
    func lookAt(node: SCNNode, target: SCNVector3) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.20
        node.look(at: target)
        SCNTransaction.commit()
    }
    
    func findSlope(x1:Float, y1:Float, x2:Float, y2:Float) -> Float {
        return (y2 - y1) / (x2 - x1)
    }
    
    func findDistance(from start:SCNVector3, to end:SCNVector3) -> Float{
        return sqrt(pow((start.x - end.x), 2) + pow((start.y - end.y), 2))
    }
    
    func removeLoadingScreen() {
        // make call on main thread
//        DispatchQueue.main.async {
        self.label1.isHidden = true
        self.label2.isHidden = true
        self.activityIndicator.isHidden = true
//        }
    }
    
    func exitGame() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "GameToMenu", sender: self)
        }
    }
    
    func incScore() {
        currentScore+=1
        setScore(score: currentScore)
    }
    
    func decreaseHealth() {
        currentHealth -= 1
        setHealth(health: currentHealth)
    }
    
    func setScore(score: Int) {
        if let parent = container.childNode(withName: "scoreLabel", recursively: false) {
            let scoreText = parent.geometry as! SCNText
            scoreText.string = "Score: \(score)"
        }
    }
    
    func setHealth(health: Int) {
        if let parent = container.childNode(withName: "healthLabel", recursively: false) {
            let healthText = parent.geometry as! SCNText
            healthText.string = "Health: \(health)"
        }
    }
    
    func saveScore() {
        UserDefaults.standard.set(currentScore, forKey: "highscore")
    }
    
    func startSpawnTimer() {
        timer = Timer.scheduledTimer(timeInterval: difficulty, target: self, selector: #selector(spawnRandomNodes), userInfo: nil, repeats: true)
    }
    
    func stopSpawnTimer() {
        timer?.invalidate()
    }
}


public extension Float {
    static var random:Float {
        get {
            return Float(arc4random()) / 0xFFFFFFFF
        }
    }
    static func random(min: Float, max: Float) -> Float {
        return Float.random * (max - min) + min
    }
}
