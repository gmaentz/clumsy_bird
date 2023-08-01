variable "tfc_org" {
  type        = string
  description = "TFC Organization to pull remote state from"
}

variable "upstream_workspaces" {
  type    = set(string)
  default = []
}

variable "prefix" {
  type        = string
  description = "(Required) This prefix will be included in the name of most resources."
}

variable "project" {
  type        = string
  description = "(Required) Application project name."
}

variable "owner" {
  type        = string
  description = "(Optional) Project Owner. Defaults to Terraform"
  default     = "Terraform"
}

variable "environment" {
  type        = string
  description = "Application environment for deployment."
}

variable "region" {
  type        = string
  description = "(Optional) The region where the resources are created. Defaults to us-east-1."
  default     = "us-east-1"
}