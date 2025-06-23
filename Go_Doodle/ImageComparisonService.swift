//
//  ImageComparisonService.swift
//  Go_Doodle
//
//  Created by Oleksandr Kataskin on 23.06.2025.
//

import Foundation
import UIKit
import Vision

final class ImageComparisonService {
    
    public static let shared = ImageComparisonService()
    
    func compare2Images(_ image1: UIImage, _ image2: UIImage) -> Float? {

        let img1 = process(image1)
        let img2 = process(image2)
        guard let img1, let img2 else { return nil }
        
        var distance: Float = .infinity
        try? img1.computeDistance(&distance, to: img2)
        return distance
    }
    
    func process(_ image: UIImage) -> VNFeaturePrintObservation? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateImageFeaturePrintRequest()
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Can't make the request due to \(error)")
        }
        
        guard let result = request.results?.first else { return nil }
        return result
    }
}
