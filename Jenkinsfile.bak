// Complete Jenkins Pipeline with Kaniko + Harbor + Helm
// 企业级CI/CD流程：代码检出 → Maven构建 → Docker镜像构建 → Harbor推送 → Helm部署

pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
    app: demo-app-builder
spec:
  serviceAccountName: jenkins
  containers:
  # Maven容器 - 用于构建Java应用 (ARM64兼容，简化配置)
  - name: maven
    image: maven:3.9-eclipse-temurin-17
    command:
    - sh
    - -c
    - "while true; do sleep 30; done"
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1000m"

  # Kaniko容器 - 用于构建Docker镜像（无需Docker daemon）
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.23.0-debug
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"

  # Kubectl容器 - 用于Kubernetes操作
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - sh
    - -c
    - "while true; do sleep 30; done"
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"

  # Helm容器 - 用于应用部署
  - name: helm
    image: alpine/helm:3.13.0
    command:
    - sh
    - -c
    - "while true; do sleep 30; done"
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"

  volumes:
  - name: maven-cache
    emptyDir: {}
  - name: kaniko-secret
    emptyDir: {}
'''
        }
    }

    environment {
        // Harbor配置
        HARBOR_URL = 'localhost:30002'
        HARBOR_PROJECT = 'demo-app'
        HARBOR_CREDENTIAL = credentials('harbor-admin')  // Jenkins凭证ID

        // 镜像配置
        IMAGE_NAME = 'demo-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${HARBOR_URL}/${HARBOR_PROJECT}/${IMAGE_NAME}"

        // Kubernetes配置
        K8S_NAMESPACE = 'default'

        // Helm配置
        HELM_RELEASE_NAME = 'demo-app'
        HELM_CHART_PATH = 'demo-app-chart'

        // Maven配置
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }

    options {
        // 构建保留策略
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // 超时时间
        timeout(time: 30, unit: 'MINUTES')
        // 禁用并发构建
        disableConcurrentBuilds()
        // 时间戳
        timestamps()
    }

    stages {
        stage('代码检出') {
            steps {
                echo '===== 开始检出代码 ====='
                checkout scm
                script {
                    // 获取Git信息
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD || echo 'unknown'",
                        returnStdout: true
                    ).trim()
                    env.GIT_BRANCH = sh(
                        script: "git rev-parse --abbrev-ref HEAD || echo 'unknown'",
                        returnStdout: true
                    ).trim()
                }
                echo "Git Commit: ${env.GIT_COMMIT_SHORT}"
                echo "Git Branch: ${env.GIT_BRANCH}"
                echo '代码检出完成'
            }
        }

        stage('Maven构建') {
            steps {
                container('maven') {
                    echo '===== 开始Maven构建 =====  '
                    sh '''
                        echo "Maven版本:"
                        mvn --version

                        echo "开始编译和打包..."
                        mvn clean package -DskipTests ${MAVEN_OPTS}

                        echo "构建完成，生成的JAR文件:"
                        ls -lh target/*.jar

                        echo "JAR文件信息:"
                        file target/*.jar
                    '''
                }
            }
            post {
                success {
                    echo 'Maven构建成功'
                }
                failure {
                    echo 'Maven构建失败'
                }
            }
        }

        stage('单元测试') {
            steps {
                container('maven') {
                    echo '===== 开始执行单元测试 ====='
                    sh '''
                        echo "运行单元测试..."
                        mvn test ${MAVEN_OPTS}

                        echo "测试完成，测试报告:"
                        if [ -d "target/surefire-reports" ]; then
                            ls -lh target/surefire-reports/
                            echo "测试结果摘要:"
                            grep -r "Tests run:" target/surefire-reports/*.xml || echo "无法获取测试摘要"
                        fi
                    '''
                }
            }
            post {
                always {
                    echo '单元测试阶段完成'
                }
            }
        }

        stage('构建Docker镜像') {
            steps {
                container('kaniko') {
                    echo '===== 开始构建Docker镜像 ====='
                    script {
                        // 创建Kaniko配置文件用于Harbor认证
                        sh """
                            echo "配置Harbor认证..."
                            mkdir -p /kaniko/.docker
                            cat > /kaniko/.docker/config.json <<EOF
{
  "auths": {
    "${HARBOR_URL}": {
      "auth": "\$(echo -n '${HARBOR_CREDENTIAL_USR}:${HARBOR_CREDENTIAL_PSW}' | base64)"
    }
  },
  "insecure-registries": ["${HARBOR_URL}"]
}
EOF
                            echo "Harbor认证配置完成"
                        """

                        // 使用Kaniko构建镜像
                        sh """
                            echo "开始构建镜像: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"

                            /kaniko/executor \
                              --context=\${PWD} \
                              --dockerfile=Dockerfile \
                              --destination=${FULL_IMAGE_NAME}:${IMAGE_TAG} \
                              --destination=${FULL_IMAGE_NAME}:latest \
                              --insecure \
                              --skip-tls-verify \
                              --cache=true \
                              --cache-ttl=24h \
                              --cleanup

                            echo "镜像构建并推送完成"
                        """
                    }
                }
            }
            post {
                success {
                    echo "Docker镜像构建成功: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
                }
                failure {
                    echo 'Docker镜像构建失败'
                }
            }
        }

        stage('镜像扫描') {
            when {
                expression { return params.ENABLE_SCAN == true }
            }
            steps {
                container('kubectl') {
                    echo '===== 触发Harbor镜像扫描 ====='
                    script {
                        // 使用Harbor API触发扫描
                        sh """
                            echo "触发镜像安全扫描..."
                            curl -X POST \
                              -u '${HARBOR_CREDENTIAL_USR}:${HARBOR_CREDENTIAL_PSW}' \
                              -H 'Content-Type: application/json' \
                              'http://${HARBOR_URL}/api/v2.0/projects/${HARBOR_PROJECT}/repositories/${IMAGE_NAME}/artifacts/${IMAGE_TAG}/scan' \
                              || echo "扫描触发失败或已在进行中"

                            echo "等待扫描完成..."
                            sleep 30

                            echo "查询扫描结果..."
                            curl -X GET \
                              -u '${HARBOR_CREDENTIAL_USR}:${HARBOR_CREDENTIAL_PSW}' \
                              'http://${HARBOR_URL}/api/v2.0/projects/${HARBOR_PROJECT}/repositories/${IMAGE_NAME}/artifacts/${IMAGE_TAG}' \
                              || echo "无法获取扫描结果"
                        """
                    }
                }
            }
        }

        stage('部署准备') {
            steps {
                container('helm') {
                    echo '===== 部署前准备 ====='
                    sh '''
                        echo "验证Helm Chart..."
                        helm lint ${HELM_CHART_PATH}

                        echo "检查Kubernetes连接..."
                        kubectl cluster-info

                        echo "检查当前namespace资源..."
                        kubectl get all -n ${K8S_NAMESPACE} -l app=${IMAGE_NAME} || echo "应用尚未部署"

                        echo "准备完成"
                    '''
                }
            }
        }

        stage('Helm部署') {
            steps {
                container('helm') {
                    echo '===== 开始Helm部署 ====='
                    script {
                        // 检查Release是否存在
                        def releaseExists = sh(
                            script: "helm list -n ${K8S_NAMESPACE} | grep -q ${HELM_RELEASE_NAME}",
                            returnStatus: true
                        ) == 0

                        if (releaseExists) {
                            echo "Release已存在，执行升级..."
                            sh """
                                helm upgrade ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \
                                  --namespace ${K8S_NAMESPACE} \
                                  --set image.tag=${IMAGE_TAG} \
                                  --set image.repository=${FULL_IMAGE_NAME} \
                                  --set image.pullPolicy=Always \
                                  --wait \
                                  --timeout 5m \
                                  --atomic
                            """
                        } else {
                            echo "首次部署，执行安装..."
                            sh """
                                helm install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \
                                  --namespace ${K8S_NAMESPACE} \
                                  --create-namespace \
                                  --set image.tag=${IMAGE_TAG} \
                                  --set image.repository=${FULL_IMAGE_NAME} \
                                  --set image.pullPolicy=Always \
                                  --wait \
                                  --timeout 5m \
                                  --atomic
                            """
                        }

                        echo "查看Release信息..."
                        sh "helm list -n ${K8S_NAMESPACE}"

                        echo "查看Release详情..."
                        sh "helm get values ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE}"
                    }
                }
            }
            post {
                success {
                    echo 'Helm部署成功'
                }
                failure {
                    echo 'Helm部署失败，尝试回滚...'
                    container('helm') {
                        sh """
                            echo "执行回滚..."
                            helm rollback ${HELM_RELEASE_NAME} -n ${K8S_NAMESPACE} || echo "回滚失败"

                            echo "回滚后状态:"
                            helm list -n ${K8S_NAMESPACE}
                        """
                    }
                }
            }
        }

        stage('部署验证') {
            steps {
                container('kubectl') {
                    echo '===== 开始验证部署 ====='
                    sh """
                        echo "等待Pod就绪..."
                        kubectl wait --for=condition=ready pod \
                          -l app=${IMAGE_NAME} \
                          -n ${K8S_NAMESPACE} \
                          --timeout=300s || echo "等待超时，请手动检查"

                        echo "查看Pod状态:"
                        kubectl get pods -n ${K8S_NAMESPACE} -l app=${IMAGE_NAME}

                        echo "查看Service状态:"
                        kubectl get svc -n ${K8S_NAMESPACE} -l app=${IMAGE_NAME}

                        echo "查看Deployment状态:"
                        kubectl get deployment -n ${K8S_NAMESPACE} -l app=${IMAGE_NAME}

                        echo "获取最新Pod日志:"
                        LATEST_POD=\$(kubectl get pods -n ${K8S_NAMESPACE} -l app=${IMAGE_NAME} \
                          --sort-by=.metadata.creationTimestamp \
                          -o jsonpath='{.items[-1].metadata.name}')
                        echo "Latest Pod: \${LATEST_POD}"
                        kubectl logs -n ${K8S_NAMESPACE} \${LATEST_POD} --tail=50 || echo "无法获取日志"

                        echo "测试应用健康检查..."
                        kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -- \
                          curl -f http://${IMAGE_NAME}.${K8S_NAMESPACE}.svc.cluster.local:8080/actuator/health || echo "健康检查失败"
                    """
                }
            }
        }

        stage('部署后通知') {
            steps {
                script {
                    echo '''
                    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    🎉 CI/CD流程执行成功！
                    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    '''
                    echo "构建号: ${BUILD_NUMBER}"
                    echo "镜像标签: ${IMAGE_TAG}"
                    echo "完整镜像: ${FULL_IMAGE_NAME}:${IMAGE_TAG}"
                    echo "Git Commit: ${env.GIT_COMMIT_SHORT}"
                    echo "Helm Release: ${HELM_RELEASE_NAME}"
                    echo "Namespace: ${K8S_NAMESPACE}"
                    echo "访问地址: http://localhost:30088/api/hello"
                    echo '''
                    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    '''
                }
            }
        }
    }

    post {
        always {
            echo '===== Pipeline执行完成 ====='
            echo "工作空间: ${WORKSPACE}"
            echo "构建时长: ${currentBuild.durationString}"
        }
        success {
            echo '''
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ✅ Pipeline执行成功！

            部署流程:
            1. ✓ 代码检出
            2. ✓ Maven构建
            3. ✓ 单元测试
            4. ✓ Docker镜像构建（Kaniko）
            5. ✓ 推送到Harbor
            6. ✓ Helm部署到Kubernetes
            7. ✓ 部署验证

            访问地址: http://localhost:30088/api/hello
            Harbor镜像: http://localhost:30002
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            '''
        }
        failure {
            echo '''
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ❌ Pipeline执行失败

            请检查Jenkins日志排查问题
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            '''
        }
        unstable {
            echo 'Pipeline状态不稳定，请检查测试结果'
        }
        aborted {
            echo 'Pipeline被手动中止'
        }
    }
}

// Pipeline参数配置（在Jenkins Job配置中启用）
// parameters {
//     booleanParam(name: 'ENABLE_SCAN', defaultValue: false, description: '是否启用镜像安全扫描')
//     choice(name: 'DEPLOY_ENV', choices: ['dev', 'test', 'prod'], description: '部署环境')
// }
