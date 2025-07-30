---
title:  "Docker Image Layer와 build 과정에서 캐싱"

categories:
  - Docker
# tags:
#   - []

toc: true
toc_sticky: true
 
date: 2025-07-30
last_modified_at: 2025-07-30
---

# 예시

```docker
FROM node

WORKDIR /app

COPY . /app

RUN npm install

EXPOSE 80

CMD ["node", "server.js"]
```

위와 같은 `Dockerfile` 이 있다고 합니다.
현재 working directory tree는 다음과 같습니다. (Node.js 앱)

```text
.
├── Dockerfile
├── package.json
├── public
│   └── styles.css
└── server.js
```

`docker build .` 로 이미지를 빌드해보면 아래와 같습니다.  

```text
[+] Building 44.2s (9/9) FINISHED                                                                        docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                     0.0s
 => => transferring dockerfile: 128B                                                                                     0.0s
 => [internal] load metadata for docker.io/library/node:latest                                                           3.9s
 => [internal] load .dockerignore                                                                                        0.0s
 => => transferring context: 2B                                                                                          0.0s
 => [1/4] FROM docker.io/library/node:latest@sha256:c7a63f857d6dc9b3780ceb1874544cc22f3e399333c82de2a46de0049e841729    38.0s
 => => resolve docker.io/library/node:latest@sha256:c7a63f857d6dc9b3780ceb1874544cc22f3e399333c82de2a46de0049e841729     0.0s
 => => sha256:0b5fcb2a7960a57222ab8ca1b7cd59178942b0ec186925ea3cfb3296e4707b35 3.32kB / 3.32kB                           0.9s
 => => sha256:53add6cc06fcfc1109933a38ea677237b7d485fb877fbbbad208bf4eed75589c 58.02MB / 58.02MB                        25.8s
 => => sha256:e0a33b6534d538051fd57034bb0d5f5786621531966f1e005eb47fc3f6355079 446B / 446B                               0.4s
 => => sha256:a0f821d04e353b9116ba31fb4eb28aa76e5a13bd674c69fa21c9987eb79575ee 1.25MB / 1.25MB                           0.8s
 => => sha256:2c8f8efa410508ebc8fde38d377ba56a4972adb4f90837aad9c1a60960b0e431 202.82MB / 202.82MB                      35.0s
 => => sha256:1de51daaef2003ecaec3c73f5ef373c01bb10f38b5ec85db7d9077efa7231264 64.36MB / 64.36MB                        27.2s
 => => sha256:e4b341315eac0ea1ad859055038b69990fff352cc7f160586e6a94f1b126675d 23.56MB / 23.56MB                        14.0s
 => => sha256:6fbab1970a5a8545cb921278645cd2e79f4eb23c4bdfb714bef2fdf569acddd0 48.34MB / 48.34MB                         8.9s
 => => extracting sha256:6fbab1970a5a8545cb921278645cd2e79f4eb23c4bdfb714bef2fdf569acddd0                                0.5s
 => => extracting sha256:e4b341315eac0ea1ad859055038b69990fff352cc7f160586e6a94f1b126675d                                0.2s
 => => extracting sha256:1de51daaef2003ecaec3c73f5ef373c01bb10f38b5ec85db7d9077efa7231264                                0.6s
 => => extracting sha256:2c8f8efa410508ebc8fde38d377ba56a4972adb4f90837aad9c1a60960b0e431                                1.9s
 => => extracting sha256:0b5fcb2a7960a57222ab8ca1b7cd59178942b0ec186925ea3cfb3296e4707b35                                0.0s
 => => extracting sha256:53add6cc06fcfc1109933a38ea677237b7d485fb877fbbbad208bf4eed75589c                                0.6s
 => => extracting sha256:a0f821d04e353b9116ba31fb4eb28aa76e5a13bd674c69fa21c9987eb79575ee                                0.0s
 => => extracting sha256:e0a33b6534d538051fd57034bb0d5f5786621531966f1e005eb47fc3f6355079                                0.0s
 => [internal] load build context                                                                                        0.0s
 => => transferring context: 8.25kB                                                                                      0.0s
 => [2/4] WORKDIR /app                                                                                                   0.2s
 => [3/4] COPY . /app                                                                                                    0.0s
 => [4/4] RUN npm install                                                                                                1.8s
 => exporting to image                                                                                                   0.3s
 => => exporting layers                                                                                                  0.2s
 => => exporting manifest sha256:015422697203ea30cb7d5107803908d74b7a2e1e745749ddb5a56cabb3a9b7a0                        0.0s
 => => exporting config sha256:e87a96ba8b6ee6931ef5016b79267973409e10478dd41a28ce6685c6921b36dd                          0.0s
 => => exporting attestation manifest sha256:8ddf4a69db56954d3b01a25f6c66dc7ebbe40bc48c4cd3dbf1523f3897600f41            0.0s
 => => exporting manifest list sha256:a136769db264ea1e5082d2e5960665e5b1182f1505caa5c005b6d660ff8c4351                   0.0s
 => => naming to docker.io/library/original:latest                                                                       0.0s
 => => unpacking to docker.io/library/original:latest                                                                    0.1s

```

이제, `server.js` 를 변경하고 다시 빌드합니다.

```text
[+] Building 6.9s (10/10) FINISHED                                                                       docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                     0.0s
 => => transferring dockerfile: 128B                                                                                     0.0s
 => [internal] load metadata for docker.io/library/node:latest                                                           5.2s
 => [auth] library/node:pull token for registry-1.docker.io                                                              0.0s
 => [internal] load .dockerignore                                                                                        0.0s
 => => transferring context: 2B                                                                                          0.0s
 => [1/4] FROM docker.io/library/node:latest@sha256:c7a63f857d6dc9b3780ceb1874544cc22f3e399333c82de2a46de0049e841729     0.0s
 => => resolve docker.io/library/node:latest@sha256:c7a63f857d6dc9b3780ceb1874544cc22f3e399333c82de2a46de0049e841729     0.0s
 => [internal] load build context                                                                                        0.0s
 => => transferring context: 1.14kB                                                                                      0.0s
 => CACHED [2/4] WORKDIR /app                                                                                            0.0s
 => [3/4] COPY . /app                                                                                                    0.0s
 => [4/4] RUN npm install                                                                                                1.4s
 => exporting to image                                                                                                   0.3s
 => => exporting layers                                                                                                  0.2s
 => => exporting manifest sha256:a98861cbcf348f5c177efca2b4d23a8e6161b610fa5ad6420934733bb3a4102a                        0.0s
 => => exporting config sha256:e747391b63d805a595b64f2260028baaf0105736b0a2b670e7103b44bd5073d6                          0.0s
 => => exporting attestation manifest sha256:1b8efd991df8ef0e73e6d3a6d9b8dfb06ab5f258d0f96b63c868cac6e28b53d2            0.0s
 => => exporting manifest list sha256:2170d486075f102683fd3d526a2ef7465613807a54969b76744f6225e9239339                   0.0s
 => => naming to docker.io/library/changed:latest                                                                        0.0s
 => => unpacking to docker.io/library/changed:latest                                                                     0.1s
```

`WORKDIR /app` 도커 명령어 까지는 캐시된 내용을 사용했지만,  
`COPY . /app` 부터는 캐시를 사용하지 못했습니다.

이는 `server.js` 를 변경했기 때문입니다.  
다만, 문제는 `packages.json` 이 변경되지 않았기에, `RUN npm install` 은 (논리적으로) 캐시를 사용해도 되지만, 빌드 과정에서 캐시가 사용되지 않았다는 것입니다.  

# Image Layer

이는 도커의 명령어가 각각 하나의 이미지 레이어를 이루고,  
뒤쪽에 작성된 명령어가 생성한 레이어가 앞쪽에 작성한 명령어가 생성한 레이어에 의존하기 때문입니다.

즉, `COPY . /app` 에 `RUN npm install` 이 의존하기에,  
`COPY . /app` 이 캐시를 사용하지 못했다면 `RUN npm install` 도 사용하지 못하게 되었습니다.

# 해결

쓸데없는 명령어에 의존하지 않도록 해야합니다.

수정된 `Dockerfile`:

```docker
FROM node

WORKDIR /app

COPY package.json /app

RUN npm install

COPY . /app

EXPOSE 80

CMD ["node", "server.js"]
```

이 경우, 기존의 이미지를 빌드하고, `server.js` 를 수정한 후 다시 빌드 결과는 아래와 같습니다.

```text
[+] Building 2.9s (10/10) FINISHED                                                                       docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                     0.0s
 => => transferring dockerfile: 153B                                                                                     0.0s
 => [internal] load metadata for docker.io/library/node:latest                                                           2.8s
 => [internal] load .dockerignore                                                                                        0.0s
 => => transferring context: 2B                                                                                          0.0s
 => [1/5] FROM docker.io/library/node:latest@sha256:c7a63f857d6dc9b3780ceb1874544cc22f3e399333c82de2a46de0049e841729     0.0s
 => => resolve docker.io/library/node:latest@sha256:c7a63f857d6dc9b3780ceb1874544cc22f3e399333c82de2a46de0049e841729     0.0s
 => [internal] load build context                                                                                        0.0s
 => => transferring context: 1.13kB                                                                                      0.0s
 => CACHED [2/5] WORKDIR /app                                                                                            0.0s
 => CACHED [3/5] COPY package.json /app                                                                                  0.0s
 => CACHED [4/5] RUN npm install                                                                                         0.0s
 => [5/5] COPY . /app                                                                                                    0.0s
 => exporting to image                                                                                                   0.0s
 => => exporting layers                                                                                                  0.0s
 => => exporting manifest sha256:86707424360373234406a89b32f3f2711c6be56b377109165fb5beb2107455c0                        0.0s
 => => exporting config sha256:3c1b721ac3441aa338da54f01ef3944347354757a1bfcf957096e068074850f2                          0.0s
 => => exporting attestation manifest sha256:273fdb1d3756ff74286a5fe51105a715981dab9831071abfe4cc8481dabcb752            0.0s
 => => exporting manifest list sha256:568bf0f8b433222a848a8355b1f98680a00a160f121068cd36f9020dc3cf6125                   0.0s
 => => naming to docker.io/library/new-dockerfile-after-serverjs-update:latest                                           0.0s
 => => unpacking to docker.io/library/new-dockerfile-after-serverjs-update:latest                                        0.0s
```

`COPY . /app` 명령어를 제외하고는 (특히 `RUN npm install`) 모두 캐시가 적용된 것을 볼 수 있습니다.

# 주의

컨테이너 보안에서 이미지를 빌드할때 캐시를 사용하지 말라는 의견도 있습니다.  

빌드 명령어에 `--no-cache` 옵션으로 캐시 사용을 끄면, 다음과 같은 이점이 있습니다.  

- 매번 의존성과 환경 업데이트를 보장: 오래된 패키지 사용하지 않도록
- Reproducible 빌드 확보: 사람마다 캐싱된 내용이 다를 수 있음
- 개발 편의: 캐시로 인한 예기치 못한 버그 방지

그럼에도, 일단 이 예시는 도커 명령어의 각 줄이 바로 이미지 레이어를 형성한다는 개념을 이해하는 의미로 작성해봤습니다.  
