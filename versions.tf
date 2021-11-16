
# Terraform biniaries to be used - IBM Cloud provider  

terraform {
    required_providers {
        ibm = {
        source = "IBM-Cloud/ibm"
        version = ">=1.35.0"       
        }
    }
}