//
//  RoastChartConfig.swift
//  coffee-spy
//
//  Created by Konstantin Klitenik on 6/19/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import UIKit
import Charts

extension LineChartView {
    /// Modifies view with various chart configs for roast chart
    func configRoastChart() {
        // BT line
        let btSet = LineChartDataSet(entries: nil, label: "BT")
        btSet.setColor(.green)
        btSet.lineWidth = 2
        btSet.drawCirclesEnabled = false
        btSet.highlightLineDashLengths = [5, 2.5]
        btSet.drawValuesEnabled = false
        btSet.axisDependency = .left
        
        let deltaBtSet = btSet.copy() as! LineChartDataSet
        deltaBtSet.label = "ΔBT"
        deltaBtSet.setColor(.white)
        deltaBtSet.axisDependency = .right
        
        // ET line
        let etSet = LineChartDataSet(entries: nil, label: "ET")
        etSet.setColor(.yellow)
        etSet.lineWidth = 2
        etSet.drawCirclesEnabled = false
        etSet.highlightLineDashLengths = [5, 2.5]
        etSet.drawValuesEnabled = false
        etSet.axisDependency = .left
        
        // add data sets in specified order (later datasets are drawn on top)
        let dataSets: [IChartDataSet] = RoastDataSetIndex.allCases.map {
            switch $0 {
            case .bt:
                return btSet
            case .deltaBt:
                return deltaBtSet
            case .et:
                return etSet
            }
        }
        let data = LineChartData(dataSets: dataSets)
        
        // chart
        self.data = data
        
        self.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 1, alpha: 0)
        self.doubleTapToZoomEnabled = false
        
        // legend
        self.legend.textColor = .white
        self.legend.horizontalAlignment = .right
        self.legend.verticalAlignment = .top
        self.legend.drawInside = true
        
        // x axis
        self.xAxis.axisMinimum = 0
        self.xAxis.axisMaximum = 15 * 60
        self.xAxis.labelCount = 16
        self.xAxis.forceLabelsEnabled = true
        self.xAxis.labelPosition = .bottom
        self.xAxis.labelTextColor = .white
        self.xAxis.valueFormatter = TimeFormatter()
        self.xAxis.drawGridLinesEnabled = true
        self.xAxis.gridColor = .white
        self.xAxis.gridLineWidth = 0.2
        self.xAxis.gridLineDashLengths = [5, 4]
        
        // left y axis
        self.leftAxis.axisMinimum = 0.0
        self.leftAxis.axisMaximum = 500.0
        self.leftAxis.labelCount = 10
        self.leftAxis.gridColor = .white
        self.leftAxis.labelTextColor = .white
        
        // right y axis
        self.rightAxis.axisMinimum = 0.0
        self.rightAxis.axisMaximum = 50.0
        self.rightAxis.labelTextColor = .white
        self.rightAxis.drawGridLinesEnabled = false
    }
}

class TimeFormatter: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return value.asMinSecString()
    }
}

/// Indecies for chart data sets.  Later cases are plotted on top of earlier cases.
/// Don't assign integer values, let compiler assign them sequentially.
enum RoastDataSetIndex: Int, CaseIterable {
    case deltaBt
    case bt
    case et
}
