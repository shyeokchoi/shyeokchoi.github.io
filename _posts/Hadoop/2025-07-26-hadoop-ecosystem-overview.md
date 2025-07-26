---
title:  "Hadoop Ecosystem Overview"

categories:
  - Hadoop
# tags:
#   - [C, csapp]

toc: true
toc_sticky: true
 
date: 2025-07-26
last_modified_at: 2025-07-26
---

![digital_delegation_special_char_err](/assets/images/Hadoop/2025-07-26-hadoop-ecosystem-overview/hadoop_ecosystem.png)  
사진 출처: <https://1004jonghee.tistory.com/m/entry/1004jonghee-%ED%95%98%EB%91%A1%EC%97%90%EC%BD%94%EC%8B%9C%EC%8A%A4%ED%85%9CHadoop-Eco-System-Ver-10?category=419383>

Hadoop Ecosystem에 속하는 기술들의 등장 배경, 풀고자 하는 문제와 특징들을 정리한 포스팅입니다.  
각 기술에 대한 자세한 내용보단, Hadoop Ecosystem을 개괄하는 Overview 형식으로 정리했습니다.

# HDFS

## 목표: 안전한 데이터 스토리지

- 각 파일을 여러 노드에 분산 저장
  - 저장의 단위는 `블록`. 파일을 블록 단위로 쪼개어 저장. 기본 블록 사이즈 128MB
- 같은 블록을 복제해서 여러 노드에 저장하기 때문에 Fault Tolerent

## 구조

- NameNode:
  - 네임스페이스(메타데이터) 관리: 어떤 DataNode가 어떤 블록 가지고 있는지
  - 파일 복제(replication) 제어
- DataNode:
  - 실제 데이터 블록을 저장: NameNode의 요청에 따라 Read/Write에 대응

## 특징

- Throughput over Latency => 배치 처리에 적합
- Write once, Read many. 변경 불가능 => 일관성 문제 해결
- Data source와 가까운 곳에서 computation => Throughput 증가. (네트워크 오버헤드, 데이터 복사 등이 불필요)

# MapReduce

## 목표: 대량 데이터 병렬 처리

각각의 DataNode에서 복사/이동 없이 병렬로 처리해서 마지막에 합치기에 Throughput 증가

## 동작

1. 원본 데이터를`List<(K1, V1)>` 형태로 계산(= **Map**)
2. `K1` 기준으로 셔플/정렬해 `(K1, List<V1>)` 생성
3. 합쳐서(= **Reduce**) `List<(K2, V2)>` 형태로 변환

## 다이어그램

- 맵: 원본 데이터를 중간 키-값 쌍으로 변환
- 셔플 & 정렬: 동일한 키에 대한 모든 값을 수집하고 정렬
- 리듀스: 그룹화된 데이터를 처리하여 최종 결과 생성

<script src="https://unpkg.com/mermaid@8.0.0/dist/mermaid.min.js"></script>

<div class="mermaid">
graph TD
    A{원본 데이터} --> B[맵: 개발 데이터 조각 처리];
    B --> C{중간 키-값 쌍};
    C --> D[셔플 & 정렬: 동일한 키의 값들 모으고 정렬];
    D --> E{그룹화된 중간 키-값 쌍};
    E --> F[리듀스: 집계/요약/변환];
    F --> G{최종 결과 키-값 쌍};
</div>

# HBase

- 분산 DB
- Key-Value 데이터 저장 (NoSQL)
- Columnar Storage

# HIVE

- SQL-like interface 제공하는 Data warehouse (aka HiveQL)

# Impala

- SQL-like interface 제공하는 Data warehouse
- MapReduce 등을 거치지 않고 HDFS에 직접 접근. 자체 쿼리 엔진 MPP(Massive Parallel Processing)
  - => SQL-like 쿼리를 MapReduce로 변환하여 계산하는 HIVE에 비해, 실시간성 강화

# Oozie

- Hadoop 시스템에 대한 workflow 스케줄러 (작업 예약, 순차 실행 보장)

# Sqoop

- RDBMS <-> Hadoop 데이터 대량 전송
