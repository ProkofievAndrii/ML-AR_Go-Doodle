//
//  ViewController.swift
//  Go_Doodle
//
//  Created by Andrii Prokofiev on 14.06.2025.
//

import UIKit
import PencilKit
import Combine
import StableDiffusion

class DrawingVC: UIViewController {
    
    private let diffuser: ImageDiffuser = ImageDiffuser()
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: UI instances
    private let canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        return canvas
    }()
    private var toolPicker = PKToolPicker()
    private let drawing = PKDrawing()
    
    private lazy var viewResultsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "list.bullet.rectangle"), for: .normal)
        btn.setTitle("Results", for: .normal)
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(viewResultsTapped), for: .touchUpInside)
        btn.isHidden = true
        btn.isEnabled = false
        return btn
    }()
    private lazy var viewResultsBarItem = UIBarButtonItem(customView: viewResultsButton)
    
    //MARK: Varibles
    private var currentPlayer = 1
    private var countdownTimer: Timer?
    private var secondsLeft = 30
    
    private var player1ImageURL: URL?
    private var player2ImageURL: URL?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(canvasView)
        setupUI()
        
        diffuser.$outputs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outputs in
                guard let fst = outputs[1],
                      let snd = outputs[2],
                      case .finished(let image1) = fst,
                      case .finished(let image2) = snd
                else { return }
                
                //TODO: Replace with image comparison instead of replacement. Image replacement is used for debugging.
                if let url1 = self?.saveImageLocally(image1, forPlayer: 1),
                   let url2 = self?.saveImageLocally(image2, forPlayer: 2)
                {
                    self?.player1ImageURL = url1
                    self?.player2ImageURL = url2
                    self?.viewResultsButton.isEnabled = true
                }
            }
            .store(in: &cancellables)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        canvasView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        playRoundSequence()
    }
}

//MARK: - Round sequence
extension DrawingVC {
    
    private func playRoundSequence() {
        let message = currentPlayer == 1
        ? "Player 1, get ready!"
        : "Player 2, get ready!"
        showToast(message, duration: 2.0)
        
        if currentPlayer == 2 {
            canvasView.drawing = PKDrawing()
        }
        
        canvasView.isUserInteractionEnabled = true
        navigationController?.navigationBar.isUserInteractionEnabled = true
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.startCountdown()
        }
    }
    
    private func startCountdown() {
        secondsLeft = 30
        showToast("30 seconds remaining", duration: 2.0)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.secondsLeft -= 1
            
            switch self.secondsLeft {
            case 10:
                self.showToast("10 seconds remaining", duration: 2.0)
            case 3, 2, 1:
                self.showToast("\(self.secondsLeft)", duration: 0.5)
            case 0:
                timer.invalidate()
                self.interruptDrawing()
                self.canvasView.isUserInteractionEnabled = false
                self.navigationController?.navigationBar.isUserInteractionEnabled = false
                self.saveImage()
                
                if self.currentPlayer < 2 {
                    self.currentPlayer += 1
                    self.playRoundSequence()
                } else {
                    self.showToast("Game over!", duration: 2.0)
                    navigationController?.navigationBar.isUserInteractionEnabled = true
                    viewResultsButton.isHidden = false
                }
            default:
                break
            }
        }
    }
    
    private func interruptDrawing() {
        canvasView.drawingGestureRecognizer.isEnabled = false
        canvasView.drawingGestureRecognizer.isEnabled = true
    }
}


//MARK: - UI config
extension DrawingVC {
    
    private func setupUI() {
        setupBarButtons()
        setupCanvasView()
    }
    
    private func setupCanvasView() {
        canvasView.drawing = drawing
    }
    
    private func setupBarButtons() {
        let eraseButton = UIButton(type: .system)
        eraseButton.setImage(UIImage(systemName: "eraser.fill"), for: .normal)
        eraseButton.setTitle(" Erase", for: .normal)
        eraseButton.sizeToFit()
        eraseButton.addTarget(self, action: #selector(eraseTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: eraseButton)
        
        navigationItem.rightBarButtonItem = viewResultsBarItem
    }
    
    @objc private func eraseTapped() {
        canvasView.drawing = PKDrawing()
    }
    
    @objc private func viewResultsTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let resultsVC = storyboard.instantiateViewController(
            withIdentifier: "resultsVC"
        ) as? ResultsVC else {
            fatalError("ResultsVC not found in Main.storyboard")
        }
        resultsVC.player1ImageURL = player1ImageURL
        resultsVC.player2ImageURL = player2ImageURL
        navigationController?.setViewControllers([resultsVC], animated: true)
    }
    
    private func saveImage() {
        saveImageToGallery()
        let image = canvasView.drawing.image(from: canvasView.bounds,
                                             scale: UIScreen.main.scale).resizedToPixels(width: 512, height: 512)
        
        diffuser.diffuseImage(input: image, index: currentPlayer)
        //        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        if let url = saveImageLocally(image, forPlayer: currentPlayer) {
            if currentPlayer == 1 {
                player1ImageURL = url
            } else {
                player2ImageURL = url
            }
        }
    }
    
    private func saveImageToGallery() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale).resizedToPixels(width: 512, height: 512)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func saveImageLocally(_ image: UIImage, forPlayer player: Int) -> URL? {
        guard let data = image.pngData() else { return nil }
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("player\(player)_drawing.png")
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            print("Error saving image for player \(player):", error)
            return nil
        }
    }
}

//MARK: - Utils
extension DrawingVC {
    //Custom Toast
    private func showToast(_ message: String, duration: TimeInterval) {
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.numberOfLines = 0
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.alpha = 0
        
        let maxWidth = view.bounds.width - 40
        let textSize = label.sizeThatFits(CGSize(width: maxWidth - 20, height: .greatestFiniteMagnitude))
        let width = min(maxWidth, textSize.width + 20)
        let height = textSize.height + 12
        label.frame = CGRect(
            x: (view.bounds.width - width) / 2,
            y: view.safeAreaInsets.top + 10,
            width: width,
            height: height
        )
        
        view.addSubview(label)
        
        UIView.animate(withDuration: 0.3, animations: {
            label.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
}
