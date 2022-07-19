//
//  GameViewController.swift
//  MyJump
//
//  Created by Zjt on 2022/7/18.
//

import CoreData
import QuartzCore
import SceneKit
import UIKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    private lazy var rankView: UITableView = {
        let rankView = UITableView(frame: view.frame)
        rankView.register(ScoreTableViewCell.self, forCellReuseIdentifier: Id)
        rankView.delegate = self
        rankView.dataSource = self
        let returnButton = UIButton(frame: CGRect(x: 300, y: 10, width: 100, height: 18))
        returnButton.setTitleColor(.systemBlue, for: .normal)
        returnButton.setTitle("return", for: .normal)
        returnButton.addTarget(self, action: #selector(clickReturnButton), for: .touchUpInside)
        returnButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 25.0)
        rankView.addSubview(returnButton)
        return rankView
    }()

    let returnButton: UIButton = {
        let returnButton = UIButton(frame: CGRect(x: 310, y: 10, width: 100, height: 15))
        returnButton.setTitleColor(.systemBlue, for: .normal)
        returnButton.setTitle("return", for: .normal)
        returnButton.addTarget(self, action: #selector(clickReturnButton), for: .touchUpInside)
        returnButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 25.0)
        return returnButton
    }()
    
    var scoreData: [ScoreInfo] = []
    let Id = "ScoretableViewCell"
    
    var scnScene: SCNScene!
    var scnView: SCNView!
    var cameraNode: SCNNode!
    // 相机相对位置
    var cameraX = -15
    var cameraY = 40
    var cameraZ = 20
    
    private lazy var backgroundMusicPlayer: SCNAudioPlayer = {
        let music = SCNAudioSource(fileNamed: "日本群星-ハイグレしんちゃん.mp3")!
        // 3.设置音量,循环播放,流读取,空间化(是否随位置不同有3D效果)
        // music.volume = 1;
        music.loops = true
        music.shouldStream = true
        // music.isPositional = false
        // 4.创建播放器
        let musicPlayer = SCNAudioPlayer(source: music)
        return musicPlayer
    }()

    let presssoundMusic = SCNAudioSource(fileNamed: "presssound.mp3")!
    
    let fallsoundMusic = SCNAudioSource(fileNamed: "fallsound.mp3")!
    
    let failsoundMusic = SCNAudioSource(fileNamed: "failsound.mp3")!
    
    private var boxNodes: [SCNNode] = []
    private lazy var bottleNode: BottleNode = .init()
    
    private var maskTouch: Bool = false
    private var canTouch: Bool = true
    private var nextDirection: NextDirection = .left
    // 蓄力时间
    private var touchTimePair: (begin: TimeInterval, end: TimeInterval) = (0, 0)
    // 计算跳跃距离
    private let distanceCalculateClosure: (TimeInterval) -> CGFloat = {
        CGFloat($0) / 4.0
    }

    private let moveDuration: TimeInterval = 0.25
    private var isBox: Int = 0
    private let boxWidth: CGFloat = 5
    private let boxHeigh: CGFloat = 2
    private let jumpHeight: CGFloat = 3
    private let scoreLabel = UILabel(frame: CGRect(x: 20,
                                                   y: 50,
                                                   width: 200,
                                                   height: 30))
    private let rankButton: UIButton = {
        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 150, y: 50, width: 150, height: 30))
        button.setTitle("rank", for: .normal)
        button.addTarget(self, action: #selector(clickRankbutton), for: .touchUpInside)
        button.setTitleColor(UIColor.systemBlue, for: .normal)

        return button
    }()
    
    @objc func clickRankbutton() {
        setUpRankView()
    }

    private var score: UInt = 0 {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                self.scoreLabel.text = "Score: \(self.score)"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        // spawnShape()
        scoreLabel.font = UIFont(name: "HelveticaNeue", size: 30.0)
        scoreLabel.textColor = .black
        rankButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 30.0)
        scnView.addSubview(scoreLabel)
        scnView.addSubview(rankButton)
        scnScene.rootNode.addAudioPlayer(backgroundMusicPlayer)
        restartGame()
    }

    func setupView() {
        scnView = (view as! SCNView)
        scnView.backgroundColor = .white
        scnView.showsStatistics = true
        // scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
    }

    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
    }

    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        cameraNode.camera?.zFar = 200.0
        cameraNode.camera?.zNear = 0.1
        
        cameraNode.eulerAngles = SCNVector3Make(-0.9, -0.7, 0)
        cameraNode.position = SCNVector3(x: Float(cameraX), y: Float(cameraY), z: Float(cameraZ))
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func setUpRankView() {
        scoreData = ScoreHelper.shared.queryScore()
        view.addSubview(rankView)
        rankView.reloadData()
    }
    
    @objc func clickReturnButton() {
        rankView.removeFromSuperview()
        // rankButton.isEnabled = true
    }

    // 重启游戏
    func restartGame() {
        touchTimePair = (0, 0)
        score = 0
        boxNodes.forEach {
            $0.removeFromParentNode()
        }
        bottleNode.removeFromParentNode()
        boxNodes.removeAll()
        generateBox(at: SCNVector3(0, 0, 0))
        addConeNode()
        generateBox(at: boxNodes.last!.position)
        cameraNode.position = SCNVector3(cameraX, cameraY, cameraZ)
    }

    // 初始化圆锥
    func addConeNode() {
        bottleNode.position = SCNVector3(boxNodes.last!.position.x,
                                         boxNodes.last!.position.y + Float(boxWidth) * 0.75,
                                         boxNodes.last!.position.z)
        scnView.scene!.rootNode.addChildNode(bottleNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if boxNodes.isEmpty {
            generateBox(at: SCNVector3(0, 0, 0))
            addConeNode()
            generateBox(at: boxNodes.last!.position)
        } else {
            if !canTouch { return }
            if !maskTouch {
                canTouch.toggle()
                maskTouch.toggle()
                touchTimePair.begin = (event?.timestamp)!
                bottleNode.updateStrengthStatus()
                scnScene.rootNode.runAction(SCNAction.playAudio(presssoundMusic, waitForCompletion: false))
            }
//            print("toutchesBegan")
//            touchTimePair.begin = (event?.timestamp)!
//            bottleNode.updateStrengthStatus()
//            scnScene.rootNode.runAction(SCNAction.playAudio(presssoundMusic, waitForCompletion: false))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if maskTouch {
            maskTouch.toggle()
            scnScene.rootNode.runAction(SCNAction.playAudio(fallsoundMusic, waitForCompletion: true))
            
            touchTimePair.end = (event?.timestamp)!
            
            let distance = distanceCalculateClosure(touchTimePair.end - touchTimePair.begin) * 30
            var actions = [SCNAction()]
            if nextDirection == .left {
                let moveAction1 = SCNAction.moveBy(x: distance, y: jumpHeight, z: 0, duration: moveDuration)
                let moveAction2 = SCNAction.moveBy(x: distance, y: -jumpHeight, z: 0, duration: moveDuration)
                actions = [SCNAction.rotateBy(x: 0, y: 0, z: -.pi * 2, duration: moveDuration * 2),
                           SCNAction.sequence([moveAction1, moveAction2])]
            } else {
                let moveAction1 = SCNAction.moveBy(x: 0, y: jumpHeight, z: -distance, duration: moveDuration)
                let moveAction2 = SCNAction.moveBy(x: 0, y: -jumpHeight, z: -distance, duration: moveDuration)
                actions = [SCNAction.rotateBy(x: .pi * 2, y: 0, z: 0, duration: moveDuration * 2),
                           SCNAction.sequence([moveAction1, moveAction2])]
            }
            bottleNode.sphereNode.removeAllActions()
            bottleNode.coneNode.removeAllActions()
            bottleNode.recover()
            bottleNode.runAction(SCNAction.group(actions), completionHandler: { [weak self] in
                self?.canTouch = true
                let boxNode = (self?.boxNodes.last!)!
                var isNotContained = false
                if self?.isBox == 1 {
                    isNotContained = self?.bottleNode.isNotContainedXZ(in: boxNode) ?? true
                } else {
                    isNotContained = self?.bottleNode.isNotContainedR(in: boxNode) ?? true
                }
                if isNotContained {
                    ScoreHelper.shared.setHighestScore(Int((self?.score)!))
                    let nowScore = self!.score
                    let date = DateFormatter()
                    date.dateFormat = "yyyy-MM-dd HH:mm"
                    let timeNow = Date()
                    let time = date.string(from: timeNow)
                    ScoreHelper.shared.saveScore(score: Int(nowScore), time: time)
                    DispatchQueue.main.async {
                        self?.scnScene.rootNode.runAction(SCNAction.playAudio(self!.failsoundMusic, waitForCompletion: true))
                        self?.alert(message: "Game Over!\n\nScore: \(nowScore)\n\nHighest: \(ScoreHelper.shared.getHighestScore())")
                    }
                    self?.restartGame()
                } else {
                    self?.score += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.moveCamera()
                    }

                    self?.generateBox(at: (self?.boxNodes.last!.position)!)
                }
            })
        }
    }

    func moveCamera() {
        var position = bottleNode.position
        position.x += Float(cameraX)
        position.y += Float(cameraY)
        position.z += Float(cameraZ)
        let move = SCNAction.move(to: position, duration: 0.5)
        cameraNode.runAction(move)
    }

    private func generateBox(at realPosition: SCNVector3) {
        isBox = Int.random(in: 0...1)
        
        let box: SCNGeometry = {
            let boxWidth = self.boxWidth
            switch isBox {
            case 1:
                let box = SCNBox(width: boxWidth, height: boxHeigh, length: boxWidth, chamferRadius: 0.0)
                return box
            default:
                let box = SCNCylinder(radius: boxWidth / 2, height: boxHeigh)
                return box
            }
        }()
        let node = SCNNode(geometry: box)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.randomColor()
        box.materials = [material]
        
        if boxNodes.isEmpty {
            node.position = realPosition
        } else {
            nextDirection = NextDirection(rawValue: Int.random(in: 0...1))!
            let deltaDistance = Double.random(in: 5...15)
            if nextDirection == .left {
                node.position = SCNVector3(realPosition.x + Float(deltaDistance), realPosition.y, realPosition.z)
            } else {
                node.position = SCNVector3(realPosition.x, realPosition.y, realPosition.z - Float(deltaDistance))
            }
        }
        
        scnView.scene!.rootNode.addChildNode(node)
        boxNodes.append(node)
    }
    
    func alert(message: String) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if maskTouch {
            bottleNode.scaleHeight()
        }
    }
}

extension GameViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if scoreData.count > 100 {
            return 100
        }
        return scoreData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = rankView.dequeueReusableCell(withIdentifier: Id, for: indexPath) as! ScoreTableViewCell
        cell.fillView(rank: indexPath.item + 1, score: Int(scoreData[indexPath.item].score), time: scoreData[indexPath.item].time!)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " rank           score            time"
    }
}
