import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    weak var gameDelegate: GameSceneDelegate?
    private(set) var gameMode: GameMode = .classic

    private var mergeComboCounter = 0
    private var mergeComboTimer: Timer?
    private var safeAreaInsets: UIEdgeInsets = .zero
    private var gameOverTriggered = false
    private var stackOverLineStartedAt: TimeInterval?
    private var lastUpdateTime: TimeInterval = 0

    private var frameBuffer = [SKTexture]()
    private let frameBufferSize = 18
    private var shouldRecordFrames = true
    private var frameCaptureCounter = 0
    private let frameCaptureInterval = 15

    private let playfieldInset: CGFloat = 24
    private let groundHeight: CGFloat = AppMetrics.playfieldFloorClearance
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let animal: UInt32 = 0x1 << 0
        static let ground: UInt32 = 0x1 << 1
        static let wall: UInt32 = 0x1 << 2
    }

    override func didMove(to view: SKView) {
        safeAreaInsets = view.safeAreaInsets
        scaleMode = .resizeFill
        backgroundColor = .clear
        setupPhysics()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if oldSize != .zero, oldSize != size {
            safeAreaInsets = view?.safeAreaInsets ?? safeAreaInsets
            rebuildBoundaries()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        lastUpdateTime = currentTime
        captureFrameIfNeeded()
        checkForGameOver(currentTime: currentTime)
    }

    func setupPhysics() {
        guard size.width > 0, size.height > 0 else { return }

        removeAllChildren()
        frameBuffer.removeAll()
        shouldRecordFrames = true
        gameOverTriggered = false
        stackOverLineStartedAt = nil
        mergeComboCounter = 0
        mergeComboTimer?.invalidate()
        mergeComboTimer = nil

        physicsWorld.contactDelegate = self
        physicsWorld.gravity = gravityVector(for: gameMode)

        rebuildBoundaries()
    }

    func configure(mode: GameMode) {
        gameMode = mode
        physicsWorld.gravity = gravityVector(for: mode)
    }

    @discardableResult
    func addAnimal(animal: Animal, atX xPosition: CGFloat, yPosition: CGFloat? = nil, isMergeResult: Bool = false) -> SKSpriteNode? {
        guard !gameOverTriggered else { return nil }

        let texture = SKTexture(imageNamed: animal.imageName)
        let sprite = SKSpriteNode(texture: texture)
        sprite.name = "animal-\(UUID().uuidString)"

        let baseSize = min(max(size.width * 0.18, 74), 86)
        let animalSize = min(size.width * 0.4, min(168, baseSize + (animal.mass * 5.7)))
        sprite.size = CGSize(width: animalSize, height: animalSize)

        let minX = playfieldInset + animalSize / 2
        let maxX = size.width - playfieldInset - animalSize / 2
        let spawnX = max(minX, min(maxX, xPosition))
        let dropSpawnY = min(size.height - safeAreaInsets.top - 118, foulLineY - animalSize * 0.8)
        let minY = safeAreaInsets.bottom + groundHeight + animalSize / 2
        let maxY = size.height - safeAreaInsets.top - animalSize / 2
        let spawnY = max(minY, min(maxY, yPosition ?? dropSpawnY))
        sprite.position = CGPoint(x: spawnX, y: spawnY)
        sprite.zPosition = 20

        let radius = animalSize * 0.46
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.mass = max(0.12, animal.mass / 3.5)
        body.friction = animal.friction
        body.restitution = animal.restitution
        body.linearDamping = 0.15
        body.angularDamping = 0.35
        body.allowsRotation = true
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = PhysicsCategory.animal
        body.collisionBitMask = PhysicsCategory.animal | PhysicsCategory.ground | PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.animal | PhysicsCategory.ground | PhysicsCategory.wall
        sprite.physicsBody = body

        sprite.userData = [
            "animal": animal,
            "createdAt": lastUpdateTime > 0 ? lastUpdateTime : CACurrentMediaTime(),
            "isCascadeEligible": isMergeResult
        ]

        addChild(sprite)
        addAnimalOverlays(to: sprite, animal: animal, animalSize: animalSize)
        animateDropSquash(sprite)
        return sprite
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard !gameOverTriggered else { return }

        if contact.collisionImpulse > 5.0 {
            gameDelegate?.gameSceneDidThump(self)
        }

        guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else { return }
        guard let animalA = nodeA.userData?["animal"] as? Animal,
              let animalB = nodeB.userData?["animal"] as? Animal else { return }
        guard animalA.name == animalB.name,
              let mergeResultName = animalA.mergeResult,
              let nextAnimal = AnimalLibrary.getAnimal(byName: mergeResultName) else { return }
        guard nodeA.parent != nil, nodeB.parent != nil else { return }
        guard nodeA.userData?["isMerging"] as? Bool != true,
              nodeB.userData?["isMerging"] as? Bool != true else { return }

        nodeA.userData?["isMerging"] = true
        nodeB.userData?["isMerging"] = true

        let isCascade = (nodeA.userData?["isCascadeEligible"] as? Bool ?? false) ||
            (nodeB.userData?["isCascadeEligible"] as? Bool ?? false)
        let combo = max(1, mergeComboCounter + (isCascade ? 1 : 0))
        let mergePosition = CGPoint(
            x: (nodeA.position.x + nodeB.position.x) / 2,
            y: (nodeA.position.y + nodeB.position.y) / 2
        )

        run(SKAction.playSoundFileNamed(
            nextAnimal.rarity == .legendary || nextAnimal.rarity == .mythical ? "pop3.mp3" : "pop2.mp3",
            waitForCompletion: false
        ))

        addMergeEffect(at: mergePosition, for: nextAnimal)
        gameDelegate?.gameScene(self, didMergeInitialAnimal: animalA, toCreate: nextAnimal, at: mergePosition, combo: combo)

        nodeA.removeFromParent()
        nodeB.removeFromParent()
        addAnimal(animal: nextAnimal, atX: mergePosition.x, yPosition: mergePosition.y, isMergeResult: true)

        if let ability = nextAnimal.ability {
            triggerAbility(ability, at: mergePosition)
        }

        mergeComboCounter = combo + 1
        mergeComboTimer?.invalidate()
        mergeComboTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.mergeComboCounter = 0
        }
    }

    func showScoreIndicator(at position: CGPoint, amount: Int) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "+\(amount)"
        label.fontSize = 36
        label.fontColor = .yellow
        label.position = position
        label.zPosition = 100
        label.horizontalAlignmentMode = .center
        addChild(label)

        let moveUpAction = SKAction.move(by: CGVector(dx: 0, dy: 86), duration: 1.2)
        moveUpAction.timingMode = .easeOut
        let group = SKAction.group([moveUpAction, .fadeOut(withDuration: 1.2)])
        label.run(.sequence([group, .removeFromParent()]))
    }

    func clearBottomAnimals() {
        animalNodes()
            .sorted { $0.position.y < $1.position.y }
            .prefix(5)
            .forEach { $0.removeFromParent() }
    }

    func clearTopAnimals() {
        animalNodes()
            .sorted { $0.position.y > $1.position.y }
            .prefix(6)
            .forEach { $0.removeFromParent() }
        gameOverTriggered = false
        shouldRecordFrames = true
        stackOverLineStartedAt = nil
    }

    func resetScene() {
        setupPhysics()
    }

    func snapshotAnimalStates() -> [SavedRunAnimalState] {
        animalNodes().compactMap { node in
            guard let animal = node.userData?["animal"] as? Animal else { return nil }
            return SavedRunAnimalState(
                animalName: animal.name,
                x: node.position.x,
                y: node.position.y,
                rotation: node.zRotation,
                velocityDX: node.physicsBody?.velocity.dx ?? 0,
                velocityDY: node.physicsBody?.velocity.dy ?? 0,
                angularVelocity: node.physicsBody?.angularVelocity ?? 0
            )
        }
    }

    func restoreAnimalStates(_ animalStates: [SavedRunAnimalState]) {
        animalNodes().forEach { $0.removeFromParent() }
        gameOverTriggered = false
        shouldRecordFrames = true
        stackOverLineStartedAt = nil

        for animalState in animalStates {
            guard let animal = AnimalLibrary.getAnimal(byName: animalState.animalName),
                  let node = addAnimal(animal: animal, atX: animalState.x, yPosition: animalState.y) else {
                continue
            }
            node.zRotation = animalState.rotation
            node.physicsBody?.velocity = CGVector(dx: animalState.velocityDX, dy: animalState.velocityDY)
            node.physicsBody?.angularVelocity = animalState.angularVelocity
        }
    }

    func playReviveSound() {
        run(SKAction.playSoundFileNamed("revive.wav", waitForCompletion: false))
    }

    func nudgeAnimals() {
        animalNodes().forEach { node in
            let dx = CGFloat.random(in: -22...22)
            node.physicsBody?.applyImpulse(CGVector(dx: dx, dy: 8))
        }
    }

    private func addBoundaryNodes() {
        let groundY = safeAreaInsets.bottom + groundHeight

        let ground = SKNode()
        ground.name = "ground"
        ground.position = .zero
        ground.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: playfieldInset, y: groundY),
                                           to: CGPoint(x: size.width - playfieldInset, y: groundY))
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.collisionBitMask = PhysicsCategory.animal
        addChild(ground)

        let leftWall = SKNode()
        leftWall.name = "leftWall"
        leftWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: playfieldInset, y: groundY),
                                             to: CGPoint(x: playfieldInset, y: size.height + 160))
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        leftWall.physicsBody?.collisionBitMask = PhysicsCategory.animal
        addChild(leftWall)

        let rightWall = SKNode()
        rightWall.name = "rightWall"
        rightWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: size.width - playfieldInset, y: groundY),
                                              to: CGPoint(x: size.width - playfieldInset, y: size.height + 160))
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        rightWall.physicsBody?.collisionBitMask = PhysicsCategory.animal
        addChild(rightWall)
    }

    private func rebuildBoundaries() {
        children
            .filter { ["ground", "leftWall", "rightWall", "foulLine"].contains($0.name) }
            .forEach { $0.removeFromParent() }

        addBoundaryNodes()
        addFoulLine()
    }

    private func addFoulLine() {
        let line = SKShapeNode()
        let y = foulLineY
        let path = CGMutablePath()
        path.move(to: CGPoint(x: playfieldInset, y: y))
        path.addLine(to: CGPoint(x: size.width - playfieldInset, y: y))
        line.path = path
        line.strokeColor = UIColor(red: 1.0, green: 0.31, blue: 0.22, alpha: 0.78)
        line.lineWidth = 3
        line.glowWidth = 3
        line.zPosition = 5
        line.name = "foulLine"
        addChild(line)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "DANGER LINE"
        label.fontSize = 12
        label.fontColor = UIColor(red: 1.0, green: 0.34, blue: 0.25, alpha: 0.9)
        label.horizontalAlignmentMode = .right
        label.verticalAlignmentMode = .bottom
        label.position = CGPoint(x: size.width - playfieldInset, y: y + 6)
        label.zPosition = 6
        label.name = "foulLine"
        addChild(label)
    }

    private var foulLineY: CGFloat {
        size.height * AppMetrics.foulLineHeightPercentage
    }

    private func gravityVector(for mode: GameMode) -> CGVector {
        let multiplier: CGFloat
        switch mode {
        case .classic, .dailySafari, .challenge:
            multiplier = 1.0
        case .timedStampede:
            multiplier = 1.12
        case .zen:
            multiplier = 0.72
        }
        return CGVector(dx: 0, dy: AppMetrics.gravityForce * multiplier)
    }

    private func captureFrameIfNeeded() {
        guard shouldRecordFrames else { return }
        frameCaptureCounter += 1
        guard frameCaptureCounter >= frameCaptureInterval else { return }
        frameCaptureCounter = 0

        if let view, let texture = view.texture(from: self) {
            frameBuffer.append(texture)
            if frameBuffer.count > frameBufferSize {
                frameBuffer.removeFirst()
            }
        }
    }

    private func checkForGameOver(currentTime: TimeInterval) {
        guard gameMode.allowsGameOver, !gameOverTriggered else { return }

        let settledAboveLine = animalNodes().contains { node in
            guard let body = node.physicsBody else { return false }
            let age = currentTime - (node.userData?["createdAt"] as? TimeInterval ?? currentTime)
            let radius = max(node.frame.width, node.frame.height) / 2
            let top = node.position.y + radius
            let isSettled = abs(body.velocity.dy) < 45 && abs(body.velocity.dx) < 70
            return age > 1.7 && top > foulLineY && isSettled
        }

        if settledAboveLine {
            if stackOverLineStartedAt == nil {
                stackOverLineStartedAt = currentTime
            }
            if let startedAt = stackOverLineStartedAt, currentTime - startedAt > 1.0 {
                gameOverTriggered = true
                shouldRecordFrames = false
                gameDelegate?.gameScene(self, didTriggerGameOverWithFrames: frameBuffer)
            }
        } else {
            stackOverLineStartedAt = nil
        }
    }

    private func animateDropSquash(_ sprite: SKSpriteNode) {
        let originalSize = sprite.size
        let scaleDown = SKAction.scale(to: CGSize(width: originalSize.width * 1.16, height: originalSize.height * 0.84), duration: 0.08)
        let scaleUp = SKAction.scale(to: CGSize(width: originalSize.width * 0.92, height: originalSize.height * 1.08), duration: 0.08)
        let scaleNormal = SKAction.scale(to: originalSize, duration: 0.12)
        sprite.run(.sequence([scaleDown, scaleUp, scaleNormal, .run { [weak sprite] in
            self.startIdleMotion(on: sprite)
        }]))
    }

    private func startIdleMotion(on sprite: SKSpriteNode?) {
        guard let sprite else { return }
        sprite.removeAction(forKey: "idle-breathe")
        let inhale = SKAction.scaleX(to: 1.015, y: 0.992, duration: 1.35)
        inhale.timingMode = .easeInEaseOut
        let exhale = SKAction.scaleX(to: 0.995, y: 1.01, duration: 1.25)
        exhale.timingMode = .easeInEaseOut
        let settle = SKAction.scale(to: 1.0, duration: 0.28)
        let wait = SKAction.wait(forDuration: Double.random(in: 0.15...0.75))
        sprite.run(.sequence([wait, .repeatForever(.sequence([inhale, exhale, settle]))]), withKey: "idle-breathe")
    }

    private func addAnimalOverlays(to sprite: SKSpriteNode, animal: Animal, animalSize: CGFloat) {
        let rarity = animal.rarity

        if rarity == .legendary || rarity == .mythical {
            let halo = SKShapeNode(circleOfRadius: animalSize * 0.54)
            halo.name = "rarity-halo"
            halo.strokeColor = rarity == .mythical ? .cyan.withAlphaComponent(0.45) : .yellow.withAlphaComponent(0.42)
            halo.lineWidth = 2
            halo.glowWidth = 5
            halo.zPosition = -1
            sprite.addChild(halo)
            halo.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.28, duration: 0.8),
                .fadeAlpha(to: 0.72, duration: 0.8)
            ])))
        }
    }

    private func addMergeEffect(at position: CGPoint, for animal: Animal) {
        let isRare = animal.rarity == .legendary || animal.rarity == .mythical
        let glow = SKSpriteNode(texture: SKTexture(imageNamed: "fx_merge_glow_ring"))
        glow.position = position
        glow.size = CGSize(width: isRare ? 190 : 130, height: isRare ? 190 : 130)
        glow.zPosition = 88
        glow.alpha = isRare ? 0.82 : 0.58
        addChild(glow)
        glow.run(.sequence([
            .group([
                .scale(to: 1.55, duration: 0.34),
                .fadeOut(withDuration: 0.34),
                .rotate(byAngle: .pi / 2, duration: 0.34)
            ]),
            .removeFromParent()
        ]))

        let ribbons = SKEmitterNode()
        ribbons.particleTexture = SKTexture(imageNamed: "fx_merge_ribbons")
        ribbons.particleBirthRate = isRare ? 420 : 260
        ribbons.numParticlesToEmit = isRare ? 24 : 14
        ribbons.particleLifetime = 0.55
        ribbons.particleSpeed = isRare ? 190 : 126
        ribbons.particleSpeedRange = 70
        ribbons.emissionAngleRange = .pi * 2
        ribbons.particleScale = isRare ? 0.22 : 0.14
        ribbons.particleScaleRange = 0.08
        ribbons.particleAlpha = 0.86
        ribbons.particleAlphaSpeed = -1.25
        ribbons.position = position
        ribbons.zPosition = 89
        addChild(ribbons)
        ribbons.run(.sequence([.wait(forDuration: 0.85), .removeFromParent()]))

        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: isRare ? "fx_sparkle_cluster" : "fx_soft_gold_particle")
        emitter.particleBirthRate = isRare ? 1400 : 800
        emitter.numParticlesToEmit = isRare ? 38 : 22
        emitter.particleLifetime = isRare ? 0.7 : 0.45
        emitter.particleSpeed = isRare ? 240 : 145
        emitter.particleSpeedRange = isRare ? 110 : 60
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = isRare ? 0.28 : 0.2
        emitter.particleScaleRange = 0.12
        emitter.particleColor = isRare ? .yellow : .white
        emitter.particleColorBlendFactor = isRare ? 0.8 : 0.2
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.4
        emitter.position = position
        emitter.zPosition = 90
        addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 1.0), .removeFromParent()]))
    }

    private func triggerAbility(_ ability: AnimalAbility, at position: CGPoint) {
        switch ability {
        case .roar:
            triggerRoarAbility(at: position)
        case .pounce:
            triggerPounceAbility(at: position)
        case .heavyweight:
            freezeNearbyHeavyAnimal(at: position)
        case .windGust:
            nudgeAnimals()
        }
    }

    private func triggerRoarAbility(at position: CGPoint) {
        run(SKAction.playSoundFileNamed("achievement.wav", waitForCompletion: false))
        animalNodes().forEach { node in
            let distance = hypot(node.position.x - position.x, node.position.y - position.y)
            guard distance < 120 else { return }
            node.run(.sequence([
                .moveBy(x: 6, y: 0, duration: 0.05),
                .moveBy(x: -12, y: 0, duration: 0.1),
                .moveBy(x: 6, y: 0, duration: 0.05)
            ]))
        }
    }

    private func triggerPounceAbility(at position: CGPoint) {
        animalNodes().forEach { node in
            let distance = hypot(node.position.x - position.x, node.position.y - position.y)
            guard distance < 60 else { return }
            node.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 22))
        }
    }

    private func freezeNearbyHeavyAnimal(at position: CGPoint) {
        animalNodes().forEach { node in
            let distance = hypot(node.position.x - position.x, node.position.y - position.y)
            guard distance < 60 else { return }
            node.physicsBody?.mass *= 1.25
            node.physicsBody?.friction = min(1.0, (node.physicsBody?.friction ?? 0.7) + 0.15)
        }
    }

    private func animalNodes() -> [SKNode] {
        children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.animal }
    }

}
