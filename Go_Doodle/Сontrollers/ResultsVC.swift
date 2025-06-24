//
//  ResultsVC.swift
//  Go_Doodle
//
//  Created by Andrii Prokofiev on 15.06.2025.
//

import UIKit
import Vision
import CoreML
import Combine

class ResultsVC: UIViewController {

    @IBOutlet private weak var player1InitialImageView: UIImageView!
    @IBOutlet private weak var player1AugmentedImageView: UIImageView!
    @IBOutlet private weak var player1ProgressView: UIProgressView!
    @IBOutlet private weak var player2InitialImageView: UIImageView!
    @IBOutlet private weak var player2AugmentedImageView: UIImageView!
    @IBOutlet private weak var player2ProgressView: UIProgressView!
    @IBOutlet private weak var player1ScoreLabel: UILabel!
    @IBOutlet private weak var player2ScoreLabel: UILabel!
    @IBOutlet private weak var versusLabel: UILabel!
    
    var diffuser: ImageDiffuser? = nil
    var cancellables: Set<AnyCancellable> = []
    
    var player1ImageURL: URL?
    var player2ImageURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url1 = player1ImageURL {
            player1InitialImageView.image = UIImage(contentsOfFile: url1.path)
        }
        
        if let url2 = player2ImageURL {
            player2InitialImageView.image = UIImage(contentsOfFile: url2.path)
        }
        
        
        player1ProgressView.progress = 0
        player2ProgressView.progress = 0
        
        diffuser?.$outputs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outputs in
                
                guard let fst = outputs[1],
                      let snd = outputs[2]
                else { return }
                
                switch fst {
                case .progress(let progress):
                    let step = progress.step
                    let total = progress.stepCount
                    let percentage = Float(step) / Float(total)
                    self?.player1ProgressView.progress = percentage
                    //TODO: self?.progressBar1 = percentage
                case .finished(let image):
                    //TODO: self?.augmentedImage1 = image
                    self?.player1AugmentedImageView.image = image
                default: break
                }
                
                switch snd {
                case .progress(let progress):
                    let step = progress.step
                    let total = progress.stepCount
                    let percentage = Float(step) / Float(total)
                    self?.player2ProgressView.progress = percentage
                    //TODO: self?.progressBar1 = percentage
                case .finished(let image):
                    //TODO: self?.augmentedImage1 = image
                    self?.player2AugmentedImageView.image = image
                    self?.computeAndDisplayDistance()
                    //TODO: self?.stableDiffusionFinishedWork = true
                default: break
                }
                
            }
            .store(in: &cancellables)

        
        player1ScoreLabel.text = "Calculating..."
        player2ScoreLabel.text = "Calculating..."
    }
    
    private func computeAndDisplayDistance() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard
                let self = self,
                let initialUrl1 = self.player1ImageURL,
                let initialUrl2 = self.player2ImageURL,
                let augmentedImage1 = player1AugmentedImageView.image,
                let augmentedImage2 = player2AugmentedImageView.image,
                let dist1 = self.compareImages(at: initialUrl1, and: augmentedImage1),
                let dist2 = self.compareImages(at: initialUrl2, and: augmentedImage2)
            else { return }

            let text1 = String(format: "%.3f", dist1)
            let text2 = String(format: "%.3f", dist1)
            DispatchQueue.main.async {
//                self.animateSequence(with: text)
                self.player1ScoreLabel.text = text1
                self.player2ScoreLabel.text = text2
            }
        }
    }
}

//MARK: - Image comparison utils
extension ResultsVC {
    private func compareImages(at firstURL: URL, and secondURL: URL) -> Float? {
        guard
            let firstImage = UIImage(contentsOfFile: firstURL.path),
            let secondImage = UIImage(contentsOfFile: secondURL.path)
        else {
            return nil
        }
        return ImageComparisonService.shared.compare2Images(firstImage, secondImage)
    }
    
    private func compareImages(at url: URL, and image: UIImage) -> Float? {
        guard let firstImage = UIImage(contentsOfFile: url.path) else {
                return nil
            }
        return ImageComparisonService.shared.compare2Images(firstImage, image)
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
