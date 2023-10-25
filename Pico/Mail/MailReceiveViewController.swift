//
//  MailReceiveViewController.swift
//  Pico
//
//  Created by 양성혜 on 2023/09/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MailReceiveViewController: UIViewController {
    
    private let viewModel = MailReceiveModel()
    private let disposeBag = DisposeBag()
    
    private var sendMailInfo: Mail.MailInfo?
    
    private let navigationBar: UINavigationBar = {
        let navigationBar = UINavigationBar()
        navigationBar.barTintColor = .systemBackground
        return navigationBar
    }()
    
    private let navItem: UINavigationItem = {
        let navigationItem = UINavigationItem(title: "받은 쪽지")
        return navigationItem
    }()
    
    private let leftBarButton: UIBarButtonItem = {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "chevron.left", withConfiguration: imageConfig)
        barButtonItem.tintColor = .picoBlue
        barButtonItem.action = #selector(tappedBackButton)
        return barButtonItem
    }()
    
    private let rightBarButton: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.image = UIImage(systemName: "paperplane.fill")
        barButtonItem.tintColor = .picoBlue
        return barButtonItem
    }()
    
    private let userStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 15
        return stackView
    }()
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let userInfoStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        return stackView
    }()
    
    private let userNameStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        return stackView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .picoContentBoldFont
        label.textColor = .picoFontBlack
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private let mbtiLabelView: MBTILabelView = MBTILabelView(mbti: .infj, scale: .small)
    
    private let sendDateLabel: UILabel = {
        let label = UILabel()
        label.font = .picoDescriptionFont
        label.textColor = .picoFontBlack
        return label
    }()
    
    private let contentView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.clipsToBounds = true
        stackView.layer.cornerRadius = 20
        stackView.layer.borderColor = UIColor.picoBlue.cgColor
        stackView.layer.borderWidth = 2
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20)
        return stackView
    }()
    
    private let messageView: UITextView = {
        let textView: UITextView = UITextView()
        textView.font = .picoContentFont
        textView.textColor = .picoFontBlack
        textView.backgroundColor = .clear
        textView.isEditable = false
        return textView
    }()
    
    // MARK: - MailReceive +LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.configBackgroundColor()
        view.tappedDismissKeyboard()
        addViews()
        makeConstraints()
        configNavigationBarItem()
        configSenderStack()
        tappedNavigationButton()
    }
    
    override func viewDidLayoutSubviews() {
        userImageView.setCircleImageView()
    }
    
    // MARK: - MailReceive +UI
    private func addViews() {
        userNameStack.addArrangedSubview([userNameLabel, mbtiLabelView])
        userInfoStack.addArrangedSubview( [userNameStack, sendDateLabel])
        userStack.addArrangedSubview([userImageView, userInfoStack])
        contentView.addArrangedSubview(messageView)
        
        view.addSubview(navigationBar)
        view.addSubview([userStack, contentView])
    }
    
    private func makeConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        navigationBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeArea)
        }
        
        mbtiLabelView.snp.makeConstraints { make in
            make.centerY.equalTo(userNameLabel)
            make.height.equalTo(mbtiLabelView.frame.size.height)
            make.width.equalTo(mbtiLabelView.frame.size.width)
        }
        
        userStack.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(20)
            make.leading.equalTo(navigationBar).offset(20)
            make.height.equalTo(50)
        }
        
        userImageView.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.equalTo(userStack.snp.bottom).offset(20)
            make.leading.equalTo(userStack)
            make.trailing.equalTo(safeArea).offset(-20)
            make.bottom.equalTo(safeArea.snp.bottom).offset(-50)
        }
    }
    
    private func tappedNavigationButton() {
        rightBarButton.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                let mailSendView = MailSendViewController()
                if let mailUser = self.sendMailInfo {
                    mailSendView.configData(userId: mailUser.mailType == .receive ? mailUser.sendedUserId : mailUser.receivedUserId)
                }
                mailSendView.modalPresentationStyle = .formSheet
                mailSendView.modalTransitionStyle = .flipHorizontal
                self.present(mailSendView, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - MailReceive + config
    func configData(mailSender: Mail.MailInfo) {
        sendMailInfo = mailSender
        navItem.title = mailSender.mailType.typeString
        
        if mailSender.mailType == .receive {
            viewModel.getUser(userId: mailSender.sendedUserId) {
                if let user = self.viewModel.user {
                    self.configViews(user: user)
                }
            }
        } else {
            viewModel.getUser(userId: mailSender.receivedUserId) {
                if let user = self.viewModel.user {
                    self.configViews(user: user)
                }
            }
        }
        self.sendDateLabel.text = mailSender.sendedDate.toStringTime()
        self.messageView.text = mailSender.message
    }
    
    private func configViews(user: User) {
        guard let url = URL(string: user.imageURLs[0]) else { return }
        userImageView.kf.indicatorType = .custom(indicator: CustomIndicator(cycleSize: .small))
        userImageView.kf.setImage(with: url)
        userNameLabel.text = user.nickName
        userNameLabel.sizeToFit()
        mbtiLabelView.setMbti(mbti: user.mbti)
    }
    
    private func configNavigationBarItem() {
        navItem.leftBarButtonItem = leftBarButton
        navItem.rightBarButtonItem = rightBarButton
        navigationBar.shadowImage = UIImage()
        navigationBar.setItems([navItem], animated: true)
    }
    
    private func configSenderStack() {
        let stackTap = UITapGestureRecognizer(target: self, action: #selector(tappedSenderStack))
        userStack.addGestureRecognizer(stackTap)
    }
    
    // MARK: - MailReceive +objc
    @objc func tappedBackButton() {
        dismiss(animated: true)
    }
    
    @objc func tappedSenderStack() {
        dismiss(animated: true)
        let viewController = UserDetailViewController()
        if let user = sendMailInfo {
            if user.mailType == .receive {
                viewModel.getUser(userId: user.sendedUserId) {
                    if let user = self.viewModel.user {
                        viewController.viewModel = UserDetailViewModel(user: user)
                    }
                }
            } else {
                viewModel.getUser(userId: user.receivedUserId) {
                    if let user = self.viewModel.user {
                        viewController.viewModel = UserDetailViewModel(user: user)
                    }
                }
            }
        }
        self.navigationController?.pushViewController(viewController, animated: true)
        print("tap senderStack")
    }
}