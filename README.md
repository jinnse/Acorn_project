# EC2 - EKS Migration
## 프로젝트 개요
MSA 기반 대학 시스템을 EC2에서 EKS로 마이그레이션하여 비용 최적화와 운영 효율성을 확보한 프로젝트

## 프로젝트 목적
- 서비스 규모 성장에 따른 EC2 운영 한계를 극복하고 Pod 단위 스케일링으로 비용 효율성 확보
- API Gateway 트래픽 전환 방식으로 서비스 중단 없는 무중단 마이그레이션 구현
- Karpenter와 HPA를 통한 자동 스케일링으로 트래픽 변화에 유연하게 대응하는 고가용성 환경 구축
- Terraform을 활용한 IaC 기반 인프라 배포로 반복 가능하고 일관된 환경 구성

## 인프라 구성
> EC2 아키텍처 이미지
https://github.com/jinnse/Acorn_project/issues/1#issue-4020929462
> EKS 아키텍처 이미지
https://github.com/jinnse/Acorn_project/issues/2#issue-4020931718
> 무중단 마이그레이션
https://github.com/jinnse/Acorn_project/issues/3#issue-4020935530
> *위 이미지는 EC2와 EKS 인프라 구성도를 나타냅니다.*

- **주요 컴포넌트**: EKS, Karpenter, HPA, ALB, Ingress, Prometheus, Grafana, Terraform, EC2
- **인프라 흐름 요약**:  
  EC2 환경 구성 → EKS 환경 동시 구성 → API Gateway 트래픽 전환 → EC2 환경 종료

## 디렉토리 구조
```
├── ec2/        # EC2 기반 Terraform 코드
└── eks/        # EKS 기반 Terraform 코드
    ├── modules/
    └── deploy.sh
```

## 마이그레이션 흐름
1. EC2 환경과 EKS 환경을 동시에 구성
2. API Gateway에서 EC2 로드밸런서로 향하던 트래픽을 EKS Ingress LB로 전환
3. 서비스 중단 없이 트래픽을 순차적으로 EKS로 이전
4. EC2 환경 종료

## 비용 비교
| 항목 | EC2 | EKS |
|------|-----|-----|
| 인스턴스 유지 | $476 | $433 |
| 부하시 추가 인스턴스 | $43 | $21 |
| 로드밸런서 기본 | $48.6 | $16.2 |
| 로드밸런서 LCU | $34.56 | $11.52 |
| 클러스터 비용 | - | $72 |
| **총 비용** | **$559.16** | **$553.72** |

> 동일한 총 리소스(12vCPU, 48GB) 기준 비교. 소규모 서비스에서는 절감 효과가 크지 않았으나, 서비스 수와 로드밸런서가 증가할수록 EKS가 유리한 비용 구조임을 확인.

## 기대효과
- **비용 효율성**  
  EC2는 서비스마다 인스턴스와 로드밸런서가 필요한 반면, EKS는 Pod 단위 리소스 공유와 Ingress 통합으로 서비스 규모가 커질수록 비용 절감 효과가 증가.
  EC2는 서비스별 인스턴스가 독립적이라 특정 서비스에 부하가 몰려도 다른 인스턴스 자원을 활용할 수 없어 인스턴스를 추가해야 하는 반면,
  EKS는 노드 전체 자원을 Pod가 공유하여 자원이 남아 있으면 Pod만 추가하면 되므로 추가 비용 없이 대응 가능.
- **고가용성**  
  Karpenter와 HPA를 통한 자동 스케일링으로 트래픽 변화에 유연하게 대응하는 안정적인 운영 환경 구축.
- **운영 효율성**  
  로드밸런서를 3개에서 1개로 통합하고 Terraform IaC로 인프라를 코드로 관리하여 운영 복잡도 감소.
- **모니터링**  
  Prometheus + Grafana 기반 실시간 모니터링으로 인프라 상태 가시화 및 자동 스케일링 동작 검증.

## 기술 스택
1. Kubernetes, EKS
2. Karpenter, HPA
3. Prometheus, Grafana
4. Terraform
5. AWS CodePipeline, CodeBuild, CodeDeploy
6. API Gateway, ALB, Route53
