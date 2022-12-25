---
title:  "[Java] Static Binding vs. Dynamic Binding"

categories:
  - Java
tags:
  - [Java]

toc: true
toc_sticky: true
 
date: 2022-12-24
last_modified_at: 2022-12-24
---
`object.func()` 가 호출되었을 때, 컴파일러 또는 JVM은 `object` 를 보고 어떤 `func()` 를 호출할지 결정한다.   
이 결정 방식에는 두 가지가 있다.  
컴파일러가 결정한다면 Static Binding이라 부르고, JVM이 결정한다면 Dynamic Binding이라 한다.  
## Static Binding
컴파일 시점에 이미 어떤 타입을 참조해야할지 결정.  

이 경우는 Explicit Type을 기준으로 어떤 클래스를 참조할지 결정한다. 즉, 선언할 때 변수의 타입이 중요하다.  
Override된 함수를 제외하고 나머지 함수들은 모두 static binding을 따른다.  
```java
class Parent() {
    static void print() {
        System.out.println("Parent.print()");
    }
}

class Child extends Parent {
    static void print() {
        System.out.println("Child.print()");
    }
}
```

```java
public static void main(String[] args) {
		Parent parent = new Parent();
		Parent child = new Child();
		parent.print();
		child.print();
}
```

위 main 함수의 Output은   
> Parent.print()  
> Parent.print()  
  
`print()` 함수는 `static` 으로 선언되어 있기 때문에, static binding을 따른다. (override된 함수 제외하면 전부 static binding이다!) 그러므로 `child` 가 실제로 어떤 클래스의 인스턴스인지와는 상관 없이 컴파일 시점에 `child`의 explicit type인 `Parent` 클래스에 선언된 `print()` 를 호출하는 것으로 정해져있기 때문이다.   

**참고**  

명시적으로 이루어지는 type casting은 explicit type을 바꿀 뿐, actual type에는 영향을 미치지 않는다.  
따라서 static binding에 의해 어떤 메서드를 호출할지를 바꿔주고 싶다면 type casting을 이용하면 되지만, casting후에도 dynamic binding의 결과는 여전히 똑같다.  
  
예시)  
```java
class Point { static int x = 2; }
class Test extends Point {
  static double x = 4.7;
  void printX() {
    System.out.println(
      x + " " + super.x + " " + ((Point)this).x);
}
```

```java
public static void main(String[] args) {
		Test test = new Test(); 
		test.printX();
}
```  
이 경우 output은 `4.7 2 2`   
Type casting으로 `Test`의 `x`가 아닌 `Point`의 `x`를 참조하게 되었기 때문.  

## Dynamic Binding
컴파일 시점에는 해당 변수의 타입을 알 수 없고, 런타임에 JVM이 결정.  
이 경우는 Implicit Type을 기준으로 어떤 클래스를 참조할지 결정한다. 즉, “실제로” 어떤 클래스의 인스턴스인지가 중요하다.  
Override 된 함수는 dynamic binding 방식으로 어떤 클래스를 참조하여 함수를 호출하게 될지 결정된다.  
위의 예시와 달리 이번에는 overriding 해서 구현해보자.  

```java
class Parent() {
    void print() {
        System.out.println("Parent.print()");
    }
}

class Child extends Parent {
    @Override
    void print() {
        System.out.println("Child.print()");
    }
}
```

```java
public static void main(String[] args) {
		Parent parent = new Parent();
		Parent child = new Child();
		parent.print();
		child.print();
}
```

Output은  
> Parent.print()  
> Child.print()  

Override 된 함수는 dynamic binding에 따라 actual type을 런타임에 참조하여 함수를 호출하기 때문이다.   
## 최종적인 예시 (Combination of Overloading, Overriding, and Hiding)

```java
class Point {
    int x = 0;
    int y = 0;
    
    void move(int dx, int dy) {
        x += dx;
        y += dy;
    }
		
		int getX() {
        return x;
    }

    int getY() {
        return y;
    }

    static void show(int x, int y) {
        System.out.println("(" + x + ", " + y + ")");
    }

    static void show(float  x, float y) {
        System.out.println("(" + x + ", " + y + ")");
    }
}

class RealPoint extends Point {
    float x = 0.0f;
    float y = 0.0f; // x, y: Hiding

    void move(int dx, int dy) { //overriding
        move((float)dx, (float)dy); 
    }

    void move(float dx, float dy) { //overloading
        x += dx;
        y += dy;
    }

    int getX() { //overriding
        return (int)Math.floor(x);
    }
    
    int getY() { //overriding
        return (int)Math.floor(y);
    }
}
```

위와 같이 클래스를 정의하고,  

```java
public static void main(String[] args) {
		RealPoint rp = new RealPoint();
		Point p = rp;
		
		rp.move(1.71f, 4.14f);
		p.move(1, -1);
		
		Point.show(p.x, p.y);
		Point.show(rp.x, rp.y);
		Point.show(p.getX(), p.getY());
		Point.show(rp.getX(), rp.getY());
}
```

`main` 함수 실행 결과는   
> (0, 0)  
> (2.71, 3.14)  
> (2, 3)  
> (2, 3)  

`main` 함수를 본다. 이 함수에는 RealPoint 클래스의 객체는 단 하나만 존재한다. 이것을 A라고 하자. 

이 하나의 A를 레퍼런스(C/C++로 생각하면 포인터) 2개가 가리키고 있다. 하나는 rp, 다른 하나는 p라는 이름으로 선언되어 있다. 

rp는 A가 RealPoint의 객체라고 생각한다. p는 A가 Point의 객체라고 생각한다.

먼저, `rp.move(1.71f, 4.14f)`는 overriding된 함수이므로 dynamic binding을 따른다. 즉, RealPoint에 선언된 `move` 메서드를 실행시켜 A의 메모리 공간 상 RealPoint에 해당하는 x, y를 각각 1.71, 3.14 만큼 증가시킨다. 

(RealPoint 객체를 생성할 때, 힙에는 부모인 Point 객체와 자식인 RealPoint 객체가 모두 생성되어 있을 것이다. 이 중 RealPoint객체의 x, y 값이 증가된다는 것)

`p.move(1, -1)`도 마찬가지이다. p는 A가 Point의 객체라고 알고 있지만, `move(int dx, int dy)`는 RealPoint에서 overriding한 함수이므로 Point의 `move` 함수를 함부로 실행시킬 수 없다. 런타임에 실제로 A가 Point의 객체인지 RealPoint의 객체인지 확인해봐야 어떤 클래스의 `move` 함수를 실행시킬지 결정할 수 있다. 당연히 A는 RealPoint 객체이므로 RealPoint에 선언된 `move`를 실행시켜 A의 메모리 공간 상 RealPoint에 해당하는 x, y를 각각 1, -1 만큼 증가시킨다.

`Point.show(p.x, p.y)`를 본다. p는 A가 Point의 객체라고 생각한다. Hiding은 static binding을 따르므로 컴파일 시점에 그냥 A의 메모리 공간 상 Point에 해당하는 x, y를 참조하도록 결정할 수 있다. `rp.move(1.71f, 4.14f)` 와 `p.move(1, -1)` 둘 다 dynamic binding에 따라 작동해, A의 Point 부분에 해당하는 메모리 공간은 건들지 않았기 때문에 default 값인 (0, 0)이 출력되었다. 

`Point.show(rp.x, rp.y);` 는 반대로 static binding에 따라 A의 메모리 공간 상 RealPoint가 가지고 있는 x, y를 참조했기 때문에 (2.71, 3.14) 가 출력되었다.

`Point.show(p.getX(), p.getY())` 와 `Point.show(rp.getX(), rp.getY())` 는 모두 overriding된 함수를 호출하는 dynamic binding이므로 (2, 3)이 출력되었다.