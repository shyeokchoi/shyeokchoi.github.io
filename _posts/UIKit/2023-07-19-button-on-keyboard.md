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
키보드가 올라오면서 키보드 자체가 / 또는 키보드와 함께 움직이는 뷰가 다른 뷰를 가릴 때가 있습니다.  

예를 들어,  

<img width="278" alt="스크린샷 2023-07-20 14 33 39" src="https://github.com/qqq1130/qqq1130.github.io/assets/106307725/9210e0bc-d0e5-46ce-8535-5ed38e2faa25">  

이렇게요.   

이럴 때, 사용성을 위해 화면에 보이는 뷰를 올려주고 싶을 것입니다.  
구현하는 데 꽤 시행착오를 많이 겪어서 과정을 기록합니다.  

# NotificationCenter 이용 키보드 올라옴/내려감 감지
먼저, NotificationCenter를 활용해서 키보드가 올라가고 내려가는 것을 감지하는 코드를 작성합니다.  
`viewDidLoad`에서 아래와 같은 `addKeyboardNotifications` 함수를 호출해주면 됩니다.    
<script src="https://gist.github.com/shyeokchoi/308ae058be501273b7a91f6c08520126.js"></script>

`viewWillDisappear`에선 `removeKeyboardNotifications` 함수를 호출해줍니다. 메모리 누수를 방지하기 위해서입니다.  

<script src="https://gist.github.com/shyeokchoi/7c04d33a869669f5284879a0952903f7.js"></script>

이제, `keyboardWillShow`와 `keyboardWillHide` 함수를 채워넣어줄겁니다.  

<script src="https://gist.github.com/shyeokchoi/6409a38048d1a6d8a8d95622f0a5ba4e.js"></script>

# 키보드와 함께 움직이길 바라는 constraint들 빼내기
현재 디자인에서 키보드가 위로 올라올때 함께 위로 움직였으면 하는건 세 가지 입니다.  
Replay 버튼, Enter Room 버튼, Label과 TextField를 감싸고 있는 뷰 (이하 innerView).  

그렇기 때문에 세 개의 constraint들을 인스턴스 변수로 빼내줍니다.   

<script src="https://gist.github.com/shyeokchoi/2b55412dcc444cfd2970a95fa4f51008.js"></script>

`enterButtonBottomConstraint`는 Enter Room 버튼의 `bottomAnchor`의 constraint입니다.  
이 constraint만 키보드와 함께 움직여주면 Enter Room버튼 관련 UI를 다시 그릴 수 있습니다.  
아래 코드가 바로 그렇게 Layout을 설정해주는 코드 일부입니다.     

<script src="https://gist.github.com/shyeokchoi/b04fd86c3cbd391dd6ec93ab66c18a0e.js"></script>

`bottomAnchor`만 바뀌면 `leadingAnchor`, `trailingAnchor`, `heightAnchor` 값들은 정해져있기 때문에 UI가 자동으로 그려집니다.  
Replay버튼, innerView의 레이아웃 코드도 비슷합니다.  
다음과 같습니다.  

<script src="https://gist.github.com/shyeokchoi/cce863104023ead9c1cd24a9329126f2.js"></script>

이렇게 필요한 `NSLayoutConstraint`들을 인스턴스 변수로 참조했습니다.  
이를 이제 `keyboardWillShow`, `keyboardWillHide` 함수에서 활용해줍니다.  

# keyboardWillShow, keyboardWillHide
<script src="https://gist.github.com/shyeokchoi/0dcb955176511f9a57cfa4b95c894039.js"></script>

`keyboardWillShow` 함수입니다.  

```swift
if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
```
지금 올라온 키보드의 높이를 구하는 코드입니다.  
```swift
        replayButtonBottomConstraint?.constant = -keyboardHeight
        enterButtonBottomConstraint?.constant = -keyboardHeight
```
구해온 키보드의 높이를 활용해 `replayButtonBottomConstraint`와 `enterButtonBottomConstraint`를 조정합니다.  
`bottomAnchor`이기때문에 이 값을 -keyboardHeight로 설정해주면 화면 맨 아래에서부터 keyboardHeight만큼 버튼 전체가 밀려올라갑니다.  

```swift
        let safeAreaHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
        
        let buttonTopWhenKeyboardEnabled = safeAreaHeight - (keyboardHeight + buttonHeight)
        
        let innerViewBottom = innerViewTop + innerViewHeight
        
        if (innerViewBottom > buttonTopWhenKeyboardEnabled) { 
            //when pushing up the innerView is necessary (button covering the text field)
            innerViewTopConstraint?.constant = 
              innerViewTop - (innerViewBottom - buttonTopWhenKeyboardEnabled)
        }
```
그러고나면 두 버튼의 맨 위 높이를 구할 수 있게 될겁니다.  
그게 `buttonTopWhenKeyboardEnabled`입니다.  

innerView의 맨 아랫부분은 `innerViewBottom`으로 구했습니다.  

이제, `innerViewBottom > buttonTopWhenKeyboardEnabled` 라면 이는 innerView가 버튼에 가려지는 상황입니다.   

이때는 `innerView`의 top constraint를 위로 밀어올려야합니다.  
굳이 top constraint로 잡은 것은 innerView 내부의 다른 뷰들이 다 innerView의 topAnchor를 기준으로 레이아웃이 잡혀 있어서, top constraint를 옮겨줘야 다른 뷰들도 따라가기 때문입니다.  

<script src="https://gist.github.com/shyeokchoi/9ec247cd7a28c62b364ac8ec9dcda898.js"></script>

`keyboardWillHide` 함수는 간단합니다.  
그냥 처음 레이아웃상 정해져있는 위치로 되돌려주면 됩니다.  

# 결과물
<img width="377" alt="스크린샷 2023-07-20 21 28 31" src="https://github.com/qqq1130/qqq1130.github.io/assets/106307725/5e377df4-9115-4bc1-8404-e076a331a474"> <br>
<br>
버튼들과 innerView가 키보드와 함께 위로 올라가는 것을 볼 수 있습니다.  
