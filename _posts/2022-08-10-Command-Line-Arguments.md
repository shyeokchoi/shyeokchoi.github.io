---
title:  "[C] Command Line Arguments"

categories:
  - C
tags:
  - [C, csapp]

#toc: true
#toc_sticky: true
 
date: 2022-08-10
last_modified_at: 2022-08-10
---

터미널에서 프로그램을 실행하면서 사용자로부터 정보를 받아와야 할 때가 있다.   
`UNIX`의 `ls` 명령어의 경우, `ls`만 입력하면 현재 경로에 있는 파일들의 이름을 보여준다.   
반면 `ls -1`으로 입력하면 파일들의 자세한 정보(크기, 소유자, 최종 수정시간 등)들을 출력한다.  
`ls -1 remind.c`를 입력하면 `remind.c`라는 이름을 가진 파일의 자세한 정보를 출력한다.  
  
이렇게 프로그램 실행과 함께 주어지는 정보를 `command line information`이라고 한다.  
주어진 `command line arguments` (C standard에선 program parameters)에 접근하기 위해서는 `main()`함수에 두 개의 인자를 추가해야한다.  
필수적인건 아니지만, 관습적으로 `argc`와 `argv`를 사용한다.    
```c
int main(int argc, char *argv[]) {
    ...
}
```  
이런 식이다.  
  
`argc`(argument count)는 `command line arguemnts`의 수(프로그램 자체의 이름을 포함해서)이다.   
`argv`(argument vector)는 문자열 형태로 저장된 `command line arguments`를 가리키는 포인터의 배열이다.   
`argv[argc]`에는 항상 `null pointer`가 저장되어 있다.   
즉, `ls -1 remind.c`를 터미널에서 시행했다면, `argc`는 `3`이고, `argv`는 다음과 같은 구조가 된다.   
![image](https://user-images.githubusercontent.com/106307725/183884522-d2c2786e-539c-4506-a1b6-2cebacdc2b83.png)  
즉, `command line arguments`를 순차적으로 출력하는 코드는 다음과 같다.  
```c
int i;
for (i = 1; i<argc; i++) {
    printf("%s\n", argv[i]);
}
```
또는 이렇게도 할 수 있다.  
```c
char **p;
for (p = &argv[1]; *p != NULL; p++) {
    printf(%s\n", *p);
}
```  
