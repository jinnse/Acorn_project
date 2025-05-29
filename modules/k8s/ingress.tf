resource "kubernetes_ingress_v1" "univ_ingress_new" {
  provider = kubernetes

  metadata {
    name      = "univ-ingress"
    namespace = "default"
    annotations = {
      # "kubernetes.io/ingress.class"              = "alb"    
      "alb.ingress.kubernetes.io/scheme"         = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"    = "ip"
      "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:ap-northeast-2:886723286293:certificate/f858aced-e1d3-4653-a9c6-3c547f2300bc"
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/center"
          path_type = "Prefix"

          backend {
            service {
              name = "cert-service"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/reg"
          path_type = "Prefix"

          backend {
            service {
              name = "class-service"
              port {
                number = 80
              }
            }
          }
        }

        path {
          path      = "/notice"
          path_type = "Prefix"

          backend {
            service {
              name = "home-service"
              port {
                number = 80
              }
            }
          }
        }
        path {
          path      = "/grafana"
          path_type = "Prefix"

          backend {
            service {
              name = "kube-prometheus-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# variable "services" {
#   default = [
#     { name = "cert",    svc = "cert-service",            path = "/center",  healthz = "/center/healthz" },
#     { name = "class",   svc = "class-service",           path = "/reg",     healthz = "/reg/healthz" },
#     { name = "notice",  svc = "notice-service",          path = "/notice",  healthz = "/notice/healthz" },
#     { name = "grafana", svc = "kube-prometheus-grafana", path = "/grafana", healthz = "/grafana/login" }
#   ]
# }

# resource "kubernetes_ingress_v1" "svc_ingress" {
#   for_each = { for s in var.services : s.name => s }

#   metadata {
#     name      = "${each.key}-ingress"
#     namespace = "default"
#     annotations = {
#       "alb.ingress.kubernetes.io/scheme"                                = "internet-facing"
#       "alb.ingress.kubernetes.io/target-type"                           = "ip"
#       "alb.ingress.kubernetes.io/listen-ports"                          = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
#       "alb.ingress.kubernetes.io/healthcheck-path"                      = each.value.healthz
#       "alb.ingress.kubernetes.io/healthcheck-protocol"                  = "HTTP"
#       "alb.ingress.kubernetes.io/healthcheck-interval-seconds"          = "180"
#       "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"           = "30"
#       "alb.ingress.kubernetes.io/healthcheck-healthy-threshold-count"   = "3"
#       "alb.ingress.kubernetes.io/healthcheck-unhealthy-threshold-count" = "2"
#       "alb.ingress.kubernetes.io/success-codes"                         = "200-299"
#     }
#   }

#   spec {
#     ingress_class_name = "alb"
#     rule {
#       http {
#         path {
#           path      = each.value.path
#           path_type = "Prefix"
#           backend {
#             service {
#               name = each.value.svc
#               port { number = 80 }
#             }
#           }
#         }
#       }
#     }
#   }
# }