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
버그가 발견되었을 때는 해당 버그를 수정하고, 동일한 문제가 재발하지 않도록 해당 버그가 나타난 시나리오를 다루는 테스트를 추가해야 합니다.  
이 과정을 생략하면, PR 리뷰에서 "이 부분에 테스트를 추가하는 것은 어떨까요?"라는 코멘트가 달리곤 합니다.  
그리고 테스트를 추가하기 전까지는 풀 리퀘스트가 승인되지 않습니다.🥹

개발 속도가 느려지는건 사실이지만, 그만큼 리팩토링할 때도 마음 놓고 할 수 있습니다. 내가 뭘 건드렸든 지금 서버가 제공하는 API 들은 정상적으로 작동하고 있음을 보장할 수 있으니까요.  
아무튼.. 이렇다보니 앱이 리뉴얼되고 6개월밖에 지나지 않았지만, 테스트가 2300개가 쌓였습니다.

그리고 PR을 올리기 전 빌드시에 테스트를 모두 실행해서 통과를 하면, PR을 열게 됩니다. 이후 다시 개발서버에서 테스트를 모두 실행하고, 통과가 되면 머지가 가능해집니다.  
문제는, 로컬에서 고성능의 맥으로 테스트를 실행하는 데만 해도 5분이 넘게 걸린단 점입니다.

# 원인

다양한 원인이 있을거고 테스트코드를 더 효율적으로 개선해야할 부분도 많았겠지도 일단은 `@DirtiesContext`에 주목했습니다.  
해당 어노테이션을 붙이면 통합테스트 실행 중에 `Spring Application Context`를 초기화하고 다시 띄웁니다.

Configuration을 바꾸거나 bean을 바꾸거나 하면서 테스트를 하고싶은 경우, 즉 정말 `Application Context`를 초기화하면서 테스트를 해야하는 상황이라면 사용을 해야겠지만, 저희는 주로 테스트간 DB의 독립성을 위해 사용하고 있었습니다.

그러니까 DB의 특정 테이블만 초기화하면 되는데, 전체 `Application Context`를 초기화하고 있었던 것입니다.

# 해결

DB의 테이블을 초기화해주는 클래스인 `DbCleaner`를 만들고, `@DirtiesContext`를 걷어내고 `DbCleaner`를 활용해 상황에 맞게 특정 테이블들만 초기화했습니다.  
아래는 간략화한 코드입니다.

```java
@Component
@Transactional
public class DbCleaner {
    private static final String POSTS = "posts";
    private static final String POLLS = "polls";
    private static final String POLL_ITEMS = "poll_items";
    private static final String POLL_ANSWERS = "poll_answers";

    @Autowired
    private EntityManager entityManager;

    public void clearPostRelatedTables() {
        clearTables(POSTS, POLLS, POLL_ITEMS, POLL_ANSWERS);
    }

    private void clearTables(String... tableNames) {
        entityManager.createNativeQuery("SET REFERENTIAL_INTEGRITY FALSE").executeUpdate();
        Arrays.stream(tableNames)
            .forEach(tableName ->
                entityManager.createNativeQuery("TRUNCATE TABLE " + tableName).executeUpdate()
            );
        entityManager.createNativeQuery("SET REFERENTIAL_INTEGRITY TRUE").executeUpdate();
    }
}
```

예를 들어서, 테스트 중간에 게시글 테이블과 게시글과 관련된 테이블들을 초기화해줘야 하는 경우 `clearPostRelatedTables()` 함수를 호출해주면 됩니다.

```java
entityManager.createNativeQuery("SET REFERENTIAL_INTEGRITY FALSE").executeUpdate();
```

이 코드는 H2 DB에서 참조 무결성 검사를 비활성화합니다. 여기서는 foreign key 관련 제약조건들을 잠깐 비활성화하기 위해 실행되는 쿼리입니다.

```java
entityManager.createNativeQuery("SET REFERENTIAL_INTEGRITY TRUE").executeUpdate();
```

이 코드는 테이블들을 다 청소하고 나서 다시 제약조건들을 활성화합니다.

함수명만 보고도 어떤 작업을 하는 함수인지 알 수 있게 직관적으로 만들려고 노력했습니다.  
그리고 인터페이스는 최대한 제한적으로 뚫어주는게 맞다고 생각해서, `public`으로 함수들을 호출할 때는 구체적으로 어떤 테이블을 초기화할지 지정하지 않도록 구성했습니다.  
만약 `clearTables()`를 외부에서 호출한다면, 해당 함수를 사용할 때마다 db의 테이블 명들도 확인해야하고, 어떤 테이블들을 초기화할지도 생각해야 할 테니까요.

이제 이렇게 구성한 `DbCleaner`를 테스트 클래스에 의존성 주입하고, 데이터베이스 독립성이 필요한 때에 정의된 함수들을 호출해서 사용하면 됩니다.

**main 코드에선 저 클래스를 참조하거나 주입받을 수 있으면 절대 안 됩니다!! (물론 실수로 `clearTables()`가 호출되어도 운영서버는 H2 DB가 아니라 쿼리가 실행되지 못하고 실패할 것 같긴 하지만)**  
**저는 integration test를 위한 소스와 main 소스가 다른 source set으로 분리되어 있고 integration test의 소스에서는 main의 클래스를 참조할 수 있어도 main의 소스에서는 integration test의 클래스를 참조할 수 없게 되어 있어서 편하게 추가했습니다!!**

# 테스트 성능 개선 결과

개선 전:  
![digital_delegation_special_char_err](/assets/images/Spring/2024-01-20-remove-dirtiescontext/test_result_before_refactor.png)  
개선 후:  
![digital_delegation_special_char_err](/assets/images/Spring/2024-01-20-remove-dirtiescontext/test_result_after_refactor.png)  
1분정도 테스트 시간이 줄어들었습니다!  
약 16% 정도 개선되었네요 👍🫡

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
