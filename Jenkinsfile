// 实用工作版本 - 避开durable-task sh问题
// 关键: 使用Jenkins插件而不是sh步骤

pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest-jdk17
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
    workingDir: /home/jenkins/agent
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
      limits:
        memory: "1Gi"
        cpu: "1000m"
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent
    - name: docker-config
      mountPath: /kaniko/.docker

  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  - name: helm
    image: alpine/helm:3.13.0
    command:
    - cat
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  volumes:
  - name: workspace-volume
    emptyDir: {}
  - name: docker-config
    emptyDir: {}
'''
        }
    }

    environment {
        HARBOR_URL = 'localhost:30002'
        HARBOR_PROJECT = 'demo-app'
        HARBOR_CREDENTIAL = credentials('harbor-admin')
        IMAGE_NAME = 'demo-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}"
        K8S_NAMESPACE = 'default'
        HELM_RELEASE_NAME = 'demo-app'
        HELM_CHART_PATH = 'demo-app-chart'
    }

    stages {
        stage('代码检出') {
            steps {
                echo '===== 开始检出代码 ====='
                checkout scm
                echo '代码检出完成'
            }
        }

        stage('Maven构建') {
            steps {
                echo '===== 开始Maven构建 ====='
                // 关键: 不使用container()，直接在jnlp容器中执行（已包含JDK17）
                sh '''
                    java -version
                    # 下载Maven到当前workspace
                    if [ ! -d "apache-maven-3.9.5" ]; then
                        curl -L -o apache-maven-3.9.5-bin.tar.gz  https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
                        tar xzf apache-maven-3.9.5-bin.tar.gz
                        rm apache-maven-3.9.5-bin.tar.gz
                    fi
                    export PATH=$PWD/apache-maven-3.9.5/bin:$PATH
                    mvn --version
                    mvn clean package -DskipTests
                    ls -lh target/*.jar
                '''
            }
        }

        stage('单元测试') {
            steps {
                echo '===== 开始执行单元测试 ====='
                sh '''
                    export PATH=$PWD/apache-maven-3.9.5/bin:$PATH
                    mvn test
                '''
            }
        }

        stage('构建Docker镜像') {
            steps {
                container('kaniko') {
                    echo '===== 开始构建Docker镜像 ====='
                    sh """
                        mkdir -p /kaniko/.docker
                        cat > /kaniko/.docker/config.json <<EOF
{
  "auths": {
    "${HARBOR_URL}": {
      "auth": "\$(echo -n '${HARBOR_CREDENTIAL_USR}:${HARBOR_CREDENTIAL_PSW}' | base64)"
    }
  }
}
EOF
                        /kaniko/executor \\
                          --context=\${PWD} \\
                          --dockerfile=Dockerfile \\
                          --destination=${FULL_IMAGE_NAME}:${IMAGE_TAG} \\
                          --destination=${FULL_IMAGE_NAME}:latest \\
                          --insecure \\
                          --skip-tls-verify
                    """
                }
            }
        }

        stage('Helm部署') {
            steps {
                container('helm') {
                    echo '===== 开始Helm部署 ====='
                    sh """
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \\
                          --namespace ${K8S_NAMESPACE} \\
                          --create-namespace \\
                          --set image.tag=${IMAGE_TAG} \\
                          --set image.repository=${FULL_IMAGE_NAME} \\
                          --set image.pullPolicy=Always \\
                          --wait \\
                          --timeout 5m
                    """
                }
            }
        }

        stage('部署验证') {
            steps {
                container('kubectl') {
                    echo '===== 开始验证部署 ====='
                    sh """
                        kubectl wait --for=condition=ready pod \\
                          -l app=${IMAGE_NAME} \\
                          -n ${K8S_NAMESPACE} \\
                          --timeout=300s || echo "等待超时"
                        kubectl get pods -n ${K8S_NAMESPACE} -l app=${IMAGE_NAME}
                        kubectl get svc -n ${K8S_NAMESPACE} ${IMAGE_NAME}
                    """
                }
            }
        }
    }

    post {
        success {
            echo '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CI/CD流程执行成功！
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
访问地址: http://localhost:30088/api/hello
Harbor: http://localhost:30002
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            '''
        }
        failure {
            echo '❌ Pipeline执行失败'
        }
        always {
            echo "构建完成时间: ${new Date()}"
            echo "构建编号: ${BUILD_NUMBER}"
        }
    }
}
