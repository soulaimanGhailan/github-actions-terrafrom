
variable "ecr_repository_name" {
    default = "my-app-repo"
}

variable "ecs_cluster_name" {
    default = "my-app-cluster"

}

variable "ecs_task_family" {
    default = "my-app-task-family"

}

variable "ecs_service_name" {
    default = "my-app-service"
}

# variable "subnet_ids" {
#       type = list(string)
# }

variable region {}
# variable access_key {}
# variable secret_key {}
# test
