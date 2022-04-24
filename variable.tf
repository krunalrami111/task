
variable "sns_name" {
        description = "Name of the SNS Topic to be created"
        default = "infosns"
}

variable "account_id" {
        description = "My Accout Number"
        default = "<AWSAccountno>"
}

variable "keyname" {
        description = "name of exeisitng key pair"
        default = "<keypairname>"
}
