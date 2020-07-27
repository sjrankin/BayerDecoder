//
//  File.swift
//  BayerDecoder
//
//  Created by Stuart Rankin on 7/27/20.
//

import Foundation
import AppKit

/// NSImage extensions.
extension NSImage
{
    /// Write a file as a .png image.
    /// - Parameter ToURL: The URL where to write the file.
    /// - Returns: True on success, false on failure.
    @discardableResult public func WritePNG(ToURL: URL) -> Bool
    {
        guard let Data = tiffRepresentation,
              let Rep = NSBitmapImageRep(data: Data),
              let ImgData = Rep.representation(using: .png, properties: [.compressionFactor: NSNumber(floatLiteral: 1.0)]) else
        {
            print("Error getting data for image to save.")
            return false
        }
        do
        {
            try ImgData.write(to: ToURL)
        }
        catch
        {
            print("Error writing data: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    /// Write the image to a specified file whose name is passed.
    /// - Parameter To: The name of the file to write.
    /// - Parameter Options: File writing options. Defaults to `.atomic`.
    /// - Returns: True on success, false on failure.
    func Write(To FileName: String, Options: Data.WritingOptions = .atomic) -> Bool
    {
        do
        {
            try PngData?.write(to: URL(fileURLWithPath: FileName), options: Options)
            return true
        }
        catch
        {
            print("Write error: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Returns the instance's data as a `.png` representation.
    var PngData: Data?
    {
        guard let Tiff = tiffRepresentation,
              let BImage = NSBitmapImageRep(data: Tiff) else
        {
            return nil
        }
        return BImage.representation(using: .png, properties: [:])
    }
}

