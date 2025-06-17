//
//  UIImage.swift
//  Go_Doodle
//
//  Created by Oleksandr Kataskin on 17.06.2025.
//

import Foundation
import UIKit

extension UIImage {

    func resizedToPixels(width: Int, height: Int) -> UIImage {
            let targetSize = CGSize(width: CGFloat(width), height: CGFloat(height))
            
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = false
            
            let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
            
            return renderer.image { _ in
                self.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
}
