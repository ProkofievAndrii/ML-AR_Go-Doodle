//
//  ImageDiffuser.swift
//  Go_Doodle
//
//  Created by Oleksandr Kataskin on 17.06.2025.
//

import Foundation
import UIKit
import StableDiffusion
import CoreML

enum DiffusionProgress {
    case notStarted
    case progress(PipelineProgress)
    case finished(UIImage)
    case failed
}


final class ImageDiffuser {
    private let pipeline: SDPipeline = SDPipeline()
    
    @Published var outputs: [Int : DiffusionProgress] = [:]

    func diffuseImage(input: UIImage, index: Int) {

        guard let cg = input.cgImage else {
            self.outputs[index] = .failed
            return
        }
        pipeline.queue.async { [weak self] in
            print("### STARTED DIFFUSION")
            do {
                var pcfg = StableDiffusionPipeline.Configuration(prompt: "sketch drawing of a shark")
                pcfg.stepCount     = 20
                pcfg.guidanceScale = 30
                pcfg.imageCount    = 1
                pcfg.seed          = .random(in: 0..<UInt32.max)
                pcfg.targetSize    = 512
                
                pcfg.startingImage = cg
                pcfg.strength      = 0.67
                
                let images = try self?.pipeline.pipeline.generateImages(configuration: pcfg) { progress in
                    print("### DIFFUSION PROGRESS \(progress.step)/\(progress.stepCount)")
                    DispatchQueue.main.async { [weak self] in
                        self?.outputs[index] = .progress(progress)
                    }
                    return true
                }
                
                let imagesMapped = images?.compactMap { $0 }
                guard let cgOutput = imagesMapped?.first
                else {
                    self?.outputs[index] = .failed
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    print("### DIFFUSION SUCCEEDED")
                    self?.outputs[index] = .finished(UIImage(cgImage: cgOutput))
                }
                
            } catch {
                DispatchQueue.main.async { [weak self] in
                    print("### DIFFUSION FAILED: \(error)")
                    self?.outputs[index] = .failed
                    return
                }
            }
        }
    }
}
