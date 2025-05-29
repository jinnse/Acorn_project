# resource "kubernetes_manifest" "karpenter_provisioner" {
#   manifest = {
#     apiVersion = "karpenter.sh/v1alpha5"
#     kind       = "Provisioner"
#     metadata = {
#       name = "default"
#     }
#     spec = {
#       requirements = [
#         {
#           key      = "node.kubernetes.io/instance-type"
#           operator = "In"
#           values   = ["t3a.2xlarge"]
#         },
#         {
#           key      = "kubernetes.io/arch"
#           operator = "In"
#           values   = ["amd64"]
#         }
#       ]
#       provider = {
#         instanceProfile = aws_iam_instance_profile.karpenter_node.name
#         subnetSelector = {
#           "kubernetes.io/cluster/${var.cluster_name}" = "owned"
#         }
#         securityGroupSelector = {
#           "aws:eks:cluster-name" = var.cluster_name
#         }
#       }
#       ttlSecondsAfterEmpty = 30
#     }
#   }

#   depends_on = [
#     helm_release.karpenter
#   ]

#   lifecycle {
#     ignore_changes = [
#       manifest["spec"]
#     ]
#   }
# }