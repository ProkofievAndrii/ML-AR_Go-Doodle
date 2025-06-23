//
//  ResultsVC.swift
//  Go_Doodle
//
//  Created by Andrii Prokofiev on 15.06.2025.
//

import UIKit
import Vision
import CoreML

class ResultsVC: UIViewController {

    @IBOutlet private weak var player1ImageView: UIImageView!
    @IBOutlet private weak var player2ImageView: UIImageView!
    @IBOutlet private weak var player1ScoreLabel: UILabel!
    @IBOutlet private weak var player2ScoreLabel: UILabel!
    @IBOutlet private weak var versusLabel: UILabel!
    
    var player1ImageURL: URL?
    var player2ImageURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url1 = player1ImageURL {
            player1ImageView.image = UIImage(contentsOfFile: url1.path)
        }
        
        if let url2 = player2ImageURL {
            player2ImageView.image = UIImage(contentsOfFile: url2.path)
        }
        
        player1ScoreLabel.text = "Calculating..."
        player2ScoreLabel.text = "Calculating..."
        
        computeAndDisplayDistance()
    }
    
    private func computeAndDisplayDistance() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard
                let self = self,
                let url1 = self.player1ImageURL,
                let url2 = self.player2ImageURL,
                let dist = self.compareImages(at: url1, and: url2)
            else { return }

            let text = String(format: "%.3f", dist)
            DispatchQueue.main.async {
                self.animateSequence(with: text)
            }
        }
    }
}

//MARK: - Image comparison utils
extension ResultsVC {
    private func compareImages(at firstURL: URL, and secondURL: URL) -> Float? {
        guard let fpo1 = featurePrintObservation(for: firstURL) else { return nil }
        guard let fpo2 = featurePrintObservation(for: secondURL) else { return nil }
        
        var distance: Float = 0
        do {
            try fpo1.computeDistance(&distance, to: fpo2)
            return distance
        } catch {
            print("Error computing feature-print distance: \(error)")
            return nil
        }
    }
    
    private func featurePrintObservation(for url: URL) -> VNFeaturePrintObservation? {
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNGenerateImageFeaturePrintRequest()

        if #available(iOS 17.0, *) {
            for device in MLComputeDevice.allComputeDevices {
                if device.description.contains("MLCPUComputeDevice") {
                    request.setComputeDevice(device, for: .main)
                    break
                }
            }
        } else {
            request.usesCPUOnly = true
        }

        do {
            try handler.perform([request])
            return request.results?.first as? VNFeaturePrintObservation
        } catch {
            print("Vision error: \(error)")
            return nil
        }
    }
}

//MARK: - Animation Utils
extension ResultsVC {
    private func animateSequence(with scoreText: String) {
        animate(label: player1ScoreLabel, newText: scoreText) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.animate(label: self.versusLabel, newText: nil) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.animate(label: self.player2ScoreLabel, newText: scoreText)
                    }
                }
            }
        }
    }
    
    private func animate(label: UILabel, newText: String? = nil, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            if let txt = newText {
                label.text = txt
            }
            label.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { _ in
            UIView.animate(withDuration: 0.5, animations: {
                label.transform = .identity
            }) { _ in
                completion?()
            }
        }
    }
}
