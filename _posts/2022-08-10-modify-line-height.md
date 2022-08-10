---
title:  "[Github Pages] minimal-mistakes 줄간격(행간) 조절"

categories:
  - Github Pages
tags:
  - [blog, minimal mistakes, Github Pages]

#toc: true
#toc_sticky: true
 
date: 2022-08-10
last_modified_at: 2022-08-10
---
minimal mistakes 테마로 만든 블로그의 줄간격(행간)을 조절하는 방법입니다.  
`/_sass/minimal-mistakes/_base.scss` 파일에 들어가줍니다.  
![화면 캡처 2022-08-10 221132](https://user-images.githubusercontent.com/106307725/183910269-fca18fd9-d85b-46c6-83c2-06f6210a4f03.png)  
사진에 보이는 `body`의 `line-height`를 조절해주면 됩니다.  
저는 1.8로 설정하고, 혹시나 원래대로 돌리고 싶어질까봐 default 값을 따로 주석으로 저장해두었습니다.  