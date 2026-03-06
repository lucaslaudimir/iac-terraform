output "service_name" {
  description = "Service Name"
  value       = var.service_name
}

output "enable_db_connection" {
  description = "Aurora DB Connection enabled"
  value       = var.enable_aurora_db_connection
}

output "ecs_service_id" {
  description = "ID do serviço ECS"
  value       = aws_ecs_service.service.id
}

output "task_definition_arn" {
  description = "ARN da Task Definition criada"
  value       = aws_ecs_task_definition.task.arn
}
