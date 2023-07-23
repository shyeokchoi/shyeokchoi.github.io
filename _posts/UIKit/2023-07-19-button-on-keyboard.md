---
title:  "[UIKit] 화면 내의 뷰들 키보드와 함께 밀어올리기"

categories:
  - UIKit
tags:
  - [UIKit, iOS, Swift]

toc: true
toc_sticky: true
 
date: 2023-07-19
last_modified_at: 2023-07-19
published: true
---
# 배경
키보드가 올라오면서 키보드 자체가 / 또는 키보드와 함께 움직이는 뷰가 다른 뷰를 가릴 때가 있습니다. 예를 들어,  
<img width="278" alt="스크린샷 2023-07-20 14 33 39" src="https://github.com/qqq1130/qqq1130.github.io/assets/106307725/9210e0bc-d0e5-46ce-8535-5ed38e2faa25">  
이렇게요.   
(사진은 제가 인턴으로 일하고 있는 스타트업 '페이지콜'의 샘플 앱입니다. 제가 만들고 있어요!)   
이럴 때, 사용성을 위해 화면에 보이는 뷰를 올려주고 싶을 것입니다.  
구현하는 데 꽤 시행착오를 많이 겪어서, 공유도 할겸, 기록도 할 겸 글 써봅니다.  

# NotificationCenter 이용 키보드 올라옴/내려감 감지
위 사진에선 버튼들이 이미 키보드와 함께 위로 올라왔지만, 그냥 처음부터 구현하는 법을 기록하겠습니다. 버튼도 아직은 키보드와 함께 움직이지 않는다고 가정하고 읽어주세요.   
    
먼저, NotificationCenter를 활용해서 키보드가 올라가고 내려가는 것을 감지하는 코드를 작성합니다.  
`viewDidLoad`에서 아래와 같은 `addKeyboardNotifications` 함수를 호출해주면 됩니다.    
```swift
func addKeyboardNotifications() {
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil)
}
```
`viewWillDisappear`에선 `removeKeyboardNotifications` 함수를 호출해줍니다. 메모리 누수를 방지하기 위해서입니다.  
```swift
func removeKeyboardNotifications() {
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
}
```
이제, `keyboardWillShow`와 `keyboardWillHide` 함수를 채워넣어줄겁니다.  
```swift
@objc func keyboardWillShow(notification:NSNotification){
        
}
    
@objc func keyboardWillHide(notification:NSNotification){

}
```
# 키보드와 함께 움직이길 바라는 constraint들 빼내기
위 사진을 보고 생각을 해 봅니다. 우리가 움직였으면 하는건 세 가지 입니다. Replay 버튼, Enter Room 버튼, Label과 TextField를 감싸고 있는 뷰 (이하 innerView).  
그렇기 때문에 세 개의 constraint들을 인스턴스 변수로 빼내줍니다.   
```swift
var enterButtonBottomConstraint: NSLayoutConstraint?
var replayButtonBottomConstraint: NSLayoutConstraint?
var innerViewTopConstraint: NSLayoutConstraint?
```
`enterButtonBottomConstraint`는 Enter Room 버튼의 bottomAnchor의 constraint입니다. 이 constraint만 키보드와 함께 움직여주면 Enter Room버튼 관련 UI를 다시 그릴 수 있습니다. 아래 코드를 보시면 이해가 되실 겁니다. Layout을 설정해주는 코드 일부입니다.     
```swift
view.addSubview(enterButton)
enterButton.translatesAutoresizingMaskIntoConstraints = false
enterButtonBottomConstraint = enterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
NSLayoutConstraint.activate([
    enterButton.leadingAnchor.constraint(equalTo: replayButton.trailingAnchor, constant: 24),
    enterButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
    enterButtonBottomConstraint!,
    enterButton.heightAnchor.constraint(equalToConstant: 42)
])
```
bottomAnchor만 바뀌면 leadingAnchor, trailingAnchor, heightAnchor 값들은 정해져있기 때문에 UI가 자동으로 그려집니다.  
Replay버튼, innerView의 레이아웃 코드도 비슷합니다. 다음과 같습니다.  
```swift
view.addSubview(replayButton)
replayButton.translatesAutoresizingMaskIntoConstraints = false
replayButtonBottomConstraint = replayButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
NSLayoutConstraint.activate([
    replayButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
    replayButton.widthAnchor.constraint(equalToConstant: (self.view.frame.size.width - 32*2 - 24)/2),
    replayButtonBottomConstraint!,
    replayButton.heightAnchor.constraint(equalToConstant: 42)
])

view.addSubview(innerView)
innerView.translatesAutoresizingMaskIntoConstraints = false
innerViewTopConstraint = innerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)

NSLayoutConstraint.activate([
    innerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
    innerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
    innerViewTopConstraint!,
    innerView.heightAnchor.constraint(equalToConstant: 346)
])
```
이렇게 어떤 NSLayoutConstraint들이 필요할지 생각을 했고 잘 빼내줬으면 이를 이제 `keyboardWillShow`, `keyboardWillHide` 함수에서 활용해줍니다.  
# keyboardWillShow, keyboardWillHide
```swift
@objc func keyboardWillShow(notification:NSNotification){
    if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        let buttonHeight = CGFloat(42)
        let innerViewHeight = CGFloat(346)
        let innerViewTop = CGFloat(20)

        replayButtonBottomConstraint?.constant = -keyboardHeight
        enterButtonBottomConstraint?.constant = -keyboardHeight
        
        let safeAreaHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
        
        let buttonTopWhenKeyboardEnabled = safeAreaHeight - (keyboardHeight + buttonHeight)
        
        let innerViewBottom = innerViewTop + innerViewHeight
        
        if (innerViewBottom > buttonTopWhenKeyboardEnabled) { //when pushing up the innerView is necessary (button covering the text field)
            innerViewTopConstraint?.constant = innerViewTop - (innerViewBottom - buttonTopWhenKeyboardEnabled) - 16
        }
        
    }
}
```
`keyboardWillShow` 함수입니다.  
`buttonHeight`, `innerViewHeight`, `innerViewTop` 등은 제가 그냥 가독성을 높이려고 레이아웃 잡는데 썼던 상수들을 갖고온거니 신경쓰지 않으셔도 됩니다.  
```swift
if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
```
이 부분은 지금 올라온 키보드의 높이를 구하는 코드입니다.  
```swift
        replayButtonBottomConstraint?.constant = -keyboardHeight
        enterButtonBottomConstraint?.constant = -keyboardHeight
```
이후, 구해온 키보드의 높이를 활용해 `replayButtonBottomConstraint`와 `enterButtonBottomConstraint`를 조정합니다.  
bottomAnchor이기때문에 이 값을 -keyboardHeight로 설정해주면 화면 맨 아래에서부터 keyboardHeight만큼 버튼 전체가 밀려올라갑니다.  
```swift
        let safeAreaHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
        
        let buttonTopWhenKeyboardEnabled = safeAreaHeight - (keyboardHeight + buttonHeight)
        
        let innerViewBottom = innerViewTop + innerViewHeight
        
        if (innerViewBottom > buttonTopWhenKeyboardEnabled) { //when pushing up the innerView is necessary (button covering the text field)
            innerViewTopConstraint?.constant = innerViewTop - (innerViewBottom - buttonTopWhenKeyboardEnabled) - 16
        }
```
그러고나면 두 버튼의 맨 위 높이를 구할 수 있게 될겁니다. 그게 `buttonTopWhenKeyboardEnabled`입니다.  
여기서 iOS 화면의 Safe Area를 구해서 활용합니다.   
innerView의 맨 아랫부분은 `innerViewBottom`으로 구했습니다.  
이제, `innerViewBottom > buttonTopWhenKeyboardEnabled` 라면 이는 innerView가 버튼에 가려지는 상황입니다.   
이때는 innerView의 top constraint를 위로 밀어올려야합니다. 굳이 top constraint로 잡은 것은 innerView 내부의 다른 뷰들이 다 innerView의 topAnchor를 기준으로 레이아웃이 잡혀 있어서, top constraint를 옮겨줘야 다른 뷰들도 따라가기 때문입니다.  
겹치는 만큼 올려주고, 16만큼 더 올려줍니다. 16이란 숫자는 디자이너님이 정해주신 상수이지 별 의미는 없습니다.  
```swift
@objc func keyboardWillHide(notification:NSNotification){
    //go back to original constraints
    let buttonBottom = CGFloat(24)
    let innerViewTop = CGFloat(20)

    replayButtonBottomConstraint?.constant = -buttonBottom
    enterButtonBottomConstraint?.constant = -buttonBottom
    innerViewTopConstraint?.constant = innerViewTop
}
```
`keyboardWillHide` 함수는 간단합니다. 그냥 처음 레이아웃상 정해져있는 위치로 되돌려주면 됩니다.  
# 결과물
<img width="377" alt="스크린샷 2023-07-20 21 28 31" src="https://github.com/qqq1130/qqq1130.github.io/assets/106307725/5e377df4-9115-4bc1-8404-e076a331a474"> <br>
<br>
버튼들과 innerView가 키보드와 함께 위로 올라가는 것을 볼 수 있습니다.  
사실 이 기능 만들면서 시행착오도 많이 겪고 힘들었는데, 결국 디자이너님이 디자인 바꾸자고 하셔서.... 다른 디자인으로 구현하게 되었습니다 ㅜㅜ
그래도 블로그 글이라도 하나 남겼으니 만족합니다.  