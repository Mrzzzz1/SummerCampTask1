//
//  BottleNode.swift
//  MyJump
//
//  Created by Zjt on 2022/7/18.
//

import Foundation
import SceneKit
import UIKit
class BottleNode: SCNNode {
    private let minimumHeight: CGFloat = 1.5
    private let durationToReduce: TimeInterval = 1 / 60.0
    private let coneNodeHeight: CGFloat = 3
    private let reduceHeightUnit: CGFloat = 0.01
    var maskPosition: Bool = false
    var positionY: Float = 0.0
    let MaxPressDuration = 2

    lazy var myMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        return material
    }()

    // 球
    lazy var sphereNode: SCNNode = {
        let sphere = SCNSphere(radius: 0.5)
        sphere.materials = [myMaterial]
        return SCNNode(geometry: sphere)
    }()

    // 圆锥
    lazy var coneNode: SCNNode = {
        let cone = SCNCone(topRadius: 0.0, bottomRadius: 1, height: coneNodeHeight)
        cone.materials = [myMaterial]
        return SCNNode(geometry: cone)
    }()

    override init() {
        super.init()
        coneNode.position = SCNVector3(0, -1, 0)
        sphereNode.position = SCNVector3(0, coneNodeHeight / 2, 0)
        coneNode.addChildNode(sphereNode)
        addChildNode(coneNode)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 蓄力缩小
    func scaleHeight() {
        if !maskPosition {
            positionY = position.y
            maskPosition = true
        }
        let coneGeometry = coneNode.geometry as! SCNCone
        if coneGeometry.height > minimumHeight {
            sphereNode.runAction(SCNAction.move(by: SCNVector3(0, -reduceHeightUnit, 0), duration: durationToReduce))
            coneNode.runAction(SCNAction.group([SCNAction.run { _ in
                coneGeometry.height -= self.reduceHeightUnit
            }]))
        }
    }

    func updateStrengthStatus() {
        let action = SCNAction.customAction(duration: TimeInterval(MaxPressDuration), action: { [self] node, elapsedTime in
            let percentage = elapsedTime / CGFloat(MaxPressDuration)
            node.geometry!.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 1 - percentage, blue: 1 - percentage, alpha: 1)
        })
        coneNode.runAction(action)
        sphereNode.runAction(action)
    }

    func recover() {
        sphereNode.position = SCNVector3(0, coneNodeHeight / 2, 0)
        (coneNode.geometry as! SCNCone).height = coneNodeHeight
        coneNode.geometry!.firstMaterial!.diffuse.contents = UIColor.white
        sphereNode.geometry!.firstMaterial!.diffuse.contents = UIColor.white
    }
}

extension UIColor {
    static func randomColor() -> UIColor {
        let r = CGFloat.random(in: 0...1)
        let g = CGFloat.random(in: 0...1)
        let b = CGFloat.random(in: 0...1)
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension SCNNode {
    func isNotContainedXZ(in boxNode: SCNNode) -> Bool {
        let box = boxNode.geometry as! SCNBox
        let width = Float(box.width)
        if abs(position.x - boxNode.position.x) > width / 2.0 {
            return true
        }
        if abs(position.z - boxNode.position.z) > width / 2.0 {
            return true
        }
        return false
    }

    func isNotContainedR(in CylinderNode: SCNNode) -> Bool {
        let cylinder = CylinderNode.geometry as! SCNCylinder
        let r = cylinder.radius
        let x = abs(position.x - CylinderNode.position.x)
        let z = abs(position.z - CylinderNode.position.z)
        if z*z + x*x > Float(r*r) {
            return true
        }
        return false
    }
}
