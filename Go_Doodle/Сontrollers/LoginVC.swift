//
//  LoginVC.swift
//  Go_Doodle
//
//  Created by Andrii Prokofiev on 22.06.2025.
//

import UIKit

class LoginVC: UIViewController {

    @IBOutlet private weak var parentView: UIView!
    @IBOutlet private weak var player1Container: UIView!
    @IBOutlet private weak var player2Container: UIView!

    @IBOutlet private weak var player1AvatarImageView: UIImageView!
    @IBOutlet private weak var player1NicknameTextField: UITextField!
    @IBOutlet private weak var player2AvatarImageView: UIImageView!
    @IBOutlet private weak var player2NicknameTextField: UITextField!

    private var continueButtonItem: UIBarButtonItem!
    private let placeholderAvatar = UIImage(named: "avatarPlaceholder")

    private enum Step { case first, second }
    private var currentStep: Step = .first

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContinueButton()
        setupTextFieldTargets()
        resetFields()
        setupTapToDismissKeyboard()
        
        let w = view.bounds.width
        player1Container.transform = CGAffineTransform(translationX: -w, y: 0)
        player2Container.transform = CGAffineTransform(translationX:  w, y: 0)
        parentView.alpha = 0
        player1Container.isHidden = true
        player2Container.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showStep1()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        [player1AvatarImageView, player2AvatarImageView].forEach { iv in
            iv.layer.cornerRadius = iv.bounds.width / 2
            iv.clipsToBounds = true
            iv.contentMode = .scaleAspectFill
        }
    }

    private func setupContinueButton() {
        continueButtonItem = UIBarButtonItem(
            title: "Begin",
            style: .done,
            target: self,
            action: #selector(continueTapped)
        )
        continueButtonItem.isEnabled = false
        navigationItem.rightBarButtonItem = continueButtonItem
    }

    private func resetFields() {
        player1NicknameTextField.text = ""
        player2NicknameTextField.text = ""
        player1AvatarImageView.image = placeholderAvatar
        player2AvatarImageView.image = placeholderAvatar
        continueButtonItem.isEnabled = false
    }

    private func setupTextFieldTargets() {
        player1NicknameTextField.addTarget(self,
                                          action: #selector(textFieldsDidChange),
                                          for: .editingChanged)
        player2NicknameTextField.addTarget(self,
                                          action: #selector(textFieldsDidChange),
                                          for: .editingChanged)
    }

    @objc private func textFieldsDidChange() {
        switch currentStep {
        case .first:
            let valid1 = !(player1NicknameTextField.text?
                .trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            continueButtonItem.isEnabled = valid1
        case .second:
            let valid2 = !(player2NicknameTextField.text?
                .trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            continueButtonItem.isEnabled = valid2
        }
    }

    @objc private func continueTapped() {
        switch currentStep {
        case .first:
            dismissKeyboard()
            continueButtonItem.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.currentStep = .second
                self.showStep2()
            }

        case .second:
            let sb = UIStoryboard(name: "Main", bundle: nil)
            guard let drawingVC = sb.instantiateViewController(
                withIdentifier: "drawingVC"
            ) as? DrawingVC else { fatalError() }
            navigationController?.setViewControllers([drawingVC], animated: true)
        }
    }

    private func showStep1() {
        player1Container.isHidden = false
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.5) {
            self.parentView.alpha = 1
            self.player1Container.transform = .identity
            self.view.layoutIfNeeded()
        }
    }
    
    private func showStep2() {
        let w = view.bounds.width
        player2Container.transform = CGAffineTransform(translationX: w, y: 0)
        player2Container.isHidden = true

        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.5) {
            self.player2Container.isHidden = false
            self.player2Container.transform = .identity
            self.view.layoutIfNeeded()
        }
    }



    private func setupTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
