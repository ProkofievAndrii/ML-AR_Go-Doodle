//
//  LoginVC.swift
//  Go_Doodle
//
//  Created by Andrii Prokofiev on 22.06.2025.
//

import UIKit

class LoginVC: UIViewController {

    @IBOutlet private weak var player1AvatarImageView: UIImageView!
    @IBOutlet private weak var player1NicknameTextField: UITextField!
    @IBOutlet private weak var player2AvatarImageView: UIImageView!
    @IBOutlet private weak var player2NicknameTextField: UITextField!

    private var continueButtonItem: UIBarButtonItem!
    private let placeholderAvatar = UIImage(named: "avatarPlaceholder")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContinueButton()
        setupTextFieldTargets()
        resetFields()
        setupTapToDismissKeyboard()
    }

    private func resetFields() {
        player1NicknameTextField.text = ""
        player2NicknameTextField.text = ""
        player1AvatarImageView.image = placeholderAvatar
        player2AvatarImageView.image = placeholderAvatar
        continueButtonItem.isEnabled = false
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

    private func setupTextFieldTargets() {
        player1NicknameTextField.addTarget(
            self,
            action: #selector(textFieldsDidChange),
            for: .editingChanged
        )
        player2NicknameTextField.addTarget(
            self,
            action: #selector(textFieldsDidChange),
            for: .editingChanged
        )
    }

    @objc private func textFieldsDidChange() {
        let t1 = player1NicknameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == false
        let t2 = player2NicknameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == false
        continueButtonItem.isEnabled = (t1 && t2)
    }

    private func setupTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func continueTapped() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let drawingVC = sb.instantiateViewController(
            withIdentifier: "drawingVC"
        ) as? DrawingVC else {
            fatalError("DrawingVC not found")
        }
        navigationController?.setViewControllers([drawingVC], animated: true)
    }
}
