//
//  BayerDecode.swift
//  BayerDecoder
//
//  Created by Stuart Rankin on 7/27/20.
//

import Foundation
import AppKit
import CoreMedia
import CoreVideo
import MetalKit

/// Wrapper around a Bayer decode Metal compute shader.
class BayerDecode
{
    /// The image device.
    private let ImageDevice = MTLCreateSystemDefaultDevice()
    
    /// Compute pipeline.
    private var ImageComputePipelineState: MTLComputePipelineState? = nil
    
    /// Image command queue.
    private lazy var ImageCommandQueue: MTLCommandQueue? =
        {
            return self.ImageDevice?.makeCommandQueue()
        }()
    
    /// Initializer.
    init()
    {
        let DefaultLibrary = ImageDevice?.makeDefaultLibrary()
        let KernelFunction = DefaultLibrary?.makeFunction(name: "BayerDecode")
        do
        {
            ImageComputePipelineState = try ImageDevice?.makeComputePipelineState(function: KernelFunction!)
        }
        catch
        {
            print("Error creating pipeline state: \(error.localizedDescription)")
        }
    }
    
    /// Decode the passed image using the specified pixel order and decoding method.
    /// - Parameter Image: The image to decode.
    /// - Parameter Order: The pixel order of the source image.
    /// - Parameter Method: The method to use to decode the image.
    /// - Returns: Decoded image on success, nil on failure.
    func Decode(_ Image: NSImage, Order: PixelOrders, Method: ColorMethods) -> NSImage?
    {
        let Parameter = BayerDecodeParameters(Order: simd_uint1(Order.rawValue),
                                              Method: simd_uint1(Method.rawValue))
        let Parameters = [Parameter]
        let ParameterBuffer = ImageDevice!.makeBuffer(length: /*MemoryLayout<ImageMergeParameters>.stride*/16, options: [])
        memcpy(ParameterBuffer!.contents(), Parameters, /*MemoryLayout<ImageMergeParameters>.stride*/16)
        
        let Decoded = MetalLibrary.MakeEmptyTexture(Size: Image.size, ImageDevice: ImageDevice!, ForWriting: true)
        var SourceCG: CGImage? = nil
        let Source = MetalLibrary.MakeTexture(From: Image, ImageDevice: ImageDevice!, AsCG: &SourceCG)
        
        let CommandBuffer = ImageCommandQueue?.makeCommandBuffer()
        let CommandEncoder = CommandBuffer?.makeComputeCommandEncoder()
        CommandEncoder?.setComputePipelineState(ImageComputePipelineState!)
        CommandEncoder?.setTexture(Source, index: 0)
        CommandEncoder?.setTexture(Decoded, index: 1)
        CommandEncoder?.setBuffer(ParameterBuffer, offset: 0, index: 0)

        let w = ImageComputePipelineState!.threadExecutionWidth
        let h = ImageComputePipelineState!.maxTotalThreadsPerThreadgroup / w
        let ThreadGroupCount = MTLSizeMake(w, h, 1)
        let ThreadGroups = MTLSize(width: Int(Image.size.width), height: Int(Image.size.height), depth: 1)
        
        ImageCommandQueue = ImageDevice?.makeCommandQueue()
        CommandEncoder?.dispatchThreadgroups(ThreadGroups, threadsPerThreadgroup: ThreadGroupCount)
        CommandEncoder?.endEncoding()
        CommandBuffer?.commit()
        CommandBuffer?.waitUntilCompleted()
        
        let ImageSize = CGSize(width: Decoded!.width, height: Decoded!.height)
        let ImageByteCount = Int(ImageSize.width * ImageSize.height * 4)
        let BytesPerRow = SourceCG!.width * 4
        var ImageBytes = [UInt8](repeating: 0, count: ImageByteCount)
        let ORegion = MTLRegionMake2D(0, 0, Int(ImageSize.width), Int(ImageSize.height))
        Decoded!.getBytes(&ImageBytes, bytesPerRow: BytesPerRow, from: ORegion, mipmapLevel: 0)
        
        let CIOptions = [CIImageOption.colorSpace: CGColorSpaceCreateDeviceRGB(),
                         CIContextOption.outputPremultiplied: true,
                         CIContextOption.useSoftwareRenderer: false] as! [CIImageOption: Any]
        let CImg = CIImage(mtlTexture: Decoded!, options: CIOptions)
        let CImgRep = NSCIImageRep(ciImage: CImg!)
        let Final = NSImage(size: ImageSize)
        Final.addRepresentation(CImgRep)
        return Final
    }
}
