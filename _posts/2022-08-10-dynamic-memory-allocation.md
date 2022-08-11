---
title:  "[C]  Dynamic Storage Allocation"

categories:
  - C
tags:
  - [C, csapp]

toc: true
toc_sticky: true
 
date: 2022-08-10
last_modified_at: 2022-08-10
---
# Dynamic Storage Allocation 이란?
C언어에선 배열의 크기가 컴파일시에 결정되고 고정된다. 하지만 때로는 런타임에 배열의 크기를 정해주고 싶거나 이미 정해진 배열의 크기를 바꾸고 싶을 때가 있다. 이때 필요한 것이 `dynamic memory allocation`이다.  
C에서 지원하는 메모리 할당 함수는 크게 세 가지다.
- `malloc()`: 메모리를 할당하지만 초기화는 하지 않음.
- `calloc()`: 메모리를 할당하고 전부 `0`으로 초기화함.
- `realloc()`: 할당된 메모리 공간의 크기를 늘이거나 줄임.   
  
위와 같은 `memory allocation function`이 호출될 때, 컴퓨터는 이 메모리 공간에 어떤 자료형이 담길지 알 수가 없으므로, 포인터의 타입을 확정해서 반납할 수 없다. 그래서, 위의 함수들의 반환 타입은 `void *`, 즉 `generic pointer`이다.   
만약 지정된 크기의 메모리 공간을 반환할 수 없다면, `null pointer`가 반환된다.  
  
- **주의!** `memory allocation function`의 반환값이 `null pointer`인지 확인하는 것은 프로그래머의 몫이다. 만약 제대로 확인하지 않아서 `null pointer`를 통해 메모리에 접근하려는 시도를 하게 되면, 프로그램이 비정상적으로 종료되거나 예측하지 못한 방식으로 작동하게 된다.   
  
  
# Dynamically Allocated Arrays
`String`은 `char`들의 배열이므로 `memory allocation function`이 유용하게 사용될 수 있다. 특히, 사용자로부터 문자열을 입력받는 경우, 그 길이가 얼마가 될지 예측하기 어렵다. 따라서 런타임에 메모리를 동적으로 할당해주는 것이다.  
  
- **주의!** 문자열에 메모리 공간을 할당할 때에는 항상 마지막에 들어올 `null character` 까지 생각해서 1 바이트 더 할당해줘야 한다.
  
문자열 외에 다른 요소를 동적으로 할당된 배열에 저장하는 경우에는 자료형의 크기가 `1 byte`가 아닐 확률이 아주 높기 때문에 `sizeof` 연산자를 활용해서 필요한 공간을 계산해주어야 한다. 이때, 항상 `sizeof` 연산자를 사용하는 것이 좋은데, 시스템마다 같은 자료형이라도 크기가 다를 수 있기 때문이다. 예를 들어서, `long`이 `8 byte` 크기를 갖는 64bit 운영체제와 달리 32bit 운영체제에서는 `long`이 `4 byte` 크기를 갖는다.   

## malloc
```c
void *malloc(size_t size);
```  
여기서 `size_t`는 C 라이브러리에 포함된 `unsigned integer` 타입이다.  
`malloc()`은 `size` 바이트 크기의 공간을 할당하고 그 시작주소를 가리키는 포인터를 반환한다. 예를 들어서 `n`개의 `int`를 위한 공간을 할당하고 싶다면 다음과 같이 하면 된다.  
  
```c
int *a;
a = malloc(n * sizeof(int));
```

## calloc
```c
void *calloc(size_t nmemb, size_t size);
```
기본적인 사용법은 `malloc()`과 비슷하다.  
예를 들어,  
```c
int *a;
a = calloc(n, sizeof(int));
```
식으로 사용된다.  
`calloc()`은 지정된 메모리 공간을 `0`으로 초기화한다는 특성때문에, 꼭 배열을 할당할 때 뿐만 아니라 원하는 공간을 초기화하기 위해서도 사용된다.  
```c
struct point {int x, y;} *p;
p = calloc(1, sizeof(struct point)};
```
위와 같은 코드를 통해 `p`는 `x`와 `y`가 `0`으로 초기화된 구조체를 가리키게 되는 것이다.

## realloc
```c
void *realloc(void *ptr, size_t size);
```
`realloc()`을 호출할 때, `ptr`는 항상 `memory allocation function`, 즉 `malloc()` `calloc()` `realloc()` 함수들의 결과로 반환된 포인터여야 한다.  
`size`는 새롭게 할당될 메모리 공간의 크기를 의미한다.  
  
- **주의!** `malloc()` `calloc()` `realloc()` 함수들의 결과로 반환된 포인터가 아닌 다른 값을 첫번째 인자로 넘겨주는 것은 정의되지 않은 동작이다.  
   
`realloc()`을 사용하는 규칙은 다음과 같다.
- `realloc()`으로 새롭게 할당된 공간은 초기화되지 않는다.
- 더 이상 공간을 할당할 수 없다면, `null pointer`를 반환한다.
- 첫번째 인자로 `null pointer`를 넘겨줄 경우, `malloc()`과 똑같이 작동한다.
- 두번째 인자로 `0`을 넘겨줄 경우, 해당 메모리 공간을 해제한다.  
  
`realloc()`이 할당된 공간을 줄일 때는 항상 그 자리에서 줄인다. 즉, 굳이 비효율적으로 요소들을 다른 주소로 옮기지 않는다.  
늘릴 때는 가능하다면 이동 없이 늘린다. 하지만 연속하는 메모리 주소들이 선점된 경우에는 원래의 공간에 할당되어 있던 요소들을 새롭게 할당할 공간에 복사하는 방식으로 더 큰 공간을 할당한다.  
이는 python의 `list`나 java의 `ArrayList`와 같은 방식이다.   
  
- **주의!** 앞서 언급했듯 `realloc()` 이후에는 해당 배열에 할당된 메모리 주소가 바뀌었을 수 있기 때문에, 관련된 포인터들을 업데이트해줘야 한다.  

# Deallocation
```c
//p, q는 포인터
p = malloc(...);
q = malloc(...);
p = q;
```
위와 같은 코드가 있다면, `p`가 원래 가리키고 있던 메모리 공간에 우리는 다시는 접근할수 없게 된다. 이처럼 더이상 접근 불가능한 메모리 공간을 `garbage`라고 하고, 이런 `garbage`를 남겨두는 프로그램은 `memory leak` 문제를 유발한다고 표현한다. java나 python 등은 `GC(Garbage Collection)`을 지원해 알아서 이런 메모리 누수 문제를 해결해주지만, C에서는 프로그래머의 의무이다.  
이런 작업을 해주는 것이 바로 `free()` 함수다.
```c
void free(void *ptr);
```
- **주의!** 단, 이때 인자로 넘어가는 `ptr`은 `memory allocation function`에서 반환된 포인터여야 한다. 다른 객체의 포인터를 넘기는 것은 정의되지 않은 동작이다.   

- Dangling Pointer Problem
  - `free()` 함수로 해제한 메모리 공간을 가리키고 있던 포인터를 `dangling pointer`라고 한다. 이 포인터는 분명히 특정한 주소값을 가지고 있지만, 더 이상 유효한 메모리 주소가 아니다. 그걸 까먹고 이 주소로 접근하거나 해당 메모리 주소의 내용을 수정하는 것은 정의되지 않은 동작이다. 큰 문제로 이어질 수 있기 때문에 주의해야 한다.
