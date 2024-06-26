//
//  ProfileEditNicknameModalViewController.swift
//  Pico
//
//  Created by 김민기 on 2023/10/13.
//

import UIKit
import SnapKit
import RxSwift
/* 이름 뷰*/
final class ProfileEditNicknameModalViewController: UIViewController {
    
    private let backButton: UIButton = {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        let image = UIImage(systemName: "xmark", withConfiguration: imageConfig)
        let button = UIButton()
        button.layer.masksToBounds = false
        button.layer.cornerRadius = 12
        button.backgroundColor = .picoGray
        button.setImage(image, for: .normal)
        button.tintColor = .gray
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .picoSubTitleFont
        label.textColor = .picoFontBlack
        return label
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.font = .picoTitleFont
        textField.placeholder = "3자리 부터 8자리 까지"
        textField.textColor = .black
        return textField
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "x.circle"), for: .normal)
        button.tintColor = .picoGray
        button.imageView?.contentMode = .scaleAspectFit
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        return button
    }()
    
    private let nickNameCheckButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("중복확인", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 13
        button.isEnabled = false
        button.backgroundColor = .picoGray
        //        button.isHidden = true
        return button
    }()
    
    private let completeButton: UIButton = {
        let button = UIButton()
        button.setTitle("완료", for: .normal)
        button.layer.masksToBounds = false
        button.layer.cornerRadius = 15
        button.backgroundColor = .picoGray
        button.isEnabled = false
        return button
    }()
    
    private let chuCount = UserDefaultsManager.shared.getChuCount()
    private let profileEditNicknameModalViewModel = ProfileEditNicknameModalViewModel()
    private let consumeChuCountPublish = PublishSubject<Void>()
    let profileEditViewModel: ProfileEditViewModel
    private let disposeBag = DisposeBag()
    
    init(profileEditViewModel: ProfileEditViewModel) {
        self.profileEditViewModel = profileEditViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.configBackgroundColor()
        addViews()
        makeConstraints()
        textFieldConfigure()
        binds()
    }
    
    private func binds() {
        
        let input = ProfileEditNicknameModalViewModel.Input(
            consumeChuCount: consumeChuCountPublish.asObservable()
        )
        
        let output = profileEditNicknameModalViewModel.transform(input: input)
        
        output.resultPurchase
            .withUnretained(self)
            .subscribe { viewController, _ in
                DispatchQueue.main.async {
                    viewController.showCustomAlert(alertType: .onlyConfirm, titleText: "알림", messageText: "닉네임이 변경되었습니다.", confirmButtonText: "확인", comfrimAction: {
                        
                        viewController.dismiss(animated: true)
                    })
                }
            }
            .disposed(by: disposeBag)
        
        profileEditViewModel.modalName
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        backButton.rx.tap
            .bind { [weak self] _ in
                guard let self else { return }
                self.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind { [weak self] _ in
                guard let self else { return }
                self.self.textField.text = ""
                self.nickNameCheckButton.isEnabled = false
                self.nickNameCheckButton.backgroundColor = .picoGray
                self.completeButton.isEnabled = false
                self.completeButton.backgroundColor = .picoGray
            }
            .disposed(by: disposeBag)
        
        let text = profileEditViewModel.textData ?? ""
        textField.text = text
        
        nickNameCheckButton.rx.tap
            .bind { [weak self] _ in
                guard let self else { return }
                guard searchSlangWord(name: self.textField.text?.replacingOccurrences(of: " ", with: "") ?? "") else { return }
                CheckService.shared.checkNickName(name: self.textField.text?.replacingOccurrences(of: " ", with: "") ?? "") { [weak self] message, isRight in
                    guard let self = self else { return }
                    Loading.hideLoading()
                    guard isRight else {
                        self.showCustomAlert(alertType: .onlyConfirm, titleText: "알림", messageText: message, confirmButtonText: "확인", comfrimAction: {
                            self.textField.text = ""
                        })
                        return
                    }
                    view.endEditing(true)
                    showCustomAlert(alertType: .onlyConfirm, titleText: "알림", messageText: message, confirmButtonText: "확인", comfrimAction: {
                        self.completeButton.isEnabled = true
                        self.completeButton.backgroundColor = .picoBlue
                    })
                }
            }
            .disposed(by: disposeBag)
        
        completeButton.rx.tap
            .bind { [weak self] _ in
                guard let self else { return }
                self.showCustomAlert(alertType: .canCancel, titleText: "닉네임 변경", messageText: "닉네임 변경을 위해서는 50츄가 필요합니다.\n현재 츄 : \(chuCount) 개", confirmButtonText: "변경 (50츄) ", comfrimAction: {
                    self.consumeChuCountPublish.onNext(())
                    self.profileEditViewModel.updateUserData(data: self.textField.text?.replacingOccurrences(of: " ", with: ""), selectedCase: .nickName)
                    self.profileEditViewModel.updateData(data: self.textField.text?.replacingOccurrences(of: " ", with: ""))
                })
            }.disposed(by: disposeBag)
    }
    
    private func searchSlangWord(name: String) -> Bool {
        let slangWordArray: [String] = ["시발", "병신", "개새끼", "꺼져", "지랄", "애미", "애비", "등신", "따까리", "미친", "씨발", "씨팔", "시팔", "쌍놈", "쌍년", "아가리", "장애인", "호구"]
        for slangWord in slangWordArray {
            if name.contains(slangWord) {
                showCustomAlert(alertType: .onlyConfirm, titleText: "경고", messageText: "비속어 및 성적인 단어가 포함되어있습니다.", confirmButtonText: "확인")
                textField.text = ""
                completeButton.isEnabled = false
                completeButton.backgroundColor = .picoGray
                nickNameCheckButton.isEnabled = false
                nickNameCheckButton.backgroundColor = .picoGray
                return false
            }
        }
        return true
    }
    
    private func textFieldConfigure() {
        textField.delegate = self
    }
    
    private func addViews() {
        view.addSubview([backButton, titleLabel, textField, cancelButton, nickNameCheckButton, completeButton])
    }
    
    private func makeConstraints() {
        backButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-15)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(35)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(cancelButton.snp.leading).offset(-10)
            make.height.equalTo(30)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.top)
            make.trailing.equalTo(nickNameCheckButton.snp.leading).offset(-8)
            make.height.equalTo(30)
        }
        
        nickNameCheckButton.snp.makeConstraints { make in
            make.centerY.equalTo(textField.snp.centerY)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(35)
            make.width.equalTo(65)
        }
        
        completeButton.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(35)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
    }
}

extension ProfileEditNicknameModalViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == " " {
            return false
        }
        let text = profileEditViewModel.textData ?? ""
        var updatedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        updatedText = updatedText.replacingOccurrences(of: " ", with: "")
        completeButton.isEnabled = false
        completeButton.backgroundColor = .picoGray
        if updatedText.count > 8 {
            return false
        }
        if updatedText != text && updatedText.count > 2 && updatedText.count < 9 {
            nickNameCheckButton.isEnabled = true
            nickNameCheckButton.backgroundColor = .picoBlue
        } else {
            nickNameCheckButton.isEnabled = false
            nickNameCheckButton.backgroundColor = .picoGray
        }
        return updatedText.count <= 8
    }
}
