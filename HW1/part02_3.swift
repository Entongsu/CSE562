import UIKit
import CoreMotion
import DGCharts

class ViewController: UIViewController {

    let manager = CMMotionManager()
    var start_timestamp: Date?

    let roll_chartview = LineChartView()
    let pitch_chartview = LineChartView()
    let yaw_chartview = LineChartView()

    var roll_data: [ChartDataEntry] = []
    var pitch_data: [ChartDataEntry] = []
    var yaw_data: [ChartDataEntry] = []

    var all_data: [(x: Double, y: Double, z: Double, roll: Double, pitch: Double, yaw: Double)] = []
    var cvs_data: String = "timestamp, acce_x, acce_y, acce_z, gyro_x, gyro_y, gyro_z, roll, pitch, yaw\n"

    var num_data: Double = 0.0

    var filtered_roll: Double = 0.0
    var filtered_pitch: Double = 0.0
    var filtered_yaw: Double = 0.0
    var last_timestamp: TimeInterval?
    let gain: Double = 0.98

    func SetupChart(view: UIView, chart: LineChartView) {
        view.addSubview(chart)
        chart.chartDescription.enabled = true
        chart.rightAxis.enabled = true
        chart.legend.enabled = true
        chart.leftAxis.axisMinimum = -180
        chart.leftAxis.axisMaximum = 180
        chart.noDataText = ""
    }

    func SetupUIViewer() {
        view.backgroundColor = .white

        roll_chartview.translatesAutoresizingMaskIntoConstraints = false
        pitch_chartview.translatesAutoresizingMaskIntoConstraints = false
        yaw_chartview.translatesAutoresizingMaskIntoConstraints = false

        self.SetupChart(view: view, chart: roll_chartview)
        self.SetupChart(view: view, chart: pitch_chartview)
        self.SetupChart(view: view, chart: yaw_chartview)

        var constraints = [NSLayoutConstraint]()
        constraints.append(roll_chartview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        constraints.append(roll_chartview.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(roll_chartview.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        constraints.append(roll_chartview.heightAnchor.constraint(equalTo: view.heightAnchor,multiplier:0.30))

        constraints.append(pitch_chartview.topAnchor.constraint(equalTo: roll_chartview.bottomAnchor))
        constraints.append(pitch_chartview.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(pitch_chartview.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        constraints.append(pitch_chartview.heightAnchor.constraint(equalTo: view.heightAnchor,multiplier:0.30))


        constraints.append(yaw_chartview.topAnchor.constraint(equalTo: pitch_chartview.bottomAnchor))
        constraints.append(yaw_chartview.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(yaw_chartview.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        constraints.append(yaw_chartview.heightAnchor.constraint(equalTo: view.heightAnchor,multiplier:0.30))

        NSLayoutConstraint.activate(constraints)

    }

    func VizPlot(_ plot: LineChartDataSet, color: UIColor) {
        plot.setColor(color)
        plot.drawValuesEnabled = false
        plot.circleRadius = 2
        plot.setCircleColor(color)
        plot.valueFormatter = DefaultValueFormatter(decimals: 1)
        plot.lineWidth = 2
    }

    func UpdateViewer(name: String, data: [(x: Double, y: Double, z: Double)]) {
        DispatchQueue.main.async {
            guard let point = data.first else { return }

            self.num_data += 1
            self.roll_data.append(ChartDataEntry(x: self.num_data, y: point.x))
            self.pitch_data.append(ChartDataEntry(x: self.num_data, y: point.y))
            self.yaw_data.append(ChartDataEntry(x: self.num_data, y: point.z))

            if self.roll_data.count > 100 { self.roll_data.removeFirst() }
            if self.pitch_data.count > 100 { self.pitch_data.removeFirst() }
            if self.yaw_data.count > 100 { self.yaw_data.removeFirst() }

            let roll_plot = LineChartDataSet(entries: self.roll_data, label: "Roll Data")
            let pitch_plot = LineChartDataSet(entries: self.pitch_data, label: "Pitch Data")
            let yaw_plot = LineChartDataSet(entries: self.yaw_data, label: "Yaw Data")

            self.VizPlot(roll_plot, color: .systemRed)
            self.VizPlot(pitch_plot, color: .systemBlue)
            self.VizPlot(yaw_plot, color: .systemOrange)

            self.roll_chartview.data = LineChartData(dataSet: roll_plot)
            self.pitch_chartview.data = LineChartData(dataSet: pitch_plot)
            self.yaw_chartview.data = LineChartData(dataSet: yaw_plot)

            self.roll_chartview.setVisibleXRangeMaximum(10)
           
            self.pitch_chartview.setVisibleXRangeMaximum(10)
            
            self.yaw_chartview.setVisibleXRangeMaximum(10)
        
        }
    }


     func SaveData(){
        var fileURL: URL!
        do {
            
            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)
            
            fileURL = path.appendingPathComponent("filter01.csv")
            
            try self.cvs_data.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)
            
        } catch {
            print("error generating csv file")
        }}


    func SetupEnv() {
        manager.gyroUpdateInterval = 0.01
        manager.accelerometerUpdateInterval = 0.01
        manager.startGyroUpdates()
        manager.startAccelerometerUpdates()
        start_timestamp = Date()
    }

  

    func Livestream() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            guard let gyro_data = self.manager.gyroData,
                  let acc_data = self.manager.accelerometerData,
                  let start_time = self.start_timestamp else { return }
            
            let running_time = Date().timeIntervalSince(start_time)
                
            if running_time >= 60 {
                self.manager.stopAccelerometerUpdates()
                self.manager.stopGyroUpdates()
                self.SaveData()
                return
            }

            let current_timestamp: Double = Date().timeIntervalSince1970
            let dt = current_timestamp - (self.last_timestamp ?? (current_timestamp - 0.01))
            
            self.last_timestamp = current_timestamp

        

            let acc_x = acc_data.acceleration.x
            let acc_y = acc_data.acceleration.y
            let acc_z = acc_data.acceleration.z

            let acc_roll = atan2(acc_y, acc_z) * 180 / .pi
            let acc_pitch = atan2(-acc_x, sqrt(acc_y * acc_y + acc_z * acc_z)) * 180 / .pi

            self.filtered_roll = self.gain * (self.filtered_roll + gyro_data.rotationRate.x * dt * 180 / .pi) + (1 - self.gain) * acc_roll
            self.filtered_pitch = self.gain * (self.filtered_pitch + gyro_data.rotationRate.y * dt * 180 / .pi) + (1 - self.gain) * acc_pitch
            self.filtered_yaw = self.filtered_yaw + gyro_data.rotationRate.z * dt * 180 / .pi 



            self.UpdateViewer(name: "rpy", data: [(x: self.filtered_roll, y: self.filtered_pitch, z: self.filtered_yaw)])
            
            self.cvs_data += "\(current_timestamp),\(acc_x),\(acc_y),\(acc_z),\( gyro_data.rotationRate.x),\(gyro_data.rotationRate.y),\(gyro_data.rotationRate.z ),\(self.filtered_roll),\(self.filtered_pitch),\(self.filtered_yaw)\n"

            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        SetupUIViewer()
        SetupEnv()
        Livestream()
    }
}