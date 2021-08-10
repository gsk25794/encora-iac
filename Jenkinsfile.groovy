pipeline{
    agent any

    tools {
        terraform 'terraform'
    }
    parameters {
        credentials credentialType: 'com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl', defaultValue: 'AwsCredentials', name: 'aws-credentials', required: false
    }

    stages{
        stage('GitHub Repo Checkout'){
            steps{
                git credentialsId: 'github', url: 'https://github.com/gsk25794/encora-iac.git'
            }
        }
        stage('Terraform Initialization'){
            steps{
                sh 'terraform init'
            }
        }
        stage('Terraform Plan'){
            steps{
                sh 'terraform init'
            }
        }
        stage('Terraform Format'){
            steps{
                sh 'terraform fmt'
            }
        }
        stage('Terraform Validate'){
            steps{
                sh 'terraform validate'
            }
        }
        stage('Terraform Plan'){
            steps{
                sh 'terraform plan'
            }
        }
        stage('Terraform Apply'){
            steps{
                sh 'terraform apply --auto-approve'
            }
        }
    }
}
