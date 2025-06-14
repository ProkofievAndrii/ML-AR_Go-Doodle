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
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(canvasView)
        setupCanvasView()
        setupBarButtons()
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
        canvasView.delegate = self
    }

    private func setupBarButtons() {
        let eraseButton = UIButton(type: .system)
        eraseButton.setImage(UIImage(systemName: "eraser.fill"), for: .normal)
        eraseButton.setTitle(" Erase", for: .normal)
        eraseButton.sizeToFit()
        eraseButton.addTarget(self, action: #selector(eraseTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: eraseButton)

        let saveButton = UIButton(type: .system)
        saveButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        saveButton.setTitle(" Save", for: .normal)
        saveButton.sizeToFit()
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
    }

    @objc private func eraseTapped() {
        canvasView.drawing = PKDrawing()
    }

    @objc private func saveTapped() {
//        let image = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        print("Image saved")
    }
}

//MARK: - PKCanvasViewDelegate
extension DrawingVC: PKCanvasViewDelegate {
    // MARK: — PKCanvasViewDelegate stubs
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) { }
    func canvasViewDidFinishRendering(_ canvasView: PKCanvasView) { }
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) { }
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) { }
}
