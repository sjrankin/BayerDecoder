//
//  MainWindow.swift
//  BayerDecoder
//
//  Created by Stuart Rankin on 7/27/20.
//

import Foundation
import AppKit

class MainWindow: NSWindowController
{
    /// Initialize the window and the UI.
    override func windowDidLoad()
    {
        super.windowDidLoad()
        InitializeProgress(0.0, 100.0)
    }
    
    /// Initialize the progress indicator.
    /// - Parameter Minimum: Minimum value for the indicator.
    /// - Parameter Maximum: Maximum value for the indicator.
    /// - Parameter NewValue: New current value for the indicator. Defaults to `0.0`.
    func InitializeProgress(_ Minimum: Double, _ Maximum: Double, _ NewValue: Double = 0.0)
    {
        ProgressIndicator.minValue = Minimum
        ProgressIndicator.maxValue = Maximum
        ProgressIndicator.doubleValue = NewValue
    }
    
    /// Sets the progress indicator value to the passed value.
    /// - Parameter To: The new progress indicator value.
    func SetProgressValue(To NewValue: Double)
    {
        ProgressIndicator.doubleValue = NewValue
    }
    
    /// Sets the color of the progress indicator control.
    /// Parameter To: the color to set the progress indicator control to.
    func SetProgressColor(To Color: NSColor)
    {
        let MonoColor = CIFilter(name: "CIColorMonochrome", parameters: [kCIInputColorKey: CIColor(color: Color) as Any])
        ProgressIndicator.contentFilters = [MonoColor!]
    }
    
    @IBOutlet weak var ProgressIndicator: NSProgressIndicator!
}
