---
title: "[Spring] @DirtiesContext를 제거해 통합테스트 성능 높이기"

categories:
  - Spring
tags:
  - [Java, Spring]

toc: true
toc_sticky: true

date: 2024-01-20
last_modified_at: 2024-01-20
---

# 문제상황

현재 다니고 있는 회사에서는 핵심 비즈니스 로직에 대해서는 반드시 유닛 테스트를 작성하고 있습니다.  
또한, 모든 API에 대하여 가능한 한 많은 시나리오를 포함하는 통합 테스트를 작성합니다.

그러다보니 앱이 리뉴얼되고 6개월밖에 지나지 않았지만, 테스트가 약 2400개 작성되었습니다.

PR을 올리기 전 빌드시에 테스트를 모두 실행해서 통과를 하면, PR을 열게 됩니다. 이후 다시 개발서버에서 테스트를 모두 실행하고, 통과가 되어야 머지가 가능해집니다.

문제는, 로컬에서 고성능의 맥으로 테스트를 실행하는 데만 해도 5분이 넘게 걸린단 점입니다.  
저는 이 시간을 줄이고 싶었습니다.

# 원인

테스트코드에서 개선이 필요한 부분은 많겠지만 일단은 `@DirtiesContext`에 주목했습니다.  
해당 어노테이션을 붙이면 통합테스트 실행 중에 `Spring Application Context`를 초기화하고 다시 생성합니다.

Configuration을 바꾸거나 bean을 바꾸거나 하면서 테스트를 하고싶은 경우, 즉 정말 `Application Context`를 초기화하면서 테스트를 해야하는 상황이라면 사용을 해야겠지만, 저희는 주로 테스트간 DB의 독립성을 위해 사용하고 있었습니다.

그러니까 DB의 특정 테이블만 초기화하면 되는데, 전체 `Application Context`를 초기화하고 있었던 것입니다.

# 해결

**저는 integration test를 위한 소스와 main 소스가 다른 source set으로 분리되어 있고 integration test의 소스에서는 main의 클래스를 참조할 수 있어도 main의 소스에서는 integration test의 클래스를 참조할 수 없게 설정해주었습니다.**

DB의 테이블을 초기화해주는 클래스인 `DbCleaner`를 만들고, `@DirtiesContext`를 걷어내고 `DbCleaner`를 활용해 상황에 맞게 특정 테이블들만 초기화했습니다.  
아래는 간략화한 코드입니다.

최대한 다형성을 활용하기 위해 노력했습니다.  
새로운 테이블들을 청소할 필요가 생겨도 OCP 원칙이 지켜지도록(기존 코드를 수정하지 않아도 되도록) 설계했습니다.

## DbCleaner.java

<script src="https://gist.github.com/shyeokchoi/767822acaea65eed2c241183cfd720fe.js"></script>

`L30`의

`entityManager.createNativeQuery("SET REFERENTIAL_INTEGRITY FALSE").executeUpdate();`

이 코드는 H2 DB에서 참조 무결성 검사를 비활성화합니다. 여기서는 foreign key 관련 제약조건들을 잠깐 비활성화하기 위해 실행되는 쿼리입니다.

`L35`의

`entityManager.createNativeQuery("SET REFERENTIAL_INTEGRITY TRUE").executeUpdate();`

이 코드는 테이블들을 다 청소하고 나서 다시 제약조건들을 활성화합니다.

생성자는 `TableNamesProvider` 인터페이스를 구현하는 클래스들을 의존성 주입 받은 후에, `DbCleanType` 이 주어졌을 때 바로 그에 연계된 `TableNamesProvider` 구현체를 골라낼 수 있도록 `Map` 을 생성합니다.

테스트 코드에서 DB 테이블을 청소하고 싶을 때는 `clean()` 함수를 호출하게 됩니다.  
이때 `DbCleanType`를 제공하면 `DbCleaner`가 해당 `DbCleanType`에 맞는 테이블 이름들을 제공해줄, 적절한 `TableNamesProvider` 구현체를 골라냅니다.  
이 `TableNamesProvider의 구현체`가 청소할 테이블들의 이름을 제공해줍니다.

## DbCleanType.java

<script src="https://gist.github.com/shyeokchoi/c7d9dd3b2a9746784dec9afc451d7e46.js"></script>

실제 코드에는 많은 타입들이 있지만, 예시로 `POST` 하나만 넣었습니다.

## TableNamesProvider.java

<script src="https://gist.github.com/shyeokchoi/e014ba3251c736c15c4413bd313b81b4.js"></script>

청소할 테이블 이름들을 제공하는 인터페이스 입니다.

## PostRelatedTableNamesProvider.java

<script src="https://gist.github.com/shyeokchoi/22f8ee3a385bd15f465e63f588ac7ebb.js"></script>

`TableNamesProvider` 인터페이스의 구현체입니다.  
게시글 테이블과, 게시글 테이블과 연계된 다른 테이블들의 이름을 제공합니다.

## 사용예시

<script src="https://gist.github.com/shyeokchoi/735a99c4c235a714872f3d818027226d.js"></script>

테스트에서 테이블을 비워줘야 할 때 위처럼 `DbCleaner`의 함수를 호출해줍니다.

# 테스트 성능 개선 결과

개선 전:  
![digital_delegation_special_char_err](/assets/images/Spring/2024-01-20-remove-dirtiescontext/test_result_before_refactor.png)  
개선 후:  
![digital_delegation_special_char_err](/assets/images/Spring/2024-01-20-remove-dirtiescontext/test_result_after_refactor.png)  
2분정도 빌드 시간이 줄어들었습니다!  
약 40% 정도 개선되었네요 👍🫡

참고로, 개선 전이나 후나 `./gradlew build` 실행시 생성되는 Test Summary에 표시된 duration은 비슷합니다.

![digital_delegation_special_char_err](/assets/images/Spring/2024-01-20-remove-dirtiescontext/gradle_test_summary.png)

하지만, 이렇게 실제 빌드에 걸리는 시간이 줄어든 것을 보면, `Spring Application Context` 재생성에 얼마나 많은 시간이 걸리는지 짐작할 수 있습니다.

# 왜 @DirtiesContext를 사용하는건가?

이번 개선을 진행하며, 애초에 `@DirtiesContext` 어노테이션이 왜 필요한지, 언제 사용되는지 의문이 들었습니다.  
운영 환경과 테스트 환경은 같아야 한다고 생각했기 때문입니다.  
즉, 우리가 운영에서 서버를 실행할 때 중간에 configuration을 바꾸거나 bean 설정을 바꿨다가 다시 `Application Context`를 초기화하는 일은 없을텐데, 테스트에서는 그렇게 하는게 이상했던 것입니다.

이 부분에 대해서 고민해보고 서칭해보면서 알게 된 것은 다음과 같습니다.

1. 운영에서 `Application Context`를 초기화하는 일은 보통은 일어나지 않아야 하는 것이 맞다.
2. 하지만, 운영과 다른 configuration, bean을 사용하는 시나리오에 대해서도 유연하게 테스트하고싶은 경우가 있다.
3. 이때, `Application Context`를 수정하게 된다.
4. 이런 시나리오들을 테스트하고 나서는, 원래의 상태로 돌아와야 남은 테스트들을 정상적으로 실행할 수 있다.

따라서, `Application Context`을 초기화해야하는 경우가 생깁니다.  
이를 위해 `@DirtiesContext`가 필요합니다.
