---
title: "공간 효율적인 완전탐색 - Deutsch-Schorr-Waite 알고리즘"

categories:
  - Algorithms
tags:
  - [Algorithms, DFS]

toc: true
toc_sticky: true
 
date: 2024-06-30
last_modified_at: 2024-06-30
---

# 문제의식
Garbage Collection 등을 위해서 root 노드로부터 완전탐색이 필요합니다.  
이때 적은 공간으로 완전탐색을 하기 위해 고안된 것이 Deutsch-Schorr-Waite 알고리즘 입니다.  

이 알고리즘은 각 노드와 엣지마다 각각 1 bit (노드에는 visited bit, 엣지에는 flipped bit)만 추가해서 완전탐색을 수행합니다.  

따라서, Big-O notation으로 바라본 공간복잡도는 같더라도, 필요한 메모리 공간이 스택이나 큐를 유지하는 일반적인 완전탐색 알고리즘에 비해 적어집니다.  
또, 메모리를 동적으로 할당할 필요가 없습니다.

# 완전탐색을 위해 필요한 정보
BFS든 DFS든, 알고리즘에 사용되는 큐나 스택 자료구조의 역할을 추상화해서 생각해보면,   
"지금 보고있는 노드를 방문한 후에 그 다음 어디로 갈지"를 기록하는 것입니다.      

BFS에서 "다음으로 향할 곳", 즉 "같은 레벨의 다른 노드 혹은 그 아래 레벨의 첫번째 노드"를 저장하는 데 큐를 사용합니다.   
DFS에서 "다음으로 향할 곳", 즉 "아래 레벨의 다른 노드 혹은 다음 분기의 첫번째 노드"를 저장하는 데 스택을 사용합니다.  

Deutsch-Schorr-Waite 알고리즘에서 "다음으로 향할 곳"을 기록하는 자료구조는,  
`직전 노드로 진입하는 엣지를 뒤집어 놓은 것` 입니다.  

즉, 지금 보고 있는 노드에서부터 도달할 수 있는 노드들을 모두 방문한 후에 어디로 가면 될지를, 뒤집어진 엣지라는 형태로 저장합니다.   

# pseudo-code 
<script src="https://gist.github.com/shyeokchoi/6b7a2ee4def6623e9ced4490f5d35118.js"></script>
재귀적인 호출로 인한 스택 메모리 사용도 고려해야 하는 것 아니냐고 하실 수 있지만,  
`Tail-Recursive Function` 이므로 컴파일러가 최적화해준다면 loop와 같습니다.  

# 그림으로
먼저, 아래 사진은 그림에서 사용할 notation 들입니다.  
<img src="/assets/images/Algorithms/2024-06-30-deutsch-schorr-waite/def.png" width="600px" title="def"/>   
아래 그림들에서, 각 그림이 나타내는 시점은 `mark(c, p)` 가 호출된 직후입니다.   

![12](/assets/images/Algorithms/2024-06-30-deutsch-schorr-waite/12.png)  
![34](/assets/images/Algorithms/2024-06-30-deutsch-schorr-waite/34.png)  
![56](/assets/images/Algorithms/2024-06-30-deutsch-schorr-waite/56.png)  

# 단점
- 백트래킹 식으로 경로를 복원해줘야 함
- 포인터 연산으로 인해서 복잡도가 높고 디버깅이 어려움

등의 이유로 실제로 Garbage Collector 들에서 잘 쓰이진 않는 것으로 알고 있습니다.    

다만, 재귀적인 구조로 알고리즘을 구현하는 방법이나 BFS, DFS 에서 자료구조의 역할에 대한 통찰을 제공해줄 수 있을 것 같아 기록을 해보았습니다.
