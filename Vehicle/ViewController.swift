//
//  ViewController.swift
//  FloorIsLava
//
//  Created by Demick McMullin on 10/19/17.
//  Copyright © 2017 Demick McMullin. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    // just needed a change
    
    // Vehicle ====================================================================
    
    @IBAction func addVehicle(_ sender: Any) {
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
        let location = SCNVector3(transform.m41,transform.m42,transform.m43)
        let currentPositionOfCamera = orientation + location
        
        let scene = SCNScene(named: "Car-scene.scn")
        let chassis = (scene?.rootNode.childNode(withName: "frame", recursively: false))!
        let frontLeftWheel = chassis.childNode(withName: "frontLeftParent", recursively: false)
        let frontRightWheel = chassis.childNode(withName: "frontRightParent", recursively: false)
        let backLeftWheel = chassis.childNode(withName: "rearLeftParent", recursively: false)
        let backRightWheel = chassis.childNode(withName: "rearRightParent", recursively: false) 
        let v_FrontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeftWheel!)
        let v_FrontRightWheel = SCNPhysicsVehicleWheel(node: frontRightWheel!)
        let v_backLeftWheel = SCNPhysicsVehicleWheel(node: backLeftWheel!)
        let v_backRightWheel = SCNPhysicsVehicleWheel(node: backRightWheel!)
        
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: chassis, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        
        chassis.physicsBody = body
        chassis.position = currentPositionOfCamera
        self.vehicle = SCNPhysicsVehicle(chassisBody: chassis.physicsBody!, wheels: [v_backLeftWheel, v_backRightWheel, v_FrontLeftWheel, v_FrontRightWheel])
        sceneView.scene.physicsWorld.addBehavior(vehicle)
        sceneView.scene.rootNode.addChildNode(chassis)
    }
    
    
    // Variables =======================================
    
    let configuration = ARWorldTrackingConfiguration()
    let motionManager = CMMotionManager()
    var vehicle = SCNPhysicsVehicle()
    var orientation: CGFloat = 0
    var direction: CGFloat = 0
    var touched: Int = 0
    var accelerationValues = [UIAccelerationValue(0), UIAccelerationValue(0)]
    // Functions ================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.setupAccelerometer()
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
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        var engineForce: CGFloat = 0
        var brakingForce: CGFloat = 0
        self.vehicle.setSteeringAngle(-orientation, forWheelAt: 2)
        self.vehicle.setSteeringAngle(-orientation, forWheelAt: 3)
        if self.touched == 1 {
            engineForce = 5
        } else if self.touched == 2 {
            engineForce = -5
        } else if self.touched == 3 {
            brakingForce = 100
        }
        else {
            engineForce = 0
        }
        self.vehicle.applyEngineForce(engineForce, forWheelAt: 0)
        self.vehicle.applyEngineForce(engineForce, forWheelAt: 1)
        self.vehicle.applyBrakingForce(brakingForce, forWheelAt: 0)
        self.vehicle.applyBrakingForce(brakingForce, forWheelAt: 1)
    }

    func setupAccelerometer() {
        if motionManager.isAccelerometerAvailable {
           motionManager.accelerometerUpdateInterval = 1/60
            motionManager.startAccelerometerUpdates(to: .main, withHandler: { (accelerometerData, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                guard let accelerometerData = accelerometerData else {return}
                self.accelerometerDidChange(acceleration: accelerometerData.acceleration)
                
            })
        } else {
            print("you suck")
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _ = touches.first else {return}
        self.touched += touches.count
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touched = 0
    }
    
    
    func accelerometerDidChange(acceleration: CMAcceleration) {
        accelerationValues[1] = filtered(currentAcceleration: accelerationValues[1], UpdatedAcceleration: acceleration.y)
        accelerationValues[0] = filtered(currentAcceleration: accelerationValues[0], UpdatedAcceleration: acceleration.x)
        if accelerationValues[0] > 0 {
            self.orientation = -CGFloat(accelerationValues[1])
        } else {
            self.orientation = CGFloat(accelerationValues[1])
        }
        
    }
    
    func filtered(currentAcceleration: Double, UpdatedAcceleration: Double) -> Double {
        let kfilteringFactor = 0.5
        return UpdatedAcceleration * kfilteringFactor + currentAcceleration * (1-kfilteringFactor)
    }
} // end of class ViewController =============================================

// add 2 SCNVector3 vectors function
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

extension Int {
        var degreesToRadians: Double { return Double(self) * .pi/180}
    }
