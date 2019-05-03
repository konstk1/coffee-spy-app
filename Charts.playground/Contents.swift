import PlaygroundSupport
import UIKit
import Charts

let roast = MyRoast()
roast.loadSampleCsv()

// Line Data
let btLine = roast.btCurve.map { ChartDataEntry(x: $0.time, y: $0.temp) }
let btSet = LineChartDataSet(entries: btLine, label: "BT")
btSet.setColor(.green)
btSet.lineWidth = 2
btSet.drawCirclesEnabled = false
btSet.highlightLineDashLengths = [5, 2.5]

let etLine = roast.etCurve.map { ChartDataEntry(x: $0.time, y: $0.temp) }
let etSet = LineChartDataSet(entries: etLine, label: "ET")
etSet.setColor(.yellow)
etSet.lineWidth = 2
etSet.drawCirclesEnabled = false
btSet.highlightLineDashLengths = [5, 2.5]

let data = LineChartData(dataSets: [btSet, etSet])
data.setValueTextColor(.white)
data.setValueFont(.systemFont(ofSize: 9))

// Chart
let chartWidth = 400
let chartHeight = 300

let lineChart = LineChartView(frame: CGRect(x: 0, y: 0, width: chartWidth, height: chartHeight))
lineChart.data = data
lineChart.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 1, alpha: 1)
lineChart.xAxis.drawGridLinesEnabled = false
lineChart.xAxis.labelPosition = .bottom
lineChart.xAxis.labelTextColor = .white
lineChart.xAxis.valueFormatter = TimeFormatter()
lineChart.leftAxis.gridColor = .white
lineChart.leftAxis.labelTextColor = .white
lineChart.rightAxis.labelTextColor = .white
lineChart.rightAxis.drawGridLinesEnabled = false
lineChart.notifyDataSetChanged()
//lineChart.xAxis.valueFormatter

// View
let frame = CGRect(x: 0, y: 0, width: chartWidth, height: chartHeight)
let view = UIView(frame: frame)
view.backgroundColor = .white
view.addSubview(lineChart)

PlaygroundPage.current.liveView = view
PlaygroundPage.current.needsIndefiniteExecution = true

class TimeFormatter: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let mins = Int(value / 60)
        let secs = Int(value) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
