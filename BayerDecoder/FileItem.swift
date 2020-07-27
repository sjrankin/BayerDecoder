//
//  FileItem.swift
//  BayerDecoder
//
//  Created by Stuart Rankin on 7/27/20.
//

import Foundation
import AppKit

/// Holds information about one item to convert.
class FileItem
{
    /// Initializer.
    /// - Parameter ImageURL: URL of the image to convert.
    /// - Parameter SourceImage: The original, unconverted image.
    init(_ ImageURL: URL, _ SourceImage: NSImage)
    {
        FileURL = ImageURL
        Source = SourceImage
        Converted = nil
        Saved = false
    }
    
    /// Holds the URL of the file.
    private var _FileURL: URL? = nil
    /// Get or set the URL of the file
    /// - Note: For some reason, this value is being set to nil somewhere. For that reason, it is stored
    ///         as a string elsewhere.
    public var FileURL: URL?
    {
        get
        {
            return _FileURL
        }
        set
        {
            _FileURL = newValue
            if let Path = _FileURL
            {
                FileURLPath = Path.path
            }
        }
    }
    
    /// The file's URL path.
    var FileURLPath: String = ""
    
    /// The source/unconverted image.
    var Source: NSImage? = nil
    
    /// The converted image. Nil if not converted.
    var Converted: NSImage? = nil
    
    /// The saved flag.
    var Saved: Bool = false
    
    /// Returns the name of the unconverted file.
    func GetFileName() -> String?
    {
        if let TheURL = URL(string: FileURLPath)
        {
            return TheURL.lastPathComponent
        }
        return nil
    }
    
    /// Returns `Source` in reverse order.
    /// - Parameter Source: The string to reverse.
    /// - Returns: String with the contents of `Source` in reverse order.
    func ReversedString(_ Source: String) -> String
    {
        let ReversedChars = Source.reversed()
        var Rev = ""
        for Char in ReversedChars
        {
            Rev.append(Char)
        }
        return Rev
    }
    
    /// Return a name to use for saving converted files.
    /// - Parameter With: The extension to use. Defaults to `png`. *Do not specify a leading period.*
    /// - Parameter Suffix: A string to append to the end of the file name to differentiate it from the
    ///                     source image. Defaults to `a`. If this value is an empty string, `a` is
    ///                     used anyway.
    /// - Returns: The name to use when saving the file. Nil on error.
    func SaveFileName(With Extension: String = "png", Suffix: String = "a") -> String?
    {
        if Extension.isEmpty
        {
            return nil
        }
        if let TheURL = URL(string: FileURLPath)
        {
            let Name = TheURL.lastPathComponent
            
            let RevName = ReversedString(Name)
            let Parts = RevName.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
            let FinalSuffix = Suffix.isEmpty ? "a" : Suffix
            let FinalName = ReversedString(String(Parts[1])) + FinalSuffix
            
            return "\(FinalName).\(Extension)"
        }
        return nil
    }
    
    /// Returns the directory of the source image file.
    /// - Returns: The directory of the source image file. Nil on error.
    func GetDirectory() -> String?
    {
        if let TheURL = URL(string: FileURLPath)
        {
            let Directory = TheURL.deletingLastPathComponent()
            return Directory.path
        }
        return nil

    }
}
