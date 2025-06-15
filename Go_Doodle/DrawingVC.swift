//
//  ViewController.swift
//  Go_Doodle
//
//  Created by Andrii Prokofiev on 14.06.2025.
//

import UIKit
import PencilKit

class DrawingVC: UIViewController {
    
    // MARK: UI instances & variables
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
        return btn
    }()
    private lazy var viewResultsBarItem = UIBarButtonItem(customView: viewResultsButton)
    
    private var currentPlayer = 1
    private var countdownTimer: Timer?
    private var secondsLeft = 30
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(canvasView)
        setupUI()
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
        let resultsVC = UIViewController()
        resultsVC.view.backgroundColor = .systemBackground
        resultsVC.title = "Results"
        navigationController?.setViewControllers([resultsVC], animated: true)
    }
    
    @objc private func saveImage() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("Image saved")
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
