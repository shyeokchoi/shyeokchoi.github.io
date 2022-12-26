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
`public section` 에 클래스명과 같은 이름을 갖고 반환형이 없는 함수로 선언해 줄 수 있다.  
이때 constructor와 상관 없이 data member를 brace(`{`) 또는 assignment operator(`=`)를 써서 default값으로 초기화해줄 수도 있다.  

Default값 부여 예시)   
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
}
```  
위 코드의 실행 결과는  
  
`c0 c1 c2 c3 d2 d3 d1 d0` 
  
- 참고로, 파괴 순서의 tie breaking은 선입후출식. 즉, 먼저 생성된 객체가 늦게 파괴됨.  

## implicit destructor
만약 프로그래머가 destructor를 명시하지 않으면, 컴파일러가 body가 **비어있는** destructor를 자동으로 생성한다. 따라서 동적으로 할당한 공간을 해제해주지 못하므로 메모리 누수가 발생할 수 있기에 주의해야한다.  

# Copy constructor

syntax:  

```cpp
class ClassName {
  ClassName(const ClassName& other) {
    //copy constructor body
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
**Q) Copy constructor는 언제 호출되는가?**  
**A) 같은 클래스의 다른 객체를 써서 새로운 객체를 만들 때.**  
  
1. `T a = b;` or `T a(b);`  
2. function argument passing by value:  
    C++에서 함수는 `call-by-value`. 그러므로 function에 인스턴스를 제공할 때도 copy constructor 시행되어서 새롭게 만들어지고 그게 argument가 된다.  
    `f(a)` where `a` is of type `T` and `void f(T t)`  
3. function return by value:  
    이런 경우도 copy constructor 써서 새로운 클래스가 생성되고 그것이 반환된다.  
    `return a` inside a function like `T f()` where `a` is an instance of `T`  

## implicit copy constructor
만약 프로그래머가 copy constructor를 명시하지 않으면, 컴파일러가 자동으로 모든 멤버를 다 복사하는 copy constructor를 생성한다.  

**주의!**  
컴파일러가 만든 implicit copy constructor는 `full member-wise copy`를 실행한다.    
따라서, 멤버변수 중 포인터가 있다면 그 포인터의 값(== 주소값)만 복사하는 shallow copy 방식으로 작동한다. 포인터가 가리키던 객체를 복사한 새로운 객체를 생성하고 그 새로운 객체의 주소값을 멤버변수로 갖는 객체가 생성되는 deep copy 방식이 아니다.  
포인터 멤버변수를 dereference할 때 문제가 생길 수 있기 때문에 (포인터 멤버변수가 서로 다른 주소값을 가지고 있는 것으로 착각한다거나, 메모리에서 이미 해제한 객체에 접근하려 한다거나) implicit copy constructor 사용을 지양하고 의도에 맞게 copy constructor를 잘 구현해야 한다.   

예시)  
```cpp  
class Person {
public:
  int age;
  Person(int age): age(age) {}
};

class Student {
public:
  Person* person;
  Student(Person* person): person(person) {};
};
```  
위 코드의 경우 `Student` 클래스는 implicit copy constructor가 생성된다.  
```cpp
int main() {
  Person* personForStudent1 = new Person(24);
  Student student1(personForStudent1);
  std::cout << student1.person->age << std::endl;
  Student student2(student1); //implicit copy constructor called
  delete personForStudent1;
  std::cout << student2.person->age << std::endl;
}
```  
위 `main()` 함수를 시행하면 `24 -494239696` 식으로, 첫번째는 제대로 된 값이 나오지만 두번째는 쓰레기값이 나온다.   
이는 student2 객체의 `person` 멤버변수가 student1 객체의 `person` 멤버변수와 똑같은 주소를 값으로 갖고있었기 때문이다. 그래서, student1을 생성할 때 주었던 `personForStudent1` 만 삭제했는데도 student2 객체의 `person` 멤버변수도 쓰레기값을 가리키게 된 것이다.     

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