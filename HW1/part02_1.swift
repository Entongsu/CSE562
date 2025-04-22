import UIKit
import CoreMotion
import DGCharts

class ViewController: UIViewController {

    let manager = CMMotionManager()
    var start_timestamp: Date?

    let roll_chartview = LineChartView()
    let pitch_chartview = LineChartView()

    var roll_data: [ChartDataEntry] = []
    var pitch_data: [ChartDataEntry] = []
    var yaw_data: [ChartDataEntry] = []

    var all_data: [(x: Double, y: Double, z: Double, roll: Double, pitch: Double, yaw: Double)] = []
    var csv_data: String = "timestamp, acc_x, acc_y, acc_z, roll, pitch, yaw\n"

    var num_data: Double = 0

    func SetupChart(view: UIView, chart: LineChartView) {
        view.addSubview(chart)
        chart.rightAxis.enabled = true
        chart.legend.enabled = true
        chart.leftAxis.axisMinimum = -180
        chart.leftAxis.axisMaximum = 180
      
    }

    func SetupUIViewer() {
 

        roll_chartview.translatesAutoresizingMaskIntoConstraints = false
        pitch_chartview.translatesAutoresizingMaskIntoConstraints = false

        self.SetupChart(view: view, chart: roll_chartview)
        self.SetupChart(view: view, chart: pitch_chartview)
        var constraints = [NSLayoutConstraint]()
        constraints.append(roll_chartview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        constraints.append(roll_chartview.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(roll_chartview.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        constraints.append(roll_chartview.heightAnchor.constraint(equalTo: view.heightAnchor,multiplier:0.45))

        constraints.append(pitch_chartview.topAnchor.constraint(equalTo: roll_chartview.bottomAnchor))
        constraints.append(pitch_chartview.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        constraints.append(pitch_chartview.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        constraints.append(pitch_chartview.heightAnchor.constraint(equalTo: view.heightAnchor,multiplier:0.45))


        NSLayoutConstraint.activate(constraints)
    }

    func VizPlot(_ plot: LineChartDataSet, color: UIColor) {
        plot.setColor(color)
        plot.drawValuesEnabled = false
        plot.setCircleColor(color)
        plot.valueFormatter = DefaultValueFormatter(decimals: 1)
        plot.circleRadius = 3
        plot.lineWidth = 5
    }

    func UpdateViewer(name: String, data: [(x: Double, y: Double)]) {
        DispatchQueue.main.async {
            guard let point = data.first else { return }

            self.num_data += 1

            self.roll_data.append(ChartDataEntry(x: self.num_data, y: point.x))
            self.pitch_data.append(ChartDataEntry(x: self.num_data, y: point.y))

            if self.roll_data.count > 100 { self.roll_data.removeFirst() }
            if self.pitch_data.count > 100 { self.pitch_data.removeFirst() }

            let roll_plot = LineChartDataSet(entries: self.roll_data, label: "Roll Data")
            let pitch_plot = LineChartDataSet(entries: self.pitch_data, label: "Pitch Data")

            self.VizPlot(roll_plot, color:.systemRed)
            self.VizPlot(pitch_plot,  color:.systemBlue)

            self.roll_chartview.data = LineChartData(dataSet:roll_plot)
            self.pitch_chartview.data = LineChartData(dataSet:pitch_plot)

            self.roll_chartview.setVisibleXRangeMaximum(10)
            self.pitch_chartview.setVisibleXRangeMaximum(10)
            
        }
    }

    func SetupAccelerometer() {
        self.manager.accelerometerUpdateInterval = 0.01
        self.manager.startAccelerometerUpdates()
        start_timestamp = Date()
    }


    func SaveData() {
        var fileURL: URL!
        do {
            
            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)
            
            fileURL = path.appendingPathComponent("accelerometerdata01.csv")
            
            try csv_data.write(to: fileURL, atomically: true , encoding: .utf8)
            print(fileURL!)
            
        } catch {
            print("error generating csv file")
        }
    }

    func LivestreamAcclerometer() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            guard let accelerometerData = self.manager.accelerometerData,
                  let start_time = self.start_timestamp else { return }

            let running_time = Date().timeIntervalSince(start_time)
            if running_time >= 60 {
                self.manager.stopAccelerometerUpdates()
                self.SaveData()
                return
            }

            let acce_x = accelerometerData.acceleration.x
            let acce_y = accelerometerData.acceleration.y
            let acce_z = accelerometerData.acceleration.z
            let timestamp = Date().timeIntervalSince1970

            let roll = atan2(acce_y, acce_z) * 180 / .pi
            let pitch: Double = atan2(-acce_x, sqrt(acce_y * acce_y + acce_z * acce_z)) * 180 / .pi

           
            self.UpdateViewer(name: "rpy", data: [(x: roll, y: pitch)])
            self.all_data.append((acce_x, acce_y, acce_z, roll, pitch, 0.0))
            self.csv_data += "\(timestamp),\(acce_x),\(acce_y),\(acce_z),\(roll),\(pitch),0.0\n"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        SetupUIViewer()
        SetupAccelerometer()
        LivestreamAcclerometer()
    }
}