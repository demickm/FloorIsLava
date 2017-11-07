//
//  ViewController.swift
//  FloorIsLava
//
//  Created by Demick McMullin on 10/19/17.
//  Copyright © 2017 Demick McMullin. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBAction func addVehicle(_ sender: Any) {
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = orientation + location
        
        let scene = SCNScene(named: "Car-scene.scn")
        let carNode = (scene?.rootNode.childNode(withName: "frame", recursively: false))! 
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: carNode, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        carNode.physicsBody = body
        carNode.position = currentPositionOfCamera
        sceneView.scene.rootNode.addChildNode(carNode)
    }

    let configuration = ARWorldTrackingConfiguration()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height:CGFloat(planeAnchor.extent.z)))
        concreteNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        concreteNode.eulerAngles = SCNVector3(CGFloat(90.degreesToRadians),0,0)
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody
        return concreteNode
    }
    // creates an anchor when new plane is detected
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
    }
    // updates the plane as the plane is updated by phone
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
         guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
    }
    // removes redundant points
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else { return }
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
    }
    
}
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

extension Int {
        
        var degreesToRadians: Double { return Double(self) * .pi/180}
    }
