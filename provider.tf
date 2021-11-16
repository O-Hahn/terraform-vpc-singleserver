# Initialize the Terraform Provider to with the necessary config 

variable "ibmcloud_api_key" {}
variable "region" {}

# IBM Cloud Provider for Terraform 
provider "ibm" {
    ibmcloud_api_key   = var.ibmcloud_api_key
    region = var.region
}