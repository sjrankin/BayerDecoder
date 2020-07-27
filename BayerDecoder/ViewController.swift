//
//  ViewController.swift
//  BayerDecoder
//
//  Created by Stuart Rankin on 7/27/20.
//

import Cocoa

/// Main view for the Bayer decode program.
class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource
{
    /// Initialize the UI to known values.
    override func viewDidLoad()
    {
        super.viewDidLoad()
        ConvertOnDropSwitch.state = .on
        SaveOnConvertSwitch.state = .on
        StatusLabel.stringValue = ""
    }
    
    /// Get the main window and initialize it - mainly setting up the progress indicator.
    override func viewDidLayout()
    {
        Main = view.window?.windowController as? MainWindow
        Main?.SetProgressColor(To: NSColor.systemRed)
    }
    
    /// Holds the main window.
    var Main: MainWindow? = nil
    
    /// Pixel order for Bayer decoding.
    var PixelOrder: PixelOrders = .RGGB
    
    /// How to perform Bayer decoding.
    var ColorMethod: ColorMethods = .NearestNeighbor
    
    /// Holds the list of items to convert.
    var FileList = [FileItem]()
    
    /// Xcode-generated function.
    override var representedObject: Any?
    {
        didSet
        {
            // Update the view, if already loaded.
        }
    }
    
    /// Open files via a menu or button press.
    @IBAction func OpenFiles(_ sender: Any)
    {
        let OpenPanel = NSOpenPanel()
        OpenPanel.title = "Select Files to Convert"
        OpenPanel.allowsMultipleSelection = true
        OpenPanel.allowedFileTypes = ["png", "jpg"]
        OpenPanel.level = .modalPanel
        if OpenPanel.runModal() == .OK
        {
            PopulateFileListWith(OpenPanel.urls)
        }
    }
    
    /// Given a list of URLs, populate the file list with information.
    /// - Parameter URLs: List of URLs to use to populate the file list.
    func PopulateFileListWith(_ URLs: [URL])
    {
        if HaveUnsavedImages()
        {
            print("Found unsaved images.")
        }
        FileList.removeAll()
        for SomeURL in URLs
        {
            let Image = NSImage(byReferencing: SomeURL)
            let NewFile = FileItem(SomeURL, Image)
            FileList.append(NewFile)
        }
        SourceTable.reloadData()
    }
    
    /// Determines if any images are unsaved in the file list.
    /// - Returns: True if at least one image in the file list is unsaved, false if all are saved.
    func HaveUnsavedImages() -> Bool
    {
        for File in FileList
        {
            if !File.Saved
            {
                return true
            }
        }
        return false
    }
    
    /// Save the currently selected item (in the file list table view) if it has been converted.
    /// - Parameter sender: Not used.
    @IBAction func HandleSaveImageButton(_ sender: Any)
    {
        if let CurrentItem = CurrentlySelectedItem
        {
            SaveFileItem(CurrentItem)
        }
    }
    
    /// Save a file item. If the file item has not been converted or has already been saved, no action
    /// is taken.
    /// - Parameter Item: The item to save.
    /// - Parameter Count: If not zero, the value to set the progress indicator to. If zero, no action
    ///                    is taken.
    /// - Returns: True if the item was saves, false if not (for any reason).
    @discardableResult func SaveFileItem(_ Item: FileItem, Count: Int = 0) -> Bool
    {
        if Item.Converted == nil
        {
            StatusLabel.stringValue = "Item not converted."
            return false
        }
        if Item.Saved
        {
            StatusLabel.stringValue = "Already saved."
            return false
        }
        let Directory = Item.GetDirectory()
        let SaveName = Item.SaveFileName()
        let FinalPath = Directory! + "/" + SaveName!
        if ((Item.Converted?.Write(To: FinalPath)) != nil)
        {
            Item.Saved = true
            StatusLabel.stringValue = "\(SaveName!) saved OK"
            return true
        }
        return false
    }
    
    /// Handle the save all images button press or menu command.
    /// - Parameter sender: Not used.
    @IBAction func HandleSaveAllImages(_ sender: Any)
    {
        Main?.InitializeProgress(0.0, Double(FileList.count))
        Main?.SetProgressColor(To: NSColor.systemBlue)
        var Count = 0
        for Item in FileList
        {
            Count = Count + 1
            Main?.SetProgressValue(To: Double(Count))
            SaveFileItem(Item, Count: Count)
        }
        StatusLabel.stringValue = "Save \(FileList.count) images."
    }
    
    /// Returns the number of items to display in the file list table view.
    /// - Parameter in: The table view where the file list will be displayed.
    /// - Returns: Number of items in the file list.
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return FileList.count
    }
    
    /// Returns the height of each row in the file list table view.
    /// - Parameter tableView: The table view whose row height will be returned.
    /// - Paraemter heightOfRow: The row whose height will be returned. Not used.
    /// - Returns: The height of the specified row.
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return 100.0
    }
    
    /// Returns values for the file list table view.
    /// - Parameter tableView: The table view being populated.
    /// - Parameter viewFor: The column of the table view being populated.
    /// - Parameter row: Row of the table view being populated.
    /// - Returns: View for the specified row and column in the specified table view.
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        var CellContents = ""
        var CellIdentifier = ""
        var ToolTip = ""
        
        if tableColumn == tableView.tableColumns[0]
        {
            CellIdentifier = "ImageNameColumn"
            if let FileName = FileList[row].GetFileName()
            {
                CellContents = FileName
                ToolTip = FileName
            }
            else
            {
                CellContents = "??"
                ToolTip = "No file name available"
            }
        }
        if tableColumn == tableView.tableColumns[1]
        {
            let IView = NSImageView(frame: NSRect(x: 1, y: 1, width: 96, height: 96))
            let ShowDecoded = TableDecodedButton.state == .on
            if ShowDecoded
            {
                ToolTip = "No decoded image available"
                if let Decoded = FileList[row].Converted
                {
                    ToolTip = "Decoded image"
                    IView.image = Decoded
                }
            }
            else
            {
                ToolTip = "Unable to load image"
                if let Image = FileList[row].Source
                {
                    ToolTip = "Source image to convert"
                    IView.image = Image
                }
            }
            return IView
        }
        
        let Cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: CellIdentifier), owner: self) as? NSTableCellView
        Cell?.textField?.stringValue = CellContents
        Cell?.toolTip = ToolTip
        return Cell
    }
    
    /// Handle selection changes in the file list table view.
    /// - Parameter notification: Not used.
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        HandleSelectedItems()
    }
    
    /// Handle selection changes in the file list table view. If there are no selected items or multiple
    /// selected items, the current view is cleared. Otherwise, it is populted with the selected item.
    func HandleSelectedItems()
    {
        StatusLabel.stringValue = ""
        let SelectedSet = SourceTable.selectedRowIndexes
        let SelectedRows = SelectedSet.map{$0}
        if SelectedRows.isEmpty || SelectedRows.count > 1
        {
            StatusLabel.stringValue = ""
            CurrentlySelectedItem = nil
            ConvertedImageView.image = nil
            ShowDecodedButton.isEnabled = false
            SaveImageButton.isEnabled = false
            SaveAllImagesButton.isEnabled = SelectedRows.isEmpty ? false : true
        }
        else
        {
            CurrentlySelectedItem = FileList[SelectedRows[0]]
            var Image: NSImage = NSImage()
            if ShowDecodedButton.state == .on
            {
                if let FinalImage = CurrentlySelectedItem?.Converted
                {
                Image = FinalImage
                }
                else
                {
                    if let SourceImage = CurrentlySelectedItem?.Source
                    {
                        Image = SourceImage
                        StatusLabel.stringValue = "Not converted yet."
                    }
                }
                ConvertedImageView.image = Image
            }
            else
            {
                if let SourceImage = CurrentlySelectedItem?.Source
                {
                    ConvertedImageView.image = SourceImage
                }
                else
                {
                    StatusLabel.stringValue = "No source image available."
                }
            }
        }
    }
    
    /// The currently selected item in the file item table view.
    var CurrentlySelectedItem: FileItem? = nil
    
    /// Handle the convert selected file item button pressed.
    /// - Parameter sender: Not used.
    @IBAction func HandleConvertButtonPressed(_ sender: Any)
    {
        let SelectedRowIndices = SourceTable.selectedRowIndexes
        let SelectedRows = SelectedRowIndices.map{$0}
        if !SelectedRows.isEmpty
        {
            let Decoder = BayerDecode()
            for Row in SelectedRows
            {
                if FileList[Row].Converted != nil
                {
                    print("Already converted \(FileList[Row].GetFileName()!)")
                }
                else
                {
                    if let DecodeMe = FileList[Row].Source
                    {
                        if let Decoded = Decoder.Decode(DecodeMe, Order: PixelOrder, Method: ColorMethod)
                        {
                            FileList[Row].Converted = Decoded
                        }
                    }
                    else
                    {
                        print("No image available for \(FileList[Row].FileURLPath)")
                    }
                }
            }
        }
        SourceTable.reloadData()
    }
    
    /// Handle the convert all images button pressed. Images that have already been converted are
    /// reconverted.
    /// - Parameter: sender: Not used.
    @IBAction func HandleConvertAllButtonPressed(_ sender: Any)
    {
        Main?.InitializeProgress(0.0, Double(FileList.count))
        Main?.SetProgressColor(To: NSColor.systemOrange)
        let Decoder = BayerDecode()
        var Count = 0
        for Item in FileList
        {
            Count = Count + 1
            Main?.SetProgressValue(To: Double(Count))
            if Item.Converted == nil
            {
                if let DecodeMe = Item.Source
                {
                    if let Decoded = Decoder.Decode(DecodeMe, Order: PixelOrder, Method: ColorMethod)
                    {
                        Item.Converted = Decoded
                    }
                }
            }
        }
        SourceTable.reloadData()
    }
    
    /// Handle changes to the show decoded/original image for the current image.
    /// - Parameter sender: Not used.
    @IBAction func HandleShowDecodedButtonChanged(_ sender: Any)
    {
        HandleSelectedItems()
    }
    
    /// Handle changes to the show decoded/original image for all images in the file item table view.
    /// - Parameter sender: Not used.
    @IBAction func HandleTableDecodedButtonChanged(_ sender: Any)
    {
        SourceTable.reloadData()
    }
    
    /// Handle changes to the pixel order for when images are decoded.
    /// - Parameter sender: Not used.
    @IBAction func HandlePixelOrderChanged(_ sender: Any)
    {
        if let Segment = sender as? NSSegmentedControl
        {
            switch Segment.selectedSegment
            {
                case 0:
                    PixelOrder = .RGGB
                    
                case 1:
                    PixelOrder = .BGGR
                    
                default:
                    PixelOrder = .RGGB
            }
        }
    }
    
    /// Handle changes to the decoding method for when images are decoded.
    /// - Parameter sender: Not used.
    @IBAction func HandleMethodChanged(_ sender: Any)
    {
        if let Combo = sender as? NSComboBox
        {
            switch Combo.indexOfSelectedItem
            {
                case 0:
                    ColorMethod = .NearestNeighbor
                    
                case 1:
                    ColorMethod = .PixelMean5x5
                    
                default:
                    ColorMethod = .NearestNeighbor
            }
        }
    }
    
    @IBOutlet weak var TableDecodedButton: NSButton!
    @IBOutlet weak var ShowDecodedButton: NSButton!
    @IBOutlet weak var ConvertAllButton: NSButton!
    @IBOutlet weak var ConvertButton: NSButton!
    @IBOutlet weak var ConvertedImageView: NSImageView!
    @IBOutlet weak var StatusLabel: NSTextField!
    @IBOutlet weak var SaveOnConvertSwitch: NSSwitch!
    @IBOutlet weak var ConvertOnDropSwitch: NSSwitch!
    @IBOutlet weak var SourceTable: NSTableView!
    @IBOutlet weak var SaveAllImagesButton: NSButton!
    @IBOutlet weak var SaveImageButton: NSButton!
}

/// List of pixel orders for Bayer decoding.
enum PixelOrders: Int
{
    /// In order: UL=Red, UR=Green, LL=Green, LR=Blue
    case RGGB = 0
    /// In oder: UL=Blue, UR=Green, LL=Green, LR=Red
    case BGGR = 1
}

/// Ways to convert from Bayer-encoded images to decoded images.
enum ColorMethods: Int
{
    /// Nearest neighbor.
    case NearestNeighbor = 0
    /// Pixel mean in a 5x5 matrix.
    case PixelMean5x5 = 1
}
