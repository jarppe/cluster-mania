# Cluster mania

Creating IoC setup for Kubernetes cluster in GCP using Terraform.

Useful resources:

* [Using GKE with Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform)

## Usage

Note that this is not general purpose setup, this still has couple of places with hard-coded values that you probably find confusing, weird, or wrong. Often all three. 

1. Put some magic values to `.env` file
1. Ensure that you have working `gcloud` setup.
1. Run `./init.sh`
1. Run `terraform apply`
1. Run `gcloud container clusters get-credentials $(terraform output cluster-name) --region=$TF_VAR_REGION`
1. Add HTTP load balancer `gcloud container clusters update $(terraform output cluster-name) --region=$TF_VAR_REGION --update-addons=HttpLoadBalancing=ENABLED`
1. Test with `kubectl get svc`
1. Profit

The `init.sh` creates a folder for the project, the project, service-account, bucket for terraform state, and applies some roles for the SA.

The terraform will then create a VPC, subnet, bastion host, static IP for bastion, cluster and node pool.

To destroy the whole setup:

1. Run `terraform destroy`
1. Run `./destroy.sh`
