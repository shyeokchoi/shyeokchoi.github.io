---
title: "[Spring] HttpServletResponse의 버퍼 flush로 인한 HTTP 상태 코드 오류"

categories:
  - Spring
tags:
  - [Java, Spring]

toc: true
toc_sticky: true

date: 2024-01-15
last_modified_at: 2024-01-15
---

# 문제상황

백오피스 어드민 클라이언트의 요청에 따라 csv를 응답으로 제공하기 위해 아래와 같은 코드를 짰습니다.

<script src="https://gist.github.com/shyeokchoi/5d3feb4081b25014c3335319ae3a4466.js"></script>

여기서, `NotFoundException`은 `RuntimeException`을 상속한 custom exception으로, 아래와 같이 `@ExceptionHandler`를 설정해줘서 `NotFoundException`이 발생하면 Http status code를 404로 반환하도록 설정해두었습니다.

<script src="https://gist.github.com/shyeokchoi/646145be011d935fd7d9c7b3d0de962f.js"></script>

그런데, 테스트코드를 작성하다 보니 이상하게 자꾸 `post`에 연결된 `poll`이 없어도, 즉 `NotFoundException`이 발생하는 경우에도 Http status code가 200으로 내려오는 것이었습니다.  
더 이상한건 응답에 "not found"라고 적혀있었다는 점.. 그러니까 `@ExceptionHandler` 어노테이션은 잘 작동했다는 점이었습니다.

# 원인

`csvWriter.writeNext()` 내부에서 `HttpServletResponse` 객체인 `response`의 `OutputStream`에 계속 `write()` 하는 것이 문제였습니다.  
그러다 보면 `OutputStream` 내부의 버퍼가 차게 되고, 클라이언트로 해당 바이트들이 전송됩니다.  
이 경우 한 번 Http status가 200으로 설정되어 전송되었기 때문에, 중간에 예외가 발생해도 status code는 변경되지 않았던 것입니다.

# 해결

임시 `OutputStream`을 도입해서 해결했습니다.

<script src="https://gist.github.com/shyeokchoi/2e071e36665717f4f547d49847228025.js"></script>

이렇게 하면 `csvWriter`는 일단 `tempStream`에 csv로 반환하고자 하는 byte array를 적게 됩니다.  
이후, `tempStream`에 쌓여 있던 데이터를 `response.getOutputStream().write()` 함수를 통해 클라이언트에 전달합니다.  
그러면 모든 작업이 끝나고 `response.getOutputStream().write()` 함수가 호출되기 전에 예외가 발생하면 의도했던대로 Http status code가 `@ExceptionHandler`에 의해 설정됩니다.
