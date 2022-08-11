---
title:  "[C] Command Line Arguments"

categories:
  - C
tags:
  - [C, csapp]

toc: true
toc_sticky: true
 
date: 2022-08-10
last_modified_at: 2022-08-10
---
# Command Line Arguments
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

# getopt()
`getopt()` 함수는 `command line option`을 분석하는 데 도움을 주는 C 라이브러리 함수다.  
```c
int getopt(int argc, char *const argv[], const char *option);
```  
  
`argc`와 `argv`에는 위에서 사용한 값을 그대로 넣어주면 된다.  
`option`에는 옵션을 어떻게 분석할 것인지를 정해줄 수 있다. 만약 옵션이 'a' 또는 'l' 이라면 "al" 이라고 전달하면 된다. 옵션 뒤에 추가적인 인자를 받아오려면 ':'를 넣으면 된다. 예를 들어, 옵션 'a' 뒤에는 인자를 받아들이고 싶다면 "a:l"을 세번째 인자로 전달하면 되는 식이다.  
이 `getopt()` 함수는 더 이상 옵션이 없을 때 `-1`을, 설정되지 않은 옵션이 들어왔을 때는 `?`를, 그 외에는 옵션값 자체를 반환하게 된다.  

`getopt()`는 다음과 같은 변수들과 함께 활용할 수 있다.  
  
```c
extern char *optarg;
extern int opterr;
extern int optind;
extern int optopt;
```  
  
- `optarg`: 해당 옵션 뒤에 오는 `command line argument`를 가리킨다. 예를 들어 `ls -l remind.c`의 예시에서 `getopt(argc, argv, "l:")`을 시행했다면 `optarg`는 "remind.c"라는 문자열을 가리킨다.
- `opterr`: `getopt()`가 에러메시지를 발생시키지 않도록 하려면 `opterr`를 `0`으로 설정해주면 된다.
- `optind`: 다음으로 처리할 `command line argument`의 index 값이다.
- `optopt`: 가장 마지막으로 매칭된 `command line argument`  
  
`getopt()`의 사용 예시는 다음과 같다.  
```c
int main(int argc, char *argv[]) {
    int opt;
    extern char* optarg;

    while ((opt = getopt(argc, argv, "s:E:b:t:")) != -1) {
        switch(opt) {
            case 's':
                //옵션이 's' 일때 할 작업
                //예를 들어서, 's'뒤에 들어온 인자를 integer로 바꿔서 저장하고싶다면,
                int s = atoi(optarg);
                break;
            case 'E':
                //옵션이 'E' 일때 할 작업
                break;
            case 'b':
                //옵션이 'b' 일때 할 작업
                break;
            case 't':
                //옵션이 't' 일때 할 작업
                break;
            default:
                //...
                break;
        }
    }
}
```