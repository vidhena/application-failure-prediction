pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t failure-prediction-app:v1 ./application
                '''
            }
        }

        stage('Load Image into Kubernetes') {
            steps {
                sh '''
                docker save failure-prediction-app:v1 -o failure-prediction-app.tar
                sudo k3s ctr images import failure-prediction-app.tar
                '''
            }
        }

        stage('Deploy Kubernetes') {
            steps {
                sh '''
                sudo k3s kubectl apply -f kubernetes/deployment.yml
                sudo k3s kubectl apply -f kubernetes/service.yml
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                sudo k3s kubectl get pods
                sudo k3s kubectl get service
                '''
            }
        }
    }
}