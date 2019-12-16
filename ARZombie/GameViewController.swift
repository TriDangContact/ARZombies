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
import ModelIO
import SceneKit.ModelIO

class GameViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SCNPhysicsContactDelegate {

    let colourArray: [UIColor] = [.red, .green, .yellow, .cyan, .white, .orange, .magenta, .purple]
    let randomObjectsGenerated = 1
    var currentScore = 0
    var currentHealth = 100
    var timer:Timer?
    var isGameOver = false
    
    // difficulty settings
    var spawnTimerDifficultyDivider = 3.0   // harder = lower
    var scoreDifficultyMultiplier = 1   // harder = higher
    var healthDifficultyMultiplier = 1  // harder = higher
    var spawnDistanceDifficultyDivider = 3  // harder = lower
    var spawnSideDistance:Float = 15.0   // harder = higher
    var spawnFrontDistance:Float = 3.0  // harder = lower
    let hitboxThresholdDifficulty:Float = 1.0 // harder = lower
    let spawnedMovementDifficultyDivider:Float = 10000.0    // harder = lower, movement amount is extremely tiny, need to divide by amount to make difference noticeable
    
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
    var backBtnNode: SKShapeNode = SKShapeNode()
    var replayBtnNode: SKShapeNode = SKShapeNode()
    var healthbar = HealthBar()
    var gameHUDOverlay:GameHUDOverlay?
    
    @IBOutlet weak var howToPlayInstruction: UIImageView!
    @IBOutlet weak var tapToShootInstruction: UIImageView!
    @IBOutlet weak var pauseBtn: UIButton!
    @IBOutlet weak var loadingScreenLabel: UILabel!
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
    
    
    
    // -------- SCENE LIFE CYCLE --------------

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        // once our AR view has been loaded, we can remove the loading screen and display instructions
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
            displayHowToPlayInstructions()
            
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
//            let (_, position) = getCameraDirectionAndPosition()
//            lookAt(node: trackerNode!, target: position)
            
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
            gameOver()
        }
        
        let (_, position) = getCameraDirectionAndPosition()
        let spawned = sceneView.scene.rootNode.childNodes
            .filter({ $0.name == "spawnedNode" })
        gameHUDOverlay?.zombiesCount = spawned.count
        spawned.forEach({
            let distance = findDistance(from: $0.position, to: position)
            if (distance < hitboxThresholdDifficulty) {
                print("DB: ZOMBIE NEARBY")
                feedbackGenerator.impactOccurred()
                decHealth()
                decZombiesCount()
                $0.removeFromParentNode()
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
            
            hideHowToPlayInstructions()
            displayTapToShootInstructions()
            
            // get the position from the tracker and remove the tracker since we no longer need it
            let trackingPosition = trackerNode!.position
            trackerNode?.removeFromParentNode()
            
            // retrieve our container
            container = sceneView.scene.rootNode.childNode(withName: "container", recursively: false)
            
            // we can now show the game, after we have found a surface
            container.position = trackingPosition
            container.isHidden = false
            pauseBtn.isHidden = false
            sceneView.overlaySKScene = getGameHUDOverlay()
            // MARK: convenient place to test overlays
//            gameOver()
            
            // INITIALIZING ALL THE NODES IN THE SCENE
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
            hideTapToShootInstructions()
            shootBall()
            
            // handling touch for nodes inside of the ARScene
            let touch = touches.first as! UITouch
            if(touch.view == self.sceneView) {
                let viewTouchLocation = touch.location(in: sceneView)
                guard let result = sceneView.hitTest(viewTouchLocation, options: nil).first else {
                        return
                    }
                if let backNode = backNode, backNode == result.node {
                    gameOver()
                }
            }
        }
    }
    
    // Object Collision handling
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
        decZombiesCount()
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
    
    // -------- END SCENE LIFE CYCLE ---------
    
    
    // ------- START OVERLAYS METHODS ---------
    func getGameHUDOverlay() -> SKScene {
        let viewHeight = sceneView.bounds.size.height
        let viewWidth = sceneView.bounds.size.width
        gameHUDOverlay = GameHUDOverlay(size: CGSize(width: viewWidth, height: viewHeight))
        healthbar = gameHUDOverlay!.healthbar
        
        gameHUDOverlay!.isUserInteractionEnabled = false
        gameHUDOverlay!.viewController = self
        return gameHUDOverlay!
    }
    
    func getGamePausedOverlay() -> SKScene {
        let viewHeight = sceneView.bounds.size.height
        let viewWidth = sceneView.bounds.size.width
        let overlay = GamePausedOverlay(size: CGSize(width: viewWidth, height: viewHeight))
        
        overlay.score.text = "\(currentScore)"
        overlay.isUserInteractionEnabled = true
        overlay.viewController = self
        return overlay
    }
    
    func getGameOverOverlay() -> SKScene {
        let viewHeight = sceneView.bounds.size.height
        let viewWidth = sceneView.bounds.size.width
        let overlay = GameOverOverlay(size: CGSize(width: viewWidth, height: viewHeight))
        
        overlay.score.text = "\(currentScore)"
        overlay.isUserInteractionEnabled = true
        overlay.viewController = self
        return overlay
    }
    // ------- END OVERLAYS METHODS ---------
    
    
    // ------- START GAME BUILDING ---------
    func shootBall() {
        let (direction, position) = getCameraDirectionAndPosition()
                    
        let ball = BallNode()
        ball.position = position
        sceneView.scene.rootNode.addChildNode(ball)
        
        // telling the ball to wait for specified amount of time and remove itself from the scene
        ball.runAction(SCNAction.sequence([SCNAction.wait(duration: 5.0), SCNAction.removeFromParentNode()]))
        
        // actually shooting the ball
        ball.physicsBody?.applyForce(direction, asImpulse: true)
    }
    
    @objc func spawnRandomNodes(){
        let number = randomObjectsGenerated
        
        if !isTracking {
            
            // need to figure out where we started the game at so we can generated new objects based on the game's vertical (y) position
            guard let tracker = trackerNode else {
                return
            }
            let yPosition = tracker.position.y
            
            var scale = SCNVector3(0.25, 0.25, 0.25)
            
            // create x number of objects with different colors and position
            for _ in 0...number{
                let randomColor = Int.random(in:0..<colourArray.count)
                var randomDistanceX = Float.random(min: -(spawnSideDistance), max: spawnSideDistance)
                var randomDistanceZ = Float.random(min: -(spawnFrontDistance), max: spawnFrontDistance)
                
                // ensure that we spawn objects at a certain distance away from the player
                if randomDistanceX < 0 {
                    randomDistanceX = randomDistanceX - Float(spawnDistanceDifficultyDivider)
                } else {
                    randomDistanceX = randomDistanceX + Float(spawnDistanceDifficultyDivider)
                }
                
                if randomDistanceZ < 0 {
                    randomDistanceZ = randomDistanceZ - Float(spawnDistanceDifficultyDivider)
                } else {
                    randomDistanceZ = randomDistanceZ + Float(spawnDistanceDifficultyDivider)
                }
                
                // specify random position where the node should be placed
                let randomVector =  SCNVector3(randomDistanceX, yPosition, randomDistanceZ)
                
                // spawn a node
                let spawnedNode = SpawnedSCNNode()
                
                // MARK: testing spawning of zombie 3D model
//                scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
//                let spawnedNode = createZombie(scale: scale)

//                // set node's positon
                spawnedNode.position = randomVector
                spawnedNode.scale = scale
                
                moveNodeTowardsPlayer(node: spawnedNode)
                
                let (_, position) = getCameraDirectionAndPosition()
                lookAt(node: spawnedNode, target: position)
                
                // add to scene
                sceneView.scene.rootNode.addChildNode(spawnedNode)
                incZombiesCount()
            }
        }
    }
    
    // MARK: IN PROGRESS
    // MARK: BUG: texture not showing up, model not facing player, model not moving towards player
    func createZombie(scale: SCNVector3) -> SCNNode{
//         load our 3D object
//        let scene = SCNScene(named: "art.scnassets/steve.dae")!
        guard let steve = container.childNode(withName: "steve", recursively: false) else {
            print("DB: unable to load zombie")
            return SCNNode()
        }
        
        guard let zombie = steve.childNode(withName: "container", recursively: false) else {
            return SCNNode()
        }
        
        let node = zombie.clone()
        node.isHidden = false
//        node.addChildNode(container)
                
        // configure the physics of the node for collision detection, using the same shape of the object we used
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.categoryBitMask = 1
        node.physicsBody?.contactTestBitMask = 0
        node.physicsBody?.collisionBitMask = -1
        
        node.name = "spawnedNode"
        
        return node
    }
    
    // need to implement Bresenham's line
    func moveNodeTowardsPlayer(node: SCNNode) {
        let (_, position) = getCameraDirectionAndPosition()
        
        let slope = findSlope(x1: node.position.x, y1: node.position.y, x2: position.x, y2: position.y)
        let distance = findDistance(from: node.position, to: position)
        let delta = slope / distance
        
//        //Aim
//        let dx = position.x - node.position.x
//        let dz = position.z - node.position.z
//        let angle = atan2(dz, dx)
//
//        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat(angle) * CGFloat(Float.pi), z: 0, duration: 1.0)
//        node.runAction(rotate)
//
//        //Seek
//        let vx = cos(angle) * delta
//        let vz = sin(angle) * delta
//
        let moveAmount = SCNVector3(x: delta/spawnedMovementDifficultyDivider, y: 0.0, z: (slope*delta) / spawnedMovementDifficultyDivider)

        let moveAction = SCNAction.move(by: moveAmount, duration: 1.0)
        let repeatForever = SCNAction.repeatForever(moveAction)
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
        
        
//        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi), z: 0, duration: 1.0)
//        node.runAction(rotate)
        
//        guard let rotation = rotateTransform else{
//            return
//        }
//        node.transform = SCNMatrix4(rotation)
    }
    
    func findSlope(x1:Float, y1:Float, x2:Float, y2:Float) -> Float {
        return (y2 - y1) / (x2 - x1)
    }
    
    func findDistance(from start:SCNVector3, to end:SCNVector3) -> Float{
        return sqrt(pow((start.x - end.x), 2) + pow((start.y - end.y), 2))
    }
    
    // ------- END GAME BUILDING ---------
    
    
    // ------- START HELPER METHODS ---------
    func removeLoadingScreen() {
        // make call on main thread
//        DispatchQueue.main.async {
        self.loadingScreenLabel.isHidden = true
        self.activityIndicator.isHidden = true
//        }
    }
    
    func displayHowToPlayInstructions() {
        self.howToPlayInstruction.isHidden = false
    }
    
    func hideHowToPlayInstructions() {
        self.howToPlayInstruction.isHidden = true
    }
    
    func displayTapToShootInstructions() {
        self.tapToShootInstruction.isHidden = false
    }
    
    func hideTapToShootInstructions() {
        self.tapToShootInstruction.isHidden = true
    }
    
    @IBAction func pausePressed(_ sender: UIButton) {
        pauseBtn.isHidden = true
        pauseGame()
        
    }
    func gameOver() {
        saveScore()
        stopSpawnTimer()
        sceneView.overlaySKScene = getGameOverOverlay()
        sceneView.session.pause()
    }
    
    func pauseGame() {
        saveScore()
        stopSpawnTimer()
//        sceneView.pause(self)
        sceneView.scene.isPaused = true
//        sceneView.session.pause()
        sceneView.overlaySKScene = getGamePausedOverlay()
    }
    
    func resumeGame() {
        startSpawnTimer()
        sceneView.overlaySKScene = gameHUDOverlay
        pauseBtn.isHidden = false
        sceneView.scene.isPaused = false
//        sceneView.session.run(sceneView.session.configuration!)
    }
    
    func exitGame() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "GameToMenu", sender: self)
        }
    }
    
    func incScore() {
        currentScore += scoreDifficultyMultiplier
        setScore(score: currentScore)
        gameHUDOverlay?.incScore(score: scoreDifficultyMultiplier)
    }
    
    func incZombiesCount() {
        gameHUDOverlay?.zombiesCount += 1
    }
    
    func decZombiesCount() {
        gameHUDOverlay?.zombiesCount -= 1
    }
    
    func decHealth() {
        currentHealth -= healthDifficultyMultiplier
        setHealth(health: currentHealth)
        gameHUDOverlay?.decHealth(health: healthDifficultyMultiplier)
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
        healthbar.progress = CGFloat(Float(health)/100)
    }
    
    func displayHealthPenalty() {
        
    }
    
    func saveScore() {
        UserDefaults.standard.set(currentScore, forKey: "highscore")
    }
    
    func startSpawnTimer() {
        timer = Timer.scheduledTimer(timeInterval: spawnTimerDifficultyDivider, target: self, selector: #selector(spawnRandomNodes), userInfo: nil, repeats: true)
    }
    
    func stopSpawnTimer() {
        timer?.invalidate()
    }
    
    // ------- END HELPER METHODS ---------
    
    
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
