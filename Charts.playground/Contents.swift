import PlaygroundSupport
import UIKit
import Charts

let roast = MyRoast()
roast.loadSampleCsv()

// Line Data
let btLine = roast.btCurve.map { ChartDataEntry(x: $0.time, y: $0.temp) }
let btSet = LineChartDataSet(entries: btLine, label: "BT")

let etLine = roast.etCurve.map { ChartDataEntry(x: $0.time, y: $0.temp) }
let etSet = LineChartDataSet(entries: etLine, label: "ET")

// Chart
let chartWidth = 500
let chartHeight = 300

let chartView = LineChartView(frame: CGRect(x: 0, y: 0, width: chartWidth, height: chartHeight))

setupLineChart()

// View
let frame = CGRect(x: 0, y: 0, width: chartWidth, height: chartHeight)
let view = UIView(frame: frame)
view.backgroundColor = .white
view.addSubview(chartView)

PlaygroundPage.current.liveView = view
PlaygroundPage.current.needsIndefiniteExecution = true

class TimeFormatter: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return value.asMinSecString()
    }
}

func setupLineChart() {
    // BT line
    //    let btSet = LineChartDataSet(entries: nil, label: "BT")
    btSet.setColor(.green)
    btSet.lineWidth = 2
    btSet.drawCirclesEnabled = false
    btSet.highlightLineDashLengths = [5, 2.5]
    btSet.drawValuesEnabled = false
    btSet.axisDependency = .left
    
    // ET line
    //    let etSet = LineChartDataSet(entries: nil, label: "ET")
    etSet.setColor(.yellow)
    etSet.lineWidth = 2
    etSet.drawCirclesEnabled = false
    etSet.highlightLineDashLengths = [5, 2.5]
    etSet.drawValuesEnabled = false
    etSet.axisDependency = .left
    
    let data = LineChartData(dataSets: [btSet, etSet])
    
    // chart
    chartView.data = data
    chartView.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 1, alpha: 1)
    chartView.doubleTapToZoomEnabled = false
    
    // legend
    chartView.legend.textColor = .white
    chartView.legend.horizontalAlignment = .right
    chartView.legend.verticalAlignment = .top
    chartView.legend.drawInside = true
    
    // x axis
    chartView.xAxis.axisMinimum = 0
    chartView.xAxis.axisMaximum = 15 * 60
    chartView.xAxis.labelCount = 16
    chartView.xAxis.forceLabelsEnabled = true
    chartView.xAxis.labelPosition = .bottom
    chartView.xAxis.labelTextColor = .white
    chartView.xAxis.valueFormatter = TimeFormatter()
    chartView.xAxis.drawGridLinesEnabled = true
    chartView.xAxis.gridLineWidth = 0.2
    chartView.xAxis.gridLineDashLengths = [5, 4]
    chartView.xAxis.gridColor = .white
    
    // left y axis
    chartView.leftAxis.axisMinimum = 0.0
    chartView.leftAxis.axisMaximum = 500.0
    chartView.leftAxis.labelCount = 10
    chartView.leftAxis.gridColor = .white
    chartView.leftAxis.labelTextColor = .white
    
    // right y axis
    chartView.rightAxis.axisMinimum = 0.0
    chartView.rightAxis.axisMaximum = 50.0
    chartView.rightAxis.labelTextColor = .white
    chartView.rightAxis.drawGridLinesEnabled = false
    
    chartView.notifyDataSetChanged()
}
