podTemplate(label: 'mypod', serviceAccount: 'jenkins', containers: [ 
    containerTemplate(
      name: 'docker', 
      image: 'docker', 
      command: 'cat', 
      resourceRequestCpu: '100m',
      resourceLimitCpu: '300m',
      resourceRequestMemory: '300Mi',
      resourceLimitMemory: '500Mi',
      ttyEnabled: true
    ),
    containerTemplate(
      name: 'kubectl', 
      image: 'amaceog/kubectl',
      resourceRequestCpu: '100m',
      resourceLimitCpu: '300m',
      resourceRequestMemory: '300Mi',
      resourceLimitMemory: '500Mi', 
      ttyEnabled: true, 
      command: 'cat'
    ),
    containerTemplate(
      name: 'helm', 
      image: 'alpine/helm:3.8.0', 
      resourceRequestCpu: '100m',
      resourceLimitCpu: '300m',
      resourceRequestMemory: '300Mi',
      resourceLimitMemory: '500Mi',
      ttyEnabled: true, 
      command: 'cat'
    )
  ],

  volumes: [
    hostPathVolume(mountPath: '/var/run/docker.sock', hostPath: '/var/run/docker.sock'),
    hostPathVolume(mountPath: '/usr/local/bin/helm', hostPath: '/usr/local/bin/helm')
  ]
  ) {
    node('mypod') {
        
        def GIT_URL = "https://github.com/ZhannaGuseva/python.git"
        def REPOSITORY_URI = "zhannaguseva/python"
        def VERSION = "${DEV_YEAR}-${DEV_MONTH}-${BUILD_NUMBER}"
        def HELM_APP_NAME = "python-app"
        def HELM_CHART_DIRECTORY = "/home/jenkins/agent/workspace/test3_helm/helm"
        def HELM_CHART_REPO = "/home/jenkins/agent/workspace/test3_helm"
        def HELM_IMAGE_TAG = "2024-04-16"
        def HELM_REGISTRY = "oci://registry-1.docker.io/zhannaguseva/python-app"
        
        stage('Get latest version of code') {
            script {
                git branch: 'main', credentialsId: 'jenkins', url: "${GIT_URL}"
                sh 'pwd'
            }
        }
        stage('Linting Dockerfile') {
            container('docker') {
                sh 'docker run --rm -i hadolint/hadolint:2.10.0 < Dockerfile | tee -a docker_lint.txt'
            }
        }
        
        stage('Docker Build') {
            container('docker') {
                withCredentials([usernamePassword(credentialsId: 'dockerhubcredentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                sh 'docker login --username="${USERNAME}" --password="${PASSWORD}"'
                sh "docker build -t ${REPOSITORY_URI}:${VERSION} ."
                sh 'docker image ls' 
              } 
            }
        }
        
        stage('Push artefact') {
            container('docker') {
                withCredentials([usernamePassword(credentialsId: 'dockerhubcredentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                sh "docker push ${REPOSITORY_URI}:${VERSION}"
                sh "docker rmi ${REPOSITORY_URI}:${VERSION}"
                }                 
            }
        }
        
        stage('Package Helm Chart') {
            container('helm') {
                withCredentials([usernamePassword(credentialsId: 'dockerhubcredentials', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                sh "sed -i 's;${HELM_IMAGE_TAG};${VERSION};' ${WORKSPACE}/helm/values-dev.yaml"
                sh "cat ${WORKSPACE}/helm/values-dev.yaml"
                
                sh "helm package ${HELM_CHART_DIRECTORY}"
                // Check if the package file exists
                sh "[ -f ${HELM_CHART_REPO}/${HELM_APP_NAME}-0.1.0.tgz ] && echo 'Helm chart package created' || echo 'Failed to create Helm chart package'"
                sh "export HELM_EXPERIMENTAL_OCI=1"
                sh 'helm registry login "registry-1.docker.io" --username="${USERNAME}" --password="${PASSWORD}"'
                sh "helm push ${HELM_CHART_REPO}/${HELM_APP_NAME}-*.tgz oci://registry-1.docker.io/zhannaguseva"
                }                 
            }
        }
        
        stage('Deploy Helm Chart for dev namespace and Check running containers') {
            container('helm') {
                script {
                // Check if the release already exists
                    def existingRelease = sh(returnStdout: true, script: "helm list -q | grep '^${HELM_APP_NAME}'").trim()
                    if (existingRelease.isEmpty()) {
                // If the release doesn't exist, install it
                        sh "helm install ${HELM_APP_NAME} ${HELM_REGISTRY} -n dev -f values-dev.yaml"
                    } else {
                // If the release exists, upgrade it
                        sh "helm upgrade ${HELM_APP_NAME} ${HELM_REGISTRY} -n dev -f values-dev.yaml"
                    }
                }
            }
                
            container('kubectl') { 
                sh 'kubectl get pods -n dev'  
            }
        }
        
        archiveArtifacts 'docker_lint.txt'
    }
}
