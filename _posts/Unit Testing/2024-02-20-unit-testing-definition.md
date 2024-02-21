---
title: "[Unit Testing] 단위 테스트란?: Classicist vs. Mockist"

categories:
  - Unit Testing Principles, Practices and Patterns
tags:
  - [book review, Unit Testing]

toc: true
toc_sticky: true

date: 2024-02-20
last_modified_at: 2024-02-20
---

> [Unit Testing Principles, Practices, and Patterns](https://www.amazon.com/Unit-Testing-Principles-Practices-Patterns/dp/1617296279)를 읽고 내용을 정리한 글입니다.

# 단위테스트(Unit Test)의 정의

1. 작은 단위(unit)만을 검증한다.
2. 빠르게 실행가능하다.
3. 독립성을 가진다.

**여기서 핵심은 독립성. 그리고 이 독립성을 어떻게 정의하는지가 Classicist와 Mockist의 의견이 갈리는 지점입니다.**

# Classicist vs. Mockist

## Classicist

Classicist가 말하는 독립성은, `테스트들 사이의 독립성` 입니다.  
즉, 테스트의 병렬적 수행이든, 순차적 수행이든, 순서를 바꾸든 영향이 없어야 한다는 것입니다.  
이는 각 단위테스트가 어떤 shared state(예를 들어, DB, File System, static mutable field 등)에 접근해서는 안 된다는 뜻입니다.

## Mockist

Mockist가 말하는 독립성은, `협력 클래스들로부터의 격리` 입니다.  
즉, 어떤 클래스가 테스트의 대상이 된다면, 그 클래스가 의존하고 있는 다른 클래스들은 모두 mocking 되어야 한다는 의미입니다.

## 결론

Classicist가 말하는 단위, 즉 `unit`은 클래스 하나를 의미하는 것이 아닙니다.  
Shared state가 존재하지 않는 한, 여러 개의 클래스도 단위가 될 수 있습니다.

반면 Mockist에게 단위란, `하나의 클래스` 그 자체입니다.

## Classicist는 Mocking을 사용하지 않는가?

만약 어쩔 수 없이 shared state가 개입되면, 여기서는 mocking을 사용해야 합니다.  
여기서 "shared" 란 의미는, 단위 테스트**간**에 공유되었다는 의미이지, 테스트의 대상이 되는 (즉 하나의 단위를 이루는) 클래스들 간에 공유되었다는 의미는 아닙니다.  
여러 클래스들이 주입받은 클래스라고 하더라도, 매 테스트마다 새롭게 생성되고 있다면, 이 오브젝트는 shared state가 아닙니다.

# Mockist 스타일 단위 테스트의 장점 & 반박

> 해당 책의 저자는 Classicist 쪽이기 때문에, Mockist 방식의 장점을 반박하고 있습니다.  
> 하지만 동시에 Mockist 쪽의 의견을 담은 [책](https://www.amazon.com/Growing-Object-Oriented-Software-Guided-Tests/dp/0321503627/ref=sr_1_1?crid=2YGT33LDSTSMA&dib=eyJ2IjoiMSJ9.NmnWLiDJQPuJFhP-14EkBOikcnkuBuB9YNjsZNcP0GLGjHj071QN20LucGBJIEps.WleK2QX2QpV94_GTv8ehtwCTAy2oG26xHnpEo747zyA&dib_tag=se&keywords=Growing+Object-Oriented+Software%2C+Guided+by+Tests&qid=1708361281&sprefix=growing+object-oriented+software%2C+guided+by+tests%2Caps%2C260&sr=8-1)도 소개하고 있습니다. 흥미가 가시는 분은 한 번 읽어보면 좋을 것 같습니다.

실제 예제 코드를 작성해가며, Mockist와 Classicist의 접근을 비교하겠습니다.  
먼저, 테스트에 사용될 코드는 다음과 같습니다.

<script src="https://gist.github.com/shyeokchoi/aaab48fea4b8138b26a21e36dfc69e42.js"></script>
<script src="https://gist.github.com/shyeokchoi/cab9c55ed8900a15f73847c6c0c7bdc2.js"></script>
<script src="https://gist.github.com/shyeokchoi/ac29adb100c659c9866e8f85c0978a9f.js"></script>

`Store` 객체가 `Cashier`, `InventoryManager` 객체를 주입받아서 물건을 파는 코드입니다.

위 코드에 대해, Mockist 방식으로 `Store`에 대한 테스트를 작성하면 다음과 같습니다.

<script src="https://gist.github.com/shyeokchoi/e9c431f1607f18319f72ea3e67aecd6c.js"></script>

Classicist 방식으로 `Store`에 대한 테스트를 작성하면 다음과 같습니다.

<script src="https://gist.github.com/shyeokchoi/ab6b9a2977a257c9e16fa01f281f4b62.js"></script>

이제, 위 테스트코드들을 보며 Mockist들이 주장하는 Mocking의 장점과 그에 대한 저자의 반박을 소개하겠습니다.

## 세밀한 테스트

> 클래스 하나가 단위이기 때문에, 더 세밀한 테스트가 가능하다.

위 Mockist 테스트 코드에서는, `Cashier`와 `InventoryManager`의 구현과는 상관없이 `Store`의 로직만을 테스트합니다.  
제대로 `InventoryManager`의 함수를 호출하고 있는지, `Cashier`를 활용해 계산을 하는 로직이 추가되어 있는지 등을 아래 코드를 통해서 확인합니다.

<script src="https://gist.github.com/shyeokchoi/c12125c918b9a2f652e0f0d6a979011d.js"></script>

이런 식으로 `Cashier`와 `InventoryManager`에 대해서도 따로 테스트코드가 작성될 것입니다.

### 반박

> 세분화 자체를 목표로 삼아선 안 된다. 오히려, 테스트는 의미있는 `행위`의 검증을 목표로 삼아야 한다.  
> 즉, 클래스가 몇 개가 개입되었는지와 상관 없이 비즈니스적으로 의미있는 로직을 테스트하는 것이 목표가 되어야 한다.  
> 어떤 `행위`의 검증 과정을 너무 세밀화하면, 정확히 무엇을 테스트하는지 이해하기 어렵게 된다.

이에 대해 저자는,  
"강아지가 걷는가?"를 테스트하면 되는 것을,  
"강아지가 왼발을 들고, 오른발로 땅을 밀고, 왼발을 내리고, 오른발을 들고, 왼발로 땅을 밀고, 오른발을 내리는가?"를 테스트하는 것과 비슷하다고 비유했습니다.

즉, 위의 코드에서도, `Store`에서 물건을 살 때,

1. 재고가 충분치 않거나 가격이 책정되어 있지 않다면 예외를 던진다.
2. 정상적으로 재고가 있고 가격이 책정되어 있다면 재고를 감소시키고, 고객이 지불해야 하는 가격을 반환한다.

이 행동에 대해서만 테스트를 하면, `물건을 판다`는 상점의 역할을 충분히 테스트하는 것인데,  
이걸 `Store`를 테스트하고, `Cashier`를 테스트하고, `InventoryManager`를 테스트하는 것은 지나친 세분화라고 보는 것입니다.

## 의존성 그래프를 단순화

> 테스트의 대상이 되는 클래스가 굉장히 복잡한 의존성 그래프에 속해있을 때, immediate dependency만 mocking하면, 그래프를 타고 내려가며 계속 의존성을 주입해줄 필요가 없어진다.  
> 즉, 테스트 준비에 드는 시간이 줄어든다.

Classicist 코드를 보면,

<script src="https://gist.github.com/shyeokchoi/1e50a6fb2f63abca469f8c9c1de23d5c.js"></script>

이렇게 의존성을 주입해주는 부분이 있습니다.

반면, Mockist는

<script src="https://gist.github.com/shyeokchoi/8997d29e102984a8ec49802299d22ec0.js"></script>

이렇게 어노테이션만으로 처리합니다.

Mockist의 경우 `Cashier`와 `InventoryManager` 자체를 모킹하기 때문에, 이 클래스들이 의존하는 map 들의 주입은 신경쓸 필요 없습니다.  
`Store`, `Cashier`, `InventoryManager`가 더 많은 클래스들에 의존할수록 이 차이는 커질 것입니다.

### 반박

> 문제에 대한 접근 자체가 잘못되었다.  
> 복잡한 의존성 그래프가 생성되는 것은 테스트 코드의 문제가 아니라, 운영 코드 디자인 상의 문제를 시사한다.  
> 오히려 단위 테스트가 이 점을 짚어주는 시험지 역할을 한다는 점이 Classicist 접근의 장점이다.

저자는 이 경우, 애초에 운영 코드가 잘못된 것이지 테스트코드 작성 방식이 문제가 아니라고 주장합니다.  
이 내용은 책 뒷부분에서 다시 정리한다고 하니, 나중에 더 자세히 정리하겠습니다.

## 버그 지점을 정확히 특정 가능

> 테스트 실패 시, `SUT`에 버그가 있음이 확실하다.

의미상의 기능 단위가 아닌, 각 클래스마다 테스트코드가 작성되기 때문에 어느 클래스에서 버그가 발생했는지 바로 알 수 있습니다.

### 반박

> 테스트를 자주 실행하면, 즉 코드 변경시마다 실행하면 Classicist 방식으로도 어디에서 버그가 발생했는지 알 수 있다.  
> 내가 방금 수정한 그 부분에서 발생했을것이 확실하므로.  
> 또, 하나의 변경이 많은 테스트 실패를 야기하는 것은 오히려 좋을 수도 있다.  
> 지금 수정한 코드가 어디에 영향을 주는지 알 수 있으니.

하나의 클래스에 적용된 변경이 많은 테스트 실패를 야기하는 것은 모킹을 사용하면 불가능한 일입니다.  
해당 클래스를 주입받는 곳들에선 실제 클래스가 아닌 모킹된 클래스를 주입받고, 의도한대로 작동한다고 가정하고 테스트가 진행되기 때문입니다.  
이는 방금 이루어진 변경사항이 운영 코드에선 어떻게 전파되어 어디까지 영향을 미칠지 파악하기 힘들게 만듭니다.

## 그 외 Mockist들을 향한 비판

> Mockist들의 테스트 코드는 `결과`가 아니라 `구현`을 검증하게 되는 경향이 있다.

<script src="https://gist.github.com/shyeokchoi/c12125c918b9a2f652e0f0d6a979011d.js"></script>

제가 작성한 이 테스트코드가 `구현`을 검증하는 대표적인 예시라고 볼 수 있습니다.  
저자는 이렇게 `구현`을 검증하기보다는 특정 시나리오에 대해 올바른 결과가 발생하는지를 검증해야 한다고 보는 것입니다.

# Integration Test(통합 테스트)에 대한 Classicist, Mockist의 의견

## Classicist

Shared dependency에 접근하는 테스트들을 통합 테스트라고 칭합니다.  
예를 들어, 실제 DB에 접근해서 DB에 쓰는 테스트들은 모두 통합테스트 입니다.

## Mockist

실제 구현체를 `SUT`에 주입해서, `SUT`가 실제 협력 객체의 도움을 받는 모든 테스트가 통합 테스트입니다.  
그렇기 때문에, Classicist의 대부분의 테스트가 Mockist들의 입장에선 통합테스트입니다.
