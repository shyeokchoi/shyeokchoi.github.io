---
title:  "[C++] Special Member Functions"

categories:
  - C++
tags:
  - [C++]

toc: true
toc_sticky: true
 
date: 2022-12-25
last_modified_at: 2022-12-25
---

# Constructor
당연히 `public section` 에 있어야 한다.  
Data member를 constructor body에서 `=` operator를 써서 초기화해줄 수 있다.  
Data member에는 brace(`{`) 또는 assignment operator(`=`)로 default 값들을 설정해줄 수 있다.  

예시)  
```cpp
class S {
public:
    int n = 7;
    std::string s1 {"abc"};
    float f = 3.141592;
    std::string s2 = "DEF";
};
```
## member initializer list  
Constructor signature 뒤에 `:` 에 이어서 따라오는 comma-separated list.  
Constructor body보다 먼저 실행된다.  

예시)
```cpp
class Rectangle {
    int width, height;
public:
	Rectangle(int x, int y): width(x), height(y) { } //이게 member-initializer-list
	int area() { 
		return width * height; 
	}
};
```  
만약, parameter name과 data member name이 같으면, `this->`를 사용해 명확하게 표현해줘야 한다.  

예시)  
```cpp
class X {
public:
	int a, b, i, j;
	// i is different from this->i
	X(int i): b(i), i(i-1), j(this->i) { }
};
```  
위 예시에서 `X x(9);`로 객체를 생성하면, `x.b`, `x.i`, `x.j` 값은 차례로 9, 8, 8  
만약 default 값과 member initializer list가 동시에 제공되면, default 값을 무시한다.  

## Default constructor
Parameter list가 비어있거나 모든 parameter들에 default값이 주어진 constructor  
  
parameter list 비어있는 예시)

```cpp
class A {
public:
	int x; int y;
	A() { 
		x= 1;
		y = 2; 
	}
};
```  
모든 parameter들에 default값 주어진 예시)  
```cpp
class A {
public:
	int x;
	int y;
	A(int x = 5, int y = 10) {
		this->x = x;
		this->y = y; 
	}
};
```
  
## implicit constructor
만약 프로그래머가 constructor를 명시하지 않으면, 컴파일러가 body가 비어있는 constructor를 자동으로 생성한다.  
# Destructor
Constructor와 마찬가지로 `public section`에 정의된다.  

어떤 객체의 lifetime이 끝났을 때 호출된다.  
1. delete  
2. End of scope  
해당 객체가 사용하던 resource를 해제하는 역할을 한다.  
```cpp
class ClassName {
	~ClassName() {
		//destructor body
	}
};
```

```cpp
#include <iostream> 
class A {
public:
	int i;
  A (int i): i(i) {
    std::cout << "c" << i << ' ';
  }
	~A() {
    std::cout << "d" << i << ' ';
	} 
};

A a0(0);

int main() {
  A a1(1);
	A* p;
  { // nested scope
    A a2(2);
    p = new A(3);
  } // a2 out of scope
  delete p;
  // calls the destructor of p
}
```  
위 코드의 실행 결과는  
  
`c0 c1 c2 c3 d2 d3 d1 d0` 
  
- 참고로, 파괴 순서의 tie breaking은 선입후출식. 즉, 먼저 생성된 객체가 늦게 파괴됨.
## implicit destructor
만약 프로그래머가 destructor를 명시하지 않으면, 컴파일러가 body가 비어있는 destructor를 자동으로 생성한다.  

# Copy constructor

syntax:

```cpp
class ClassName {
	ClassName(const ClassName& other) {
		//Copy constructor body
	}
};
```

예시)

```cpp
class A {
public:
    int n;
    A(int n = 1) : n(n) { }
    A(const A& a) : n(a.n) { } //이게 copy constructor
};

#include <iostream>

int main() {
  A a1(7); 
	A a2(a1); // == A a2 = a1;
  std::cout << a2.n << std::endl; // 7
}
```  
Copy constructor는 언제 호출되는가?  
⇒ 같은 클래스의 다른 객체를 써서 새로운 객체를 만들 때.  
  
1. `T a = b;` or `T a(b);`  
2. function argument passing by value:  
    C++에서 함수는 `call-by-value`. 그러므로 function에 인스턴스를 제공할 때도 copy constructor 시행되어서 새롭게 만들어지고 그게 argument가 된다.  
    `f(a)` where `a` is of type `T` and `void f(T t)`  
3. function return by value:  
    이런 경우도 copy constructor 써서 새로운 클래스가 생성되고 그것이 반환된다.  
    `return a` inside a function like `T f()` where `a` is an instance of `T`  

## implicit copy constructor
만약 프로그래머가 copy constructor를 명시하지 않으면, 컴파일러가 자동으로 모든 멤버를 다 복사하는 copy constructor를 생성한다.  

**!!!!!!Deep copy, shallow copy 부분 ppt 다시보기 강의자료 p.42~ !!!!!!**

# Copy assignment operator
일종의 연산자 오버로딩.  
copy constructor는 instantiation(`Test t2 = t1`)에서 사용되는 반면 copy assignment operator는 assignment(`t2 = t1`)에서 사용됨  

syntax)  
```cpp
class T {
	T& operator= (const T &t) {
		//copy assignment
		return *this; //for chaining, return *this
	}
};
```