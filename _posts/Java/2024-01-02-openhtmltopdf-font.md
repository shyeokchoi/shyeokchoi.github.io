---
title: "openhtmltopdf 라이브러리 특수문자가 ###로 표기되는 문제"

categories:
  - Java
tags:
  - [Java, openhtmltopdf]

toc: true
toc_sticky: true

date: 2024-01-02
last_modified_at: 2024-01-02
---

# 문제상황

![digital_delegation_special_char_err](/assets/images/Java/2024-01-02-openhtmltopdf-font/전자위임_pdf_특수문자_오류.png)  
[openhtmltopdf](https://github.com/danfickle/openhtmltopdf) 라이브러리를 사용해 html을 pdf로 변환하는 과정에서, 위 사진과 같이 한자가 ###로 표기되는 문제가 발생했습니다.

# 원인

한자를 표기할 폰트가 없어서 발생하는 문제입니다.  
[공식 위키](https://github.com/danfickle/openhtmltopdf/wiki/Fonts) 를 참조하면,

> If no glyph is found for a character in any of the specified fonts (plus serif) the behavior is as follows. Control character codes will be ignored, whitespace characters will be replaced with the space character and any other character will be replaced with the replacement character (# by default).

이라고 되어있습니다.  
폰트에서 제공하지 않는 제어문자(`널`, `탭`, `줄바꿈`, `이스케이프` 등)은 무시되고, 공백 문자들은 space로 대체되며, 나머지는 # 로 대체된다는 내용입니다.

# 해결

사실 이 글을 쓰게 된 이유인데, 공식문서에는

> Fonts may be added for embedding via CSS @font-face blocks or programatically via the builder.

라고 되어있습니다.  
저 부분을 읽으면 CSS에서 `@font-face` 블럭을 활용해 폰트를 추가해주거나([위키](https://github.com/danfickle/openhtmltopdf/wiki/Fonts#css-font-embedding-example)), 자바 코드에서 추가해주거나([위키](https://github.com/danfickle/openhtmltopdf/wiki/Fonts#programatically-adding-fonts)) 둘 중 하나만 하면 될 것 같은 느낌이 듭니다.  
그래서, 한자 번체자를 지원하는 구글의 `NotoSansKR`폰트를 추가해주고, 해당 ttf를 라이브러리에서 제공하는 `PdfRendererBuilder` 객체의 `useFont()` 함수를 통해 적용해주면 되겠다고 생각했습니다.  
하지만, 아래처럼 코드를 짜도, 해당 문제는 계속 발생합니다.

<script src="https://gist.github.com/shyeokchoi/08bd702c86cc6dae10d6fadad8cc6314.js"></script>

알고보니, 위키에는 방법이 나와있지 않지만, CSS에도 폰트 참조를 적어줘야 합니다.  
이렇게요.

<script src="https://gist.github.com/shyeokchoi/560b2250d971f59f49104ae056c64b8f.js"></script>

이렇게 하면 일단 `나눔명조` 폰트로 문자들을 처리하고, 해당 폰트에서 지원하지 않는 문자면 그 다음 `NotoSansKR` 폰트를 사용하고, 그것도 안 되면 `sans-serif`를 폰트를 사용합니다.  
이때는, `useFont()` 함수를 호출할 때 두 번째 parameter인 `fontFamily`에 argument로 제공한 문자열(여기서는 "NotoSansKR")을 적어줘야 합니다.

혹시나 저처럼 Java 코드만 수정하면 되겠지 생각하고 한참 헤매는 분이 계실까봐 글 적어보았습니다!

# 여담

사실 openhtmltopdf는 관리가 안 되고 있는 라이브러리입니다.  
하지만 html을 pdf로 변환하는 다른 라이브러리인 [itext](https://github.com/itext/itext7)는 상업용으로 사용하려면 비용을 지불하거나 어플리케이션 전체를 오픈소스로 공개해야하기 때문에 배제했습니다.

# 그 외 주의할 점

처음에는 `InputStream`을 사용하지 않고 `File` 객체를 사용했습니다.  
이렇게요.

<script src="https://gist.github.com/shyeokchoi/1e3db0bc711e1742cd1fc958f0f018a0.js"></script>

분명 로컬에선 잘 돌아갔는데, 개발서버에 배포하고 나니 갑자기 `fontFile` 객체를 초기화하며 런타임 에러가 뜨더라구요.  
알고보니 배포할 때 사용될 ttf 파일은 JAR 파일 안에 있고 해당 경로와 파일시스템이 접근하려고 하는 경로가 달라졌기 때문에 ttf 파일을 찾을 수 없어 문제가 생겼던 것입니다.  
위처럼 `InputStream`을 써서 해결했습니다.
