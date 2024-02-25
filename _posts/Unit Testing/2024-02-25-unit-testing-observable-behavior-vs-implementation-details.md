---
title: "[Unit Testing] Observable behavior와 Implementation detail"

categories:
  - Unit Testing Principles, Practices and Patterns
tags:
  - [book review, Unit Testing]

toc: true
toc_sticky: true

date: 2024-02-25
last_modified_at: 2024-02-25
---

> [Unit Testing Principles, Practices, and Patterns](https://www.amazon.com/Unit-Testing-Principles-Practices-Patterns/dp/1617296279)를 읽고 내용을 정리한 글입니다.

# Observable behavior와 Implementation detail
## Observable Behavior?
아래 두 조건 중 하나를 만족한다면, `Observable Behavior` 라고 할 수 있습니다.  
여기서 Client는 그것이 진짜 고객(end user)이든, 다른 시스템이든, 다른 클래스든 상관없이 현재 `SUT`의 API를 사용하는 대상을 의미합니다.  

1. Client가 목적을 이루기 위해 필요한 작업
2. Client가 목적을 이루기 위해 참고할 상태

## Implementation Detail?
`Observable Behavior`가 아니라면 전부 `Implementation Detail` 입니다.  

## Public API 와 Private API
`Observable Behavior` 들은 public API로, `Implementation Detail`은 private API로 설계하는 것이 이상적입니다.   
만약, Client가 단 하나의 목표를 달성하기 위해 여러 개의 public API를 호출하고 있다면, 제대로 추상화/캡슐화가 안 되었다는 신호일 수 있습니다.  

## 예시 코드
Client는 `UserController`라고 하고, `SUT`는 유저를 `UserService`이라고 하겠습니다.  

<script src="https://gist.github.com/shyeokchoi/c11401da5a1d320d53798a4d4c411306.js"></script>   

위 코드에서 Client는 "이름을 재설정한다"는 하나의 작업을 위해 `SUT`의 두 가지 API를 사용해야 했습니다.  
그런데, `normalizeName()` 함수는 사실 Client의 목적을 이루기 위한 작업이라고 할 수 없습니다.  

Client의 목적은 이름을 재설정하는 것입니다.   
재설정할 이름이 50자를 넘어갔을 때 50자를 초과하는 뒷부분을 잘라내는 것는 Client가 목적을 이루기 위해 필요한 작업이 아닙니다.  
오히려 이는 `SUT`가 정해둔 구현 세부사항을 만족하기 위한 작업입니다.  

그러므로 `normalizeName()` 함수는 `Implementation Detail`에 속합니다.  
`rename()` 함수만이 직접적으로 Client의 목적을 달성해줍니다.  

따라서, 코드를 아래와 같이 개선해야 합니다.  
<script src="https://gist.github.com/shyeokchoi/aaccab165e8b8d600356c326e122287f.js"></script>

## 좋은 API 디자인과 좋은 단위 테스트의 관계
이렇게 public API는 모두 `Observable Behavior`에 대응하고, private API는 모두 `Implementation Detail`에 대응하도록 구성해야 합니다.  
그러면 테스트도 자연스럽게 **구현**이 아닌 **결과**를 테스트하도록 짤 수 있습니다.  

# Mocking과 `리팩토링 저항`
## `리팩토링 저항`
리팩토링이란, `Observable Behavior`는 바꾸지 않으면서, 코드는 변경(개선)하는 것을 의미합니다.  

따라서 테스트가 `리팩토링 저항`을 가지고 있다는 것은, `Observable Behavior`가 변경되지 않았는데 테스트가 실패하는 경우가 없다는 뜻입니다.  

Client의 입장에선 `SUT`의 행동이 변하지 않았는데 테스트가 실패하는 것을 false positive라 부르며, 테스트의 신뢰성을 떨어뜨리기 때문에 일어나지 않도록 해야 합니다.  

## Mocking을 적절히 사용하기
이런 `리팩토링 저항`을 위해서는 mocking을 적절하게 사용해야 합니다.  

Intra-system communication, 즉 하나의 시스템 내에서 작동하는 작업의 경우는 Mocking을 사용하면 안 됩니다.  
반면 inter-system communication의 경우 Mocking을 사용하는 것이 적절합니다.  
한 시스템이 다른 시스템과 소통하는 부분은 `SUT`에 종속된 것이 아니라 외부에서 관측할 수 있는 `Observable Behavior` 이므로 mocking을 해도 false positive 문제를 일으키지 않습니다.

예를 들어서, Firebase Cloud Messaging으로 푸시를 발송하는 로직이 있다면, 단위 테스트에서는 실제 푸시 알림을 발송할 필요가 없습니다.  
이는 Firebase의 시스템과 연결되는 inter-system communication이기 때문입니다.  
Firebase Cloud Messaging을 담당하는 클래스를 모킹하고, 해당 클래스에 의도한 argument들이 전달되는지를 테스트(verify)하는 것으로 충분합니다.  

이런 verification은 **구현**에 대한 테스트가 아닙니다.  
외부에서 관찰할 수 있는 `SUT`의 행동에 속하므로, `SUT`의 작동 **결과**를 테스트하는 것입니다.  
