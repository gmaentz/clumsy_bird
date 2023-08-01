terraform {
  required_providers {
    tfe = {
      source = "hashicorp/tfe"

      # Latest fixes for tfe_workspace_run
      version = ">= 0.46.0"
    }
  }
}

variable "tfc_org" {
  type = string
}

provider "tfe" {
  organization = var.tfc_org
}

locals {
  workspaces = [
    "clumsy-bird-network",
    "clumsy-bird-compute",
  ]
}

data "tfe_workspace" "ws" {
  for_each = toset(local.workspaces)
  name     = each.key
}

resource "tfe_workspace_run" "network" {
  workspace_id = data.tfe_workspace.ws["clumsy-bird-network"].id

  apply {
    wait_for_run   = true
    manual_confirm = false
  }

  destroy {
    wait_for_run   = true
    manual_confirm = false
  }
}

resource "tfe_workspace_run" "compute" {
  workspace_id = data.tfe_workspace.ws["clumsy-bird-compute"].id

  depends_on = [tfe_workspace_run.network]

  apply {
    wait_for_run   = true
    manual_confirm = false
  }

  destroy {
    wait_for_run   = true
    manual_confirm = false
  }
}

output "clumsy-bird-compute-workspace-name" {
  value = data.tfe_workspace.ws["clumsy-bird-compute"].name
}

output "clumsy-bird-compute-workspace-id" {
  value = data.tfe_workspace.ws["clumsy-bird-compute"].id 
}

output "clumsy-bird-network-workspace-name" {
  value = data.tfe_workspace.ws["clumsy-bird-network"].name
}

output "clumsy-bird-network-workspace-id" {
  value = data.tfe_workspace.ws["clumsy-bird-network"].id 
}