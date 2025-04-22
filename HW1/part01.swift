
import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    let manager: CMMotionManager = CMMotionManager()
    var acc_dataset: [(x: Double, y: Double, z: Double)] = []
    var gyro_dataset: [(x: Double, y: Double, z: Double)] = []
    var num_data = 0
    let max_data = 60000
    
    var csv_data: String = "timestamp, acc_x, acc_y, acc_z, gyro_x, gyro_y, gyro_z\n"
    
    func SaveData(){
        var fileURL: URL!
        do {
            
            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)
            
            fileURL = path.appendingPathComponent("imudata01.csv")
            
            try csv_data.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)
            
        } catch {
            print("error generating csv file")
        }}

    func SetupEnv(){
        motionManager.accelerometerUpdateInterval = 0.01
        motionManager.gyroUpdateInterval = 0.01
        
        motionManager.startGyroUpdates()
        motionManager.startAccelerometerUpdates()
    }


    func CollectData() {

        
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            guard let acceleromotoData = self.manager.accelerometerData,
                  let gyroData = self.manager.gyroData else { return }
            
            let timestamp = Date()
            
            self.acc_dataset.append((acceleromotoData.acceleration.x, acceleromotoData.acceleration.y, acceleromotoData.acceleration.z))
            self.gyro_dataset.append((gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z))
           
            self.csv_data += "\(timestamp),\(acceleromotoData.acceleration.x),\(acceleromotoData.acceleration.y),\(acceleromotoData.acceleration.z),\(gyroData.rotationRate.x),\(gyroData.rotationRate.y),\(gyroData.rotationRate.z)\n"

              
            self.num_data += 1
            if self.num_data > self.max_data {
          
                self.manager.stopAccelerometerUpdates()
                self.manager.stopGyroUpdates()
                
                self.SaveData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SetupEnv()
        CollectData()
    }
}
