---
title: "[Java] ThreadLocal 내부 구조 & 주의사항"

categories:
  - Java
tags:
  - [Java]

toc: true
toc_sticky: true

date: 2024-03-04
last_modified_at: 2024-03-04
---
# ThreadLocal 이란?
Java에서 각 스레드별로 변수를 할당할 수 있게 해줍니다.   

싱글톤으로 구성된 객체(주로 스프링 Bean)가 어떤 state를 간직해야 할 때가 있습니다.  
이때 해당 state에 스레드별로 동시성 문제 없이 해당 state에 접근하고 수정하게 만드는 데 사용할 수 있습니다.  

스프링의 경우 각 HTTP 요청마다 스레드가 할당되므로 유용하게 사용할 수 있을 것입니다.

# 코드 살펴보기
## ThreadLocalMap
해시테이블을 사용하여 구현된 맵입니다.  

맵이기 때문에 key와 value가 무엇인지를 중심으로 보았습니다.  

Key의 타입은 `ThreadLocal`, value는 우리가 `ThreadLocal`에 저장하고자 하는 값의 타입입니다.  

예를 들어서, `ThreadLocal<String>` 식으로 사용하고 싶다면, value가 `String` 타입일 것이고, 프로그래머가 `ThreadLocal.set()`을 호출하여 저장한 값이 바로 그 value가 됩니다.  

각 `ThreadLocal` 객체마다 해시 키가 있는데, 이 키값으로 테이블에 접근해 연계된 value를 가져오는 것입니다.  

중요한 점은, `ThreadLocal`이 스레드마다 생성될 필요는 없다는 것입니다.  
뒤에 나오겠지만 오히려 `ThreadLocal`은 메모리 누수를 방지하기 위해 싱글톤으로 유지되는 것이 낫습니다.  

스레드마다 생성되어 동시성 문제 없이 스레드에 할당된 값을 저장할 수 있게 유지해주는 자료구조는 `ThreadLocalMap` 이고, `ThreadLocal`은 `ThreadLocalMap`에서 적절한 값을 가져오기 위한 key의 역할일 뿐입니다.  

## ThreadLocal.get()
이제 `ThreadLocal.get()`을 보겠습니다.  
![ThreadLocal_get](/assets/images/Java/2024-03-04-java-thread-local/1_ThreadLocal_get.png)  
`L163`을 보면 뭔가 `getMap(t)` 함수를 통해서 `ThreadLocalMap`을 꺼내오고 있습니다.  
![ThreadLocal_getMap](/assets/images/Java/2024-03-04-java-thread-local/2_ThreadLocal_getMap.png)  

위 사진을 보면, 주어진 스레드(현재 스레드)로부터 `threadLocals`라는 `ThreadLocalMap`을 가져오고 있음을 알 수 있습니다.

이 `threadLocals`는 **`Thread`의 멤버 변수**입니다. (초기값은 `null`)  

첫번째 사진 `ThreadLocal.get()`에서 `getMap()`의 결과가 `null`이라면, if 문이 실행되지 않고 바로 `L172`의 `setInitialValue()` 가 호출됩니다.  

이 함수 내에서, 현재 스레드의 `threadLocals`를 초기화하고 설정된 initial value를 넣어줍니다.   
이 initial value는 기본적으로 `null`인데, 원한다면 프로그래머가 `ThreadLocal` 의 자식 클래스를 만들고 `initialValue()` 함수를 오버라이드해서 초기값을 설정해줄 수 있습니다.  

여기서 현재 실행중인 스레드의 `threadLocals`가 초기화됩니다.  

만약 이미 이전에 `ThreadLocal.get()`이나 `ThreadLocal.set()`을 호출한 적이 있어서 `threadLocals`가 초기화된 적이 있다면, 이 `threadLocals` (얘는 해시맵)에 현재 `ThreadLocal` 자체를 key로 하여 접근해서 저장된 value를 가지고 옵니다.   
## ThreadLocal.set()
![ThreadLocal_set](/assets/images/Java/2024-03-04-java-thread-local/3_ThreadLocal_set.png)   
만약 현재 스레드에 `ThreadLocalMap`이 초기화되지 않았다면, 초기화해주고 argument로 전달된 값을 넣어줍니다.  
이미 현재 스레드가 `ThreadLocalMap`을 가지고 있다면, 이 `ThreadLocal`을 key로 `ThreadLocalMap`에 value를 집어넣어줍니다.  

# 사용시 주의점
## 보안 문제
스프링 프레임워크를 사용해 웹 애플리케이션을 개발하는 상황을 가정하겠습니다.  

1. 유저A가 `ThreadLocal`이 사용된 어떤 API를 호출하면서 자신의 정보를 `ThreadLocal`을 통해 현재 스레드의 `threadLocals`에 저장  
2. 유저A의 요청이 완료되며 스레드를 스레드 풀에 반납  
3. 유저B가 어떤 API를 호출하면서 유저A가 반납한 스레드를 할당받음  
4. 유저B가 요청한 API에 `ThreadLocal`의 정보를 `get()` 하는 로직이 포함되어 해당 값이 반환

이 경우, 유저B는 유저A가 저장한 정보를 반환받게 되는 보안 문제가 발생합니다.  

이 문제를 해결하기 위해, 스레드를 스레드 풀에 반납할 때는 `ThreadLocal.remove()` 함수를 활용해야 합니다.  
![ThreadLocal_remove](/assets\images\Java\2024-03-04-java-thread-local\4_ThreadLocal_remove.png)

위 함수를 호출해 `ThreadLocal`이 해당 스레드의 `threadLocals` 해시맵에 저장한 값을 해시맵에서 삭제해줘야 합니다.  

## 메모리 누수
위의 보안 문제와 마찬가지로, 스레드가 재사용되는 환경에서 문제가 됩니다.  

`threadLocals`는 각 스레드 자료구조에 연결된 해시맵입니다.   
따라서, 제때 entry를 삭제해주지 않는다면, `threadLocals` 테이블에 value 값이 계속 남아있게 됩니다.  
더이상 사용하지 않는 객체가 메모리에 남아있기 때문에 메모리 누수가 일어났다고 볼 수 있습니다.   

**하지만, 메모리 누수의 정도가 계속해서 증가하지는 않습니다.**  
C/C++ 등의 언어를 사용할 때 할당받은 힙을 제대로 해제해주지 않아서 계속 메모리 사용량이 증가하다가 결국 `Out Of Memory` 에러가 발생하는 것과 달리, 메모리 사용량이 한도 없이 계속 늘어나지는 않는다는 의미입니다.  

이는, 각 `ThreadLocal`의 해시값이 key가 되어 해당 스레드의 `threadLocals`의 value에 접근하기 때문입니다.  
각 API 요청마다 스레드 하나를 할당하고, 해당 요청이 끝나면 스레드를 풀에 반환한다는 가정하에 예를 들어 보겠습니다.  

1. 유저A가 `ThreadLocal.set()`을 호출해 객체 저장하고 사용    
2. 유저A의 요청이 완료되며 스레드를 스레드 풀에 반납  
3. 유저B가 어떤 API를 호출하면서 유저A가 반납한 스레드를 할당받음  
4. 유저B가 `ThreadLocal.set()`을 통해서 객체 저장  

위 상황을 가정하겠습니다.   

그러면, 유저A가 저장한 객체는, 유저B가 객체를 저장하면서 맵에서 오버라이팅되어 `threadLocals`로부터의 reference를 잃게 되고, GC의 대상이 됩니다.  

즉, 잘못된 `ThreadLocal` 사용으로 인한 메모리 누수 크기는 (스레드 풀 크기) * (저장하는 객체 크기)로 제한된다고 할 수 있습니다.  

**물론, 이건 `ThreadLocal` 객체가 싱글톤으로 잘 유지될 때의 이야기입니다.**  
만약 `ThreadLocal`을 반복적으로 생성하고, 이 객체를 통해 `threadLocals`에 정보를 저장하고, `ThreadLocal.remove()`를 호출해주고 있지 않다면.. 제한이 없는 누수가 발생해 결과적으로 `Out Of Memory` 에러가 발생할 것입니다.  

`ThreadLocal`이 생성될 때마다 새로운 해시키가 발급되기 때문입니다.  
이 경우 `ThreadLocal.set()`이 호출될 때 기존 엔트리를 삭제하고 그 자리를 대체하지 **못합니다**.    
오히려 `threadLocals`에 계속 엔트리가 추가될 것이고 해시맵에 데이터가 점점 차오를 것입니다.
