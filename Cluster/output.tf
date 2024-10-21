output "cluster_id" {
  value = aws_eks_cluster.demo_eks_cluster.id
}

output "node_group_id" {
  value = aws_eks_node_group.demo_node_group.id
}

output "vpc_id" {
  value = aws_vpc.demo_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.demo_subnet[*].id
}

