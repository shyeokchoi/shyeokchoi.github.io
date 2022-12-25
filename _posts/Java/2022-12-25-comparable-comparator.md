---
title:  "[Java] Comparable Interface vs. Comparator Interface"

categories:
  - Java
tags:
  - [Java]

toc: true
toc_sticky: true
 
date: 2022-12-25
last_modified_at: 2022-12-25
---
# Comparable vs. Comparator

## Comparable

User-defined object를 비교 가능하도록 만드는 interface이다.  
`Comparable` 을 따르는 객체는 `Collections.sort()`로 정렬할 수 있다.  
이 interface 안에는 `int compareTo(T obj)` 메서드가 정의되어 있다. 프로그래머는 이 `compareTo()` 메서드를 직접 구현해서 사용하게 된다.  

`obj1.compareTo(obj2)` 에서  
- obj1 > obj2 : positive int 반환  
- obj1 = obj2 : 0 반환  
- obj1 < obj2 : negative int 반환  
  
**기본적으로 `Collections.sort()`는 더 큰걸 뒤로 보낸다 (= 오름차순으로 정렬).**   
따라서 `compareTo()`를 구현할 때 `obj1`과 `obj2`를 비교해서 `obj1`이 **뒤로** 가길 원하는 상황에 positive int를 반환하도록 하면 됨.  
## Comparator
`compareTo` 보다 더 복잡한 서순을 구현하기에 적합하다.  
`Comparable` 은 객체들간의 natural ordering을 따지기 위해 구현한다면, `Comparator`는 special ordering을 따지기에 적합하다.  
`compare` 메서드에다가 순서를 어떻게 정할지를 구현해주면 된다.  
`compare(obj1, obj2)` 에서  
- obj1 > obj2 : positive int 반환  
- obj1 = obj2 : 0 반환  
- obj1 < obj2 : negative int 반환  
  
마찬가지로, `obj1`과 `obj2`를 비교해서 `obj1`이 **뒤로** 가길 원하는 상황에 positive int를 반환하도록 하면 됨.  
  
예시)  
```java
class NameComp implements Comparator<Player> {
    public int compare(Player e1, Player e2) { 
        return e1.getName().compareTo(e2.getName()); 
    }
}

class IdComp implements Comparator<Player>{
    public int compare(Player e1, Player e2){ 
        return e1.getId().compareTo(e2.getId());
    }
}

class Player {
    String name; 
    public String getName() { return name; }

    int id;
    public Integer getId() { return id; }

    public Player(String name, int id) {
        this.name = name; this.id = id; 
    }

    @Override
    public String toString() {
        return name + '(' + id + ')';
    } 
}
```  
위의 예시에서 `NameComp`는 `Player`를 이름 기준 오름차순으로 정렬하게 되고, `IdComp`는 `Player`를 id 기준 오름차순으로 정렬하게 된다.   
## TreeSet, TreeMap 등 순서가 유지되는 자료구조
Natural Ordering 으로 정렬기준을 제시하려면:  
- `Comparable`을 따르는 클래스를 타입으로 지정해주면 자동으로 해당 순서에 맞춰 정렬된다.  
  
Special Ordering 으로 정렬기준을 제시하려면:  
- TreeSet, TreeMap을 생성하면서 Comparator를 parameter로 넘겨주면 된다.  
    - 예시) `TreeSet<SomClass> treeSet = new TreeSet<>(new SomeClassComparator);`  