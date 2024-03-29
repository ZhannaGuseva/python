pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                metadata:
                    labels:
                        app: my-python-app
                spec:
                    containers:
                    - name: docker
                      image: docker:19.03.12
                      command:
                      - cat
                      tty: true
        '''
        }
    }

    options {
        buildDiscarder logRotator(artifactNumToKeepStr: '25', numToKeepStr: '25')
        skipDefaultCheckout()
    }

    parameters {
        string name: 'REVISION',
            defaultValue: '${DEV_BRANCH}',
            description: 'git revision to build',
            trim: true
    }

    environment {
        GIT_URL = 'https://github.com/ZhannaGuseva/python.git'
        REPOSITORY_NAME = "${GIT_URL.split('/')[1] - '.git'}"
        VERSION = "${DEV_YEAR}-${DEV_MONTH}-${BUILD_NUMBER}"
        DOCKERHUB_CREDENTIALS= credentials('dockerhubcredentials')
    }

    stages {
        stage('Source Code Checkout') {
            steps {
                script {
                    git branch: REVISION, credentialsId: 'jenkins', url: GIT_URL
                }
            }
        }
		
		stage('Linting Dockerfile') {
            steps {
                container('docker') {
                  sh 'docker run --rm -i hadolint/hadolint:2.10.0 < Dockerfile | tee -a docker_lint.txt'
                }
            }
        }
		
			
        stage('Docker Build') {
            steps {
                container('docker') {
                    sh """
                        docker build -t zhannaguseva/\${REPOSITORY_NAME}-python-docker-build:\${VERSION} .
                    """
                }
            }
        }
		
		stage('Push artefact') {
            steps {
                container('docker') {
                    sh """
			echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                        docker push zhannaguseva/\${REPOSITORY_NAME}-python-docker-build:\${VERSION}
                    """
                }
            }
        }
    }	
    
	post {
        failure {
            script {
                echo 'Pipeline FAILED '
            }
        }
        success {
            script {
                echo 'Pipeline execution was Successful'
            }
        }
        always {
            archiveArtifacts 'docker_lint.txt'
        }
    }
}
