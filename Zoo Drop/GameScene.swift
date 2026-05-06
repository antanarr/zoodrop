import SpriteKit

// The GameSceneDelegate protocol has been moved to its own file.
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var gameDelegate: GameSceneDelegate?
    
    private var mergeComboCounter = 0
    private var mergeComboTimer: Timer?
    private var safeAreaInsets: UIEdgeInsets = .zero
    
    private var frameBuffer = [SKTexture]()
    private let frameBufferSize = 100
    private var shouldRecordFrames = true
    private var frameCaptureCounter = 0
    private let frameCaptureInterval = 3
    
    private let standardMergeEmitter: SKEmitterNode = {
        let node = SKEmitterNode()
        node.particleTexture = SKTexture(imageNamed: "vfx_merge_pop")
        node.particleBirthRate = 1000
        node.numParticlesToEmit = 15
        node.particleLifetime = 0.5
        node.particleSpeed = 150
        node.particleSpeedRange = 50
        node.emissionAngleRange = .pi * 2
        node.particleScale = 0.2
        node.particleScaleRange = 0.1
        node.particleAlpha = 0.8
        node.particleAlphaSpeed = -1.5
        return node
    }()
    
    private let legendaryMergeEmitter: SKEmitterNode = {
        let node = SKEmitterNode()
        node.particleTexture = SKTexture(imageNamed: "vfx_merge_legendary")
        node.particleBirthRate = 2000
        node.numParticlesToEmit = 40
        node.particleLifetime = 0.75
        node.particleSpeed = 250
        node.particleSpeedRange = 100
        node.emissionAngleRange = .pi * 2
        node.particleScale = 0.3
        node.particleScaleRange = 0.15
        node.particleColor = .yellow
        node.particleColorBlendFactor = 0.8
        node.particleAlpha = 0.9
        node.particleAlphaSpeed = -1.0
        return node
    }()
    
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let animal: UInt32 = 0x1 << 0
        static let ground: UInt32 = 0x1 << 1
        static let foulLine: UInt32 = 0x1 << 2
        static let wall: UInt32 = 0x1 << 3
    }
    
    override func didMove(to view: SKView) {
        self.safeAreaInsets = view.safeAreaInsets
        run(SKAction.playSoundFileNamed("ambientloop.wav", waitForCompletion: false))
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard shouldRecordFrames else { return }
        frameCaptureCounter += 1
        if frameCaptureCounter >= frameCaptureInterval {
            frameCaptureCounter = 0
            if let view = self.view, let texture = view.texture(from: self) {
                frameBuffer.append(texture)
                if frameBuffer.count > frameBufferSize {
                    frameBuffer.removeFirst()
                }
            }
        }
    }
    
    func setupPhysics() {
        guard size != .zero else { return }
        frameBuffer.removeAll()
        shouldRecordFrames = true
        self.removeAllChildren()
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        // Ground, Foul Line, and Wall setup code...
    }

    func addAnimal(animal: Animal, atX xPosition: CGFloat, isMergeResult: Bool = false) {
        let texture = SKTexture(imageNamed: animal.imageName)
        let sprite = SKSpriteNode(texture: texture)
        
        let baseSize: CGFloat = 40
        let animalSize = baseSize + (animal.mass * 4.0)
        sprite.size = CGSize(width: animalSize, height: animalSize)
        
        sprite.position = CGPoint(x: xPosition, y: self.size.height - (self.safeAreaInsets.top + 75))
        
        // Physics body creation...
        
        sprite.userData = ["animal": animal]
        if isMergeResult {
            sprite.userData?["isCascadeEligible"] = true
        }
        addChild(sprite)
        
        let scaleDown = SKAction.scale(to: CGSize(width: sprite.size.width * 1.2, height: sprite.size.height * 0.8), duration: 0.1)
        let scaleUp = SKAction.scale(to: CGSize(width: sprite.size.width * 0.9, height: sprite.size.height * 1.1), duration: 0.1)
        let scaleNormal = SKAction.scale(to: sprite.size, duration: 0.15)
        let sequence = SKAction.sequence([scaleDown, scaleUp, scaleNormal])
        sprite.run(sequence)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if contact.collisionImpulse > 5.0 {
            gameDelegate?.gameSceneDidThump(self)
        }
        
        guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else { return }
        
        if (contact.bodyA.categoryBitMask == PhysicsCategory.foulLine || contact.bodyB.categoryBitMask == PhysicsCategory.foulLine) {
            shouldRecordFrames = false
            gameDelegate?.gameScene(self, didTriggerGameOverWithFrames: self.frameBuffer)
            return
        }

        guard let animalA = nodeA.userData?["animal"] as? Animal, let animalB = nodeB.userData?["animal"] as? Animal else { return }

        if animalA.name == animalB.name, let mergeResultName = animalA.mergeResult, let nextAnimal = AnimalLibrary.getAnimal(byName: mergeResultName) {
            let isCascade = (nodeA.userData?["isCascadeEligible"] as? Bool ?? false) || (nodeB.userData?["isCascadeEligible"] as? Bool ?? false)
            let comboMultiplier = isCascade ? AppMetrics.Scoring.comboMultiplier : 1.0
            let mergePosition = CGPoint(x: (nodeA.position.x + nodeB.position.x) / 2, y: (nodeA.position.y + nodeB.position.y) / 2)
            gameDelegate?.gameScene(self, didMergeInitialAnimal: animalA, toCreate: nextAnimal, at: mergePosition, combo: Int(comboMultiplier * Double(mergeComboCounter)))
            if nextAnimal.rarity == .legendary || nextAnimal.rarity == .mythical {
                run(SKAction.playSoundFileNamed("pop3.mp3", waitForCompletion: false))
            } else {
                run(SKAction.playSoundFileNamed("pop2.mp3", waitForCompletion: false))
            }
            let emitter = (nextAnimal.rarity == .legendary || nextAnimal.rarity == .mythical) ? legendaryMergeEmitter.copy() as! SKEmitterNode : standardMergeEmitter.copy() as! SKEmitterNode
            emitter.position = mergePosition
            addChild(emitter)
            emitter.run(SKAction.sequence([.wait(forDuration: 1.0), .removeFromParent()]))

            let mergeAction = SKAction.run {
                nodeA.removeFromParent()
                nodeB.removeFromParent()
                self.addAnimal(animal: nextAnimal, atX: mergePosition.x, isMergeResult: true)
                // Check for ability and trigger it
                if let ability = nextAnimal.ability {
                    self.triggerAbility(ability.rawValue, at: mergePosition)
                }
            }
            self.run(mergeAction)

            mergeComboCounter += 1
            mergeComboTimer?.invalidate()
            mergeComboTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in self?.mergeComboCounter = 0 }
        }
    }

    func triggerAbility(_ ability: String, at position: CGPoint) {
        switch ability {
        case "Roar":
            triggerRoarAbility(at: position)
        case "Pounce":
            triggerPounceAbility(at: position)
        default:
            break
        }
    }

    func triggerRoarAbility(at position: CGPoint) {
        // Example: play roar sound and shake nearby animals
        run(SKAction.playSoundFileNamed("roar.mp3", waitForCompletion: false))
        run(SKAction.playSoundFileNamed("achievement.wav", waitForCompletion: false))
        let nearbyAnimals = children.compactMap { node -> SKNode? in
            guard let animal = node.userData?["animal"] as? Animal else { return nil }
            let distance = hypot(node.position.x - position.x, node.position.y - position.y)
            return distance < 100 ? node : nil
        }
        for animalNode in nearbyAnimals {
            let shake = SKAction.sequence([
                SKAction.moveBy(x: 5, y: 0, duration: 0.05),
                SKAction.moveBy(x: -10, y: 0, duration: 0.1),
                SKAction.moveBy(x: 5, y: 0, duration: 0.05)
            ])
            animalNode.run(shake)
        }
    }

    func triggerPounceAbility(at position: CGPoint) {
        // Example: make merged animal bounce and maybe show a score boost
        let bounceUp = SKAction.moveBy(x: 0, y: 30, duration: 0.2)
        let bounceDown = SKAction.moveBy(x: 0, y: -30, duration: 0.2)
        let bounceSequence = SKAction.sequence([bounceUp, bounceDown])
        let nodesAtPos = nodes(at: position)
        for node in nodesAtPos {
            if let _ = node.userData?["animal"] as? Animal {
                node.run(bounceSequence)
            }
        }
        // Could also add a score pop-up or particle effect here
    }
    
    func showScoreIndicator(at position: CGPoint, amount: Int) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "+\(amount)!"
        label.fontSize = 40
        label.fontColor = .yellow
        label.position = position
        label.zPosition = 100
        label.horizontalAlignmentMode = .center
        addChild(label)
        
        let moveUpAction = SKAction.move(by: CGVector(dx: 0, dy: 100), duration: 1.5)
        moveUpAction.timingMode = .easeOut
        let fadeOutAction = SKAction.fadeOut(withDuration: 1.5)
        let group = SKAction.group([moveUpAction, fadeOutAction])
        let sequence = SKAction.sequence([group, .removeFromParent()])
        label.run(sequence)
    }
    
    func clearBottomAnimals() {
        let animals = children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.animal }
        let sortedAnimals = animals.sorted { $0.position.y < $1.position.y }
        let animalsToRemove = sortedAnimals.prefix(5)
        animalsToRemove.forEach { $0.removeFromParent() }
    }

    func resetScene() {
        // Clear all animals and reset relevant state for a new game.
        removeAllChildren()
        frameBuffer.removeAll()
        shouldRecordFrames = true
        run(SKAction.playSoundFileNamed("ambientloop.wav", waitForCompletion: false))
        // You can add more reset logic here if needed.
    }

    // Call this method as part of your revive logic to play the revive sound.
    func playReviveSound() {
        run(SKAction.playSoundFileNamed("revive.wav", waitForCompletion: false))
    }

    func nudgeAnimals() {
        let animals = children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.animal }
        for node in animals {
            let dx = CGFloat.random(in: -20...20)
            node.physicsBody?.applyImpulse(CGVector(dx: dx, dy: 0))
        }
    }
}

    func clearTopAnimals() {
        let animals = children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.animal }
        let sorted = animals.sorted { $0.position.y > $1.position.y }
        let toRemove = sorted.prefix(5)
        toRemove.forEach { $0.removeFromParent() }
    }
