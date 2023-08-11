variable "tfc_org" {
  default = "RPTData"
}

variable "environments" {
  description = "environments to bootstrap"
  type        = set(string)
  default     = ["development"]
}
