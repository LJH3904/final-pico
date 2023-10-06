//
//  SignViewController.swift
//  Pico
//
//  Created by LJh on 2023/09/25.
//

import UIKit
import SwiftUI
import SnapKit
import RxSwift
import RxCocoa

final class SignViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private let picoLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let picoChuImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "chu")
        return imageView
    }()
    
    private let signInButton: CommonButton = {
        let button = CommonButton(type: .custom)
        button.setTitle("로그인", for: .normal)
        return button
    }()
    
    private let signUpButton: CommonButton = {
        let button = CommonButton(type: .custom)
        button.setTitle("회원가입", for: .normal)
        return button
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configBackButton()
        addSubViews()
        makeConstraints()
        configBackButton()
        configRx()
    }
    override func viewDidAppear(_ animated: Bool) {
        print("""
              ===========================================
              mbti:\(SignUpViewModel.userMbti),
              === number: \(SignUpViewModel.phoneNumber),
              birth: \(SignUpViewModel.birth),
              === gender: \(SignUpViewModel.gender),
              nickname: \(SignUpViewModel.nickName),
              === imageURL \(SignUpViewModel.imageURLs)
              위도:1 \(SignUpViewModel.location.latitude),
              경도:1 \(SignUpViewModel.location.longitude),
              주소:1 \(SignUpViewModel.location.address)
              ===========================================
              """)
    }
}
extension SignViewController {
    private func configRx() {
        signInButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.tappedButtonAnimation(self.signInButton)
                let viewController = SignInViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
        
        signUpButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.tappedButtonAnimation(self.signUpButton)
                let viewController = SignUpViewController()
                self.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
// MARK: - UI관련
extension SignViewController {
    private func addSubViews() {
        for viewItem in [picoLogoImageView, picoChuImageView, signInButton, signUpButton] {
            view.addSubview(viewItem)
        }
    }
    
    private func makeConstraints() {
        let safeArea = self.view.safeAreaLayoutGuide
        
        picoLogoImageView.snp.makeConstraints { make in
            make.top.equalTo(safeArea).offset(30)
            make.leading.equalTo(50)
            make.trailing.equalTo(-50)
            make.height.equalTo(100)
        }
        
        picoChuImageView.snp.makeConstraints { make in
            make.top.equalTo(picoLogoImageView.snp.bottom).offset(50)
            make.leading.equalTo(50)
            make.trailing.equalTo(-50)
            make.height.equalTo(200)
        }
        
        signInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(20)
            make.trailing.equalTo(-20)
            make.bottom.equalTo(signUpButton.snp.top).offset(-20)
            make.height.equalTo(signUpButton.snp.height)
        }
        
        signUpButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(20)
            make.trailing.equalTo(-20)
            make.bottom.equalTo(safeArea).offset(-100)
            make.height.equalTo(50)
        }
    }
}
