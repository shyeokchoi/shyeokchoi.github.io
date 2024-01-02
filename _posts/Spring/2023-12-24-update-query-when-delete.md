---
title: "[Spring JPA] @OneToMany에서 자식 테이블의 row를 삭제할 때 update 쿼리가 나가는 문제"

categories:
  - Spring
tags:
  - [Java, Spring, JPA]

toc: true
toc_sticky: true

date: 2023-12-24
last_modified_at: 2023-12-24
---

# 문제상황

어떤 설문조사를 실행하는 비즈니스 로직을 구현하기 위한 `Poll` 엔티티가 있고, 그 `Poll` 엔티티와 `@OneToMany` 관계를 갖고 있는 `PollItem` 엔티티가 있습니다.  
`Poll`이 설문조사라면, `PollItem`은 설문조사에서 선택할 수 있는 선택지인 것입니다.

```java
@Entity
@Table(name = "polls")
@Getter
@Setter
public class Poll {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "title")
    private String title;

    @BatchSize(size = 100)
    @OneToMany(cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @JoinColumn("poll_id")
    private List<PollItem> pollItemList;
}
```

```java
@Entity
@Table(name = "poll_items")
@Getter
@Setter
public class PollItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "text")
    private String text;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "poll_id")
    private Poll poll;
}
```

위의 상태에서 저는 통합테스트를 작성하며 테스트간의 독립성을 유지하기 위해 매 테스트가 끝난 후 해당 테스트에서 생성되었던 `Poll`을 DB에서 삭제해주려 했습니다.

```java
Poll poll = post.getPoll(); // 게시글을 의미하는 post 엔티티에서 poll 엔티티를 꺼내온다.
pollItemRepository.deleteAll(poll.getPollItemList());
pollRepository.delete(poll);
```

이렇게요.  
그러자,

```sql
update poll_items set poll_id=null where poll_id=?
```

이런 쿼리가 나가면서

```
could not execute statement [NULL not allowed for column "POLL_ID";
```

위와 같은 에러가 발생했습니다.  
분명 저는 `PollItem`을 delete 하려고 했는데, `poll_items` 테이블에서 해당 `PollItem`들을 삭제해주는 것이 아니라,  
`poll_id` 컬럼을 null로 설정해주려고 했고, 그러면서 DB의 제약조건(`poll_id`가 null이 될 수 없다는) 에 걸려서 에러가 났던 것입니다.

# 원인

이는 레거시를 작성하신 분께서 연관관계 매핑을 제대로 하지 않으셔서 발생한 문제였습니다.  
잘 보시면, 양쪽 엔티티 모두에 `@JoinColumn` 어노테이션이 붙어 있습니다.

분명 일반적이지 않은 매핑 방식이고 이것때문에 문제가 생긴다는 심증은 있었지만, 확실한 이유를 파악하고 싶었습니다.

일단, 생성되는 쿼리를 처음부터 끝까지 확인하기 위해 DB에서 `poll_items` 테이블의 `poll_id` 컬럼에 대해 not null 제약조건을 뺐습니다.  
그러자 아래와 같은 쿼리가 나가는 것을 확인했습니다.

```sql
update
	poll_items
set
	poll_id=null
where
	poll_id=?

delete
from
	poll_items
where
	id=?
```

여기에서 뒤의 `delete` 문은 `Poll` 엔티티의 `pollItemList` 필드에 달린 `CascadeType.ALL` 설정 때문임을 해당 옵션을 제거해보고 확인할 수 있었습니다.  
그렇다면 문제는 왜 앞의 `update` 문이 나가느냐 인데...

관련 키워드로 구글링을 하다가 다음과 같은 글을 발견했습니다.  
[링크](https://homoefficio.github.io/2019/04/28/JPA-%EC%9D%BC%EB%8C%80%EB%8B%A4-%EB%8B%A8%EB%B0%A9%ED%96%A5-%EB%A7%A4%ED%95%91-%EC%9E%98%EB%AA%BB-%EC%82%AC%EC%9A%A9%ED%95%98%EB%A9%B4-%EB%B2%8C%EC%96%B4%EC%A7%80%EB%8A%94-%EC%9D%BC/)

> 일대다 조인컬럼 방식에서 children.remove(child)를 실행해서 children 쪽의 레코드 삭제를 시도하면 실제 쿼리는 delete가 아니라 해당 레코드의 parent_id에 null을 저장하는 update가 실행된다.  
> 의도와 다르게 동작한 것 같아서 이상해보이지만, 일대다 단방향 매핑에서 children.remove(child)는 사실 child 자체를 삭제하라는 게 아니라 child가 parent의 children의 하나로 존재하는 관계를 remove 하라는 것이다.  
> 따라서 child 자체를 delete 하는 게 아니라 parent_id에 null 값을 넣는 update를 실행하는 게 정확히 맞다.

이 글에서 말하는 상황인, 일대다 단방향 매핑에서 발생하는 문제가 저희 프로젝트 코드에서도 발생하고 있는 것 아닐까? 하는 생각이 들었습니다.

다만, Hibernate나 JPA 공식 문서를 봐도, 애초에 `@JoinColumn`을 양쪽에 붙이는 케이스는 설명이 없고 고려하지 않는 것 같아 그냥 unexpected behavior가 발생했다고 생각하게 되었습니다.

이렇게 양쪽에 `@JoinColumn`을 붙이는 경우는 예시나 설명이 너무 없어 직접 Hibernate 코드를 하나하나 뜯어보지 않는 한 정확한 원인을 파악하지 못할거라 생각합니다.  
또, `@JoinColumn`이 양쪽에 붙는거 자체가 잘못된 용법이기때문에 무슨 일이 있었는지를 파악하는 데에 큰 의미는 없을것 같습니다.  
하지만, 왜 위와 같은 일이 일어났는지 한 번 생각해보고 싶었습니다.

<span style="color:orange">**아래 내용은 주니어 개발자인 제가 나름대로 고민해보면서 실험하고 결론내린 내용입니다.**</span>  
<span style="color:orange">**JPA에 대한 이해가 부족해 틀린 내용이 있을 수 있고, Hibernate코드를 직접 뜯어보지 않고 현상만을 가지고 추측한 내용이기에 이상하게 결론내린 부분이 있을 수 있습니다.**</span>  
<span style="color:orange">**부정확한 정보를 건너뛰실 분들은 바로 `#해결`로 가시길 바랍니다.**</span>

혹시 양방향 연관관계가 생성된 게 아니라 단방향 연관관계 두 개가 생성된 것이었을까요?  
그렇다면, 지금 생성된 연관관계의 주인이 누구인지 알아봐야 할 것입니다.

## `Poll`

```java
final Poll poll = new Poll();

poll.setTitle(someAlphanumericString(10));

List<PollItem> pollItems = new ArrayList<>();

IntStream.range(0, 2).forEach((i)-> {
    PollItem pollItem = new PollItem();
    pollItem.setText(someAlphanumericString(10));
    pollItems.add(pollItem);
});

poll.setPollItemList(pollItems); // **************************** 여기!!
entityManager.flush();
```

위와 같은 코드로 `Poll`과 `PollItem`들을 초기화해서 DB에 저장하는 로직이 있다고 하겠습니다.  
만약 `Poll`이 연관관계의 주인이 아니라면, `PollItem`에 해당하는 row는 생성되어서는 안 됩니다. 즉, `insert into poll_items ...` 식의 쿼리가 나가면 안 됩니다.  
하지만, 다음과 같은 쿼리가 실행되는 것을 볼 수 있습니다.  
`insert into poll_items (created_at,deleted_at,poll_id,status,text,updated_at,id) values (?,?,?,?,?,?,default)`

## `PollItem`

반대로, `PollItem` 쪽의 경우, foreign key가 정의되어 있는 테이블이고

```java
PollItem pollItem = new PollItem();
pollItem.setPoll(poll); // **************************** 여기!!
```

위의 코드를 실행시킬 경우 foreign key가 관리된다는 점에서 `PollItem`도 연관관계의 주인 역할을 함을 알 수 있었습니다.

## 결론

따라서, 양쪽에 `@JoinColumn`을 붙임으로써 양방향 연관관계 1개가 아니라, 단방향 연관관계 2개가 생성되었다고 추론해볼 수 있습니다.  
그렇다면, `Poll`의 입장에선 일대다 단방향 매핑이기 때문에 child를 삭제할 때 위 블로그 글에서 언급하는, update 쿼리가 실행되는 문제가 발생하였다고 추론하였습니다.

# 해결

원인을 파악하는 것에 비해 해결방법은 간단합니다.  
정상적인 양방향 매핑을 해주면 됩니다.  
Many 쪽을 연관관계의 주인으로 설정해주고(외래키가 있는 곳이니까),  
One 쪽을 `mappedBy`를 통해 inverse로 설정해줍니다.

```java
@Entity
@Table(name = "polls")
@Getter
@Setter
public class Poll {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "title")
    private String title;

    @BatchSize(size = 100)
    @OneToMany(mappedBy = "poll", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    private List<PollItem> pollItemList;
}
```

그러자, (원했던대로) 다음과 같은 쿼리만 실행됩니다.

```sql
delete
from
	poll_items
where
	id=?
```

# 배운 점

정확한 원인은 파악을 하지 못해서 아쉽지만 그래도 공식문서도 뒤져보고 테스트코드도 여러 방식으로 작성해보면서 많이 배울 수 있었습니다.

- `연관관계의 주인`의 개념
  - 어느쪽을 주인으로 설정해야 하는지
  - 주인이 아닌 쪽(inverse side)에서 작업할 때 어떤 점을 주의해야 하는지
- 부모쪽에만 `@OneToMany`로 단방향 매핑을 할 경우, 부모를 통해서 자식을 삭제할 때 delete가 아니라 update 쿼리가 나간다는 점
- `CascadeType.ALL`과 `orphanRemoval=true`의 차이

# 부족한 점

물론, 양쪽에 `@JoinColumn`을 붙이는 것이 정의되지 않은 방식이라 그런 면도 있겠지만,  
여러 방식으로 테스트코드를 작성하고 코드를 바꿔가며 테스트하면서, JPA가 제 예상과 다른 쿼리를 생성해낼 때가 많았습니다.  
그래서 제가 아직 JPA에 대한 이해도가 부족하다는 것을 느꼈습니다.  
JPA의 동작을 더 잘 이해해서 일관적인 원칙과 논리하에서 JPA의 동작을 완벽하게 예측할 수 있을 정도로 잘 이해하고 싶다는 생각이 들었습니다.  
책이나 강의를 찾아보거나 여유가 있을 때 Hibernate 코드를 직접 읽어보는 시간을 가져봐야겠습니다.
