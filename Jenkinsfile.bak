pipeline {
    agent any

    environment {
        // Docker镜像信息
        DOCKER_IMAGE = 'demo-app'
        DOCKER_TAG = '1.0.0'

        // Kubernetes配置
        K8S_NAMESPACE = 'default'
        K8S_DEPLOYMENT = 'demo-app'

        // Maven配置
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }

    tools {
        maven 'Maven-3.9'  // 需要在Jenkins中配置Maven工具
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
                sh '''
                    echo "使用Maven进行编译和打包..."
                    mvn clean package -DskipTests ${MAVEN_OPTS}
                    echo "Maven构建完成"
                '''
            }
        }

        stage('单元测试') {
            steps {
                echo '===== 开始执行单元测试 ====='
                sh '''
                    echo "运行单元测试..."
                    mvn test ${MAVEN_OPTS}
                    echo "单元测试完成"

                    echo "测试报告位置: target/surefire-reports/"
                    if [ -d "target/surefire-reports" ]; then
                        echo "测试文件列表:"
                        ls -lh target/surefire-reports/
                    fi
                '''
            }
        }

        stage('Docker镜像构建') {
            steps {
                echo '===== 开始构建Docker镜像 ====='
                script {
                    sh """
                        echo "构建Docker镜像: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .

                        echo "添加latest标签"
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest

                        echo "查看构建的镜像"
                        docker images | grep ${DOCKER_IMAGE}
                    """
                }
            }
        }

        stage('部署到Kubernetes') {
            steps {
                echo '===== 开始部署到Kubernetes ====='
                script {
                    sh """
                        echo "应用Kubernetes配置文件..."

                        # 应用Deployment
                        kubectl apply -f k8s/deployment.yaml

                        # 应用Service
                        kubectl apply -f k8s/service.yaml

                        echo "等待部署完成..."
                        kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} --timeout=5m

                        echo "查看部署状态"
                        kubectl get pods -n ${K8S_NAMESPACE} -l app=${K8S_DEPLOYMENT}
                        kubectl get svc -n ${K8S_NAMESPACE} ${K8S_DEPLOYMENT}
                    """
                }
            }
        }

        stage('部署验证') {
            steps {
                echo '===== 开始验证部署 ====='
                script {
                    sh """
                        echo "等待服务就绪..."
                        sleep 20

                        echo "获取Service NodePort..."
                        NODE_PORT=\$(kubectl get svc ${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
                        echo "Service暴露端口: \${NODE_PORT}"

                        echo "测试API端点..."
                        curl -f http://localhost:\${NODE_PORT}/api/hello || exit 1

                        echo "部署验证成功！"
                        echo "访问地址: http://localhost:\${NODE_PORT}/api/hello"
                    """
                }
            }
        }
    }

    post {
        success {
            echo '===== Pipeline执行成功！ ====='
            echo """
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            🎉 CI/CD流程执行成功！

            应用已成功部署到Kubernetes集群

            访问地址: http://localhost:30088/api/hello
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            """
        }
        failure {
            echo '===== Pipeline执行失败 ====='
            echo """
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ❌ CI/CD流程执行失败

            请查看Jenkins日志排查问题
            ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            """
        }
        always {
            echo '===== Pipeline执行完成 ====='
            echo "工作空间位置: ${WORKSPACE}"
        }
    }
}
