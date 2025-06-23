//
//  SDPipeline.swift
//  Go_Doodle
//
//  Created by Oleksandr Kataskin on 17.06.2025.
//

import Foundation
import Combine
import StableDiffusion
import CoreML
import UIKit

enum SDInitState {
    case notLoaded
    case loading
    case loaded
    case failed
}

final class SDPipeline {
    
    @Published var initState: SDInitState = .notLoaded
    private var cancellables: Set<AnyCancellable> = []
    
    public let pipeline: StableDiffusionPipeline
    private var tasks: [() -> Void] = []
    public let queue = DispatchQueue(label: "sd-tasks-queue", qos: .background)
    
    init() {
        guard let modelsFolder = Bundle.main.resourceURL
        else {
            fatalError("Resources folder not found in bundle")
        }
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly
        
        let pipeline = try! StableDiffusionPipeline(
            resourcesAt:    modelsFolder,
            controlNet:     [],
            configuration:  config,
            disableSafety:  false,
            reduceMemory:   true
        )
        
        self.pipeline = pipeline
        
        loadResources()
        
    }
    
    
    private func runBackgroundTask(_ task: @escaping () -> Void) {
        queue.async {
            task()
        }
    }
    
    private func loadResources() {
        print("### LOADING RESOURCES")
        self.initState = .loading
        queue.async { [weak self] in
            do {
                try self?.pipeline.loadResources()
                DispatchQueue.main.async { [weak self] in
                    print("### RESOURCES LOADED")
                    self?.initState = .loaded
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    print("### RESOURCES FAILED TO LOAD")
                    self?.initState = .failed
                }
            }
        }
        
    }
}
