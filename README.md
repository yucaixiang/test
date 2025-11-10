# 完整CI/CD流程实战指南

## 项目概述

本项目展示了从代码到部署的完整CI/CD流程，使用Jenkins自动化构建、测试和部署Spring Boot应用到Kubernetes集群。

### 技术栈

- **应用框架**: Spring Boot 3.2.0 (Java 17)
- **构建工具**: Maven 3.9
- **容器化**: Docker
- **编排平台**: Kubernetes (Docker Desktop)
- **CI/CD工具**: Jenkins 2.x
- **版本控制**: Git

---

## 目录结构

```
demo-app/
├── src/
│   ├── main/
│   │   ├── java/com/example/demo/
│   │   │   ├── DemoApplication.java           # Spring Boot主类
│   │   │   └── controller/
│   │   │       └── HelloController.java       # REST API控制器
│   │   └── resources/
│   │       └── application.properties         # 应用配置
│   └── test/java/com/example/demo/
│       └── DemoApplicationTests.java          # 单元测试
├── k8s/
│   ├── deployment.yaml                        # Kubernetes部署配置
│   └── service.yaml                           # Kubernetes服务配置
├── Dockerfile                                 # Docker镜像构建文件
├── Jenkinsfile                                # Jenkins Pipeline定义
├── pom.xml                                    # Maven项目配置
└── .gitignore                                 # Git忽略文件
```

---

## API端点说明

### 1. 健康检查
```bash
GET /api/hello

响应示例:
{
  "status": "success",
  "message": "Hello from Demo App!",
  "timestamp": "2025-11-10 10:30:00",
  "version": "1.0.0",
  "environment": "Kubernetes"
}
```

### 2. 个性化问候
```bash
GET /api/greet?name=张三

响应示例:
{
  "status": "success",
  "message": "Hello, 张三!",
  "timestamp": "2025-11-10 10:30:00"
}
```

### 3. 系统信息
```bash
GET /api/info

响应示例:
{
  "application": "demo-app",
  "version": "1.0.0",
  "java_version": "17.0.x",
  "os": "Linux",
  "timestamp": "2025-11-10 10:30:00",
  "pod_name": "demo-app-7d8f9b5c6d-abc12",
  "namespace": "default"
}
```

### 4. Spring Boot Actuator健康检查
```bash
GET /actuator/health
GET /actuator/health/liveness
GET /actuator/health/readiness
GET /actuator/info
```

---

## 本地开发与测试

### 前置条件

- JDK 17或更高版本
- Maven 3.9或更高版本
- Docker Desktop (已安装并运行)

### 步骤1: 编译和运行

```bash
# 进入项目目录
cd /Users/bjsttlp324/Desktop/learn/software/CICD/demo-app

# Maven编译打包
mvn clean package

# 运行应用
java -jar target/demo-app.jar

# 或使用Maven插件运行
mvn spring-boot:run
```

### 步骤2: 测试API

```bash
# 测试健康检查
curl http://localhost:8080/api/hello

# 测试个性化问候
curl http://localhost:8080/api/greet?name=测试用户

# 测试系统信息
curl http://localhost:8080/api/info

# 测试Actuator健康检查
curl http://localhost:8080/actuator/health
```

### 步骤3: 运行单元测试

```bash
# 执行所有测试
mvn test

# 查看测试报告
open target/surefire-reports/index.html
```

---

## Docker本地测试

### 构建Docker镜像

```bash
# 构建镜像
docker build -t demo-app:1.0.0 .

# 查看镜像
docker images | grep demo-app
```

### 运行Docker容器

```bash
# 运行容器
docker run -d -p 8080:8080 --name demo-app demo-app:1.0.0

# 查看容器日志
docker logs -f demo-app

# 测试API
curl http://localhost:8080/api/hello

# 停止容器
docker stop demo-app

# 删除容器
docker rm demo-app
```

---

## Jenkins配置步骤

### 步骤1: 访问Jenkins

```bash
# Jenkins访问地址
http://localhost:30080

# 登录凭证
用户名: admin
密码: Admin@Jenkins2024
```

### 步骤2: 安装必要插件

进入 **Manage Jenkins** → **Manage Plugins** → **Available**，安装以下插件：

1. **Git Plugin** - Git代码管理
2. **Docker Plugin** - Docker集成
3. **Kubernetes CLI Plugin** - Kubernetes命令行工具
4. **Pipeline** - Pipeline支持
5. **Maven Integration** - Maven集成

### 步骤3: 配置Maven工具

1. 进入 **Manage Jenkins** → **Global Tool Configuration**
2. 找到 **Maven** 部分，点击 **Add Maven**
3. 配置如下:
   - Name: `Maven-3.9`
   - Install automatically: 勾选
   - Version: 选择 `3.9.x`
4. 点击 **Save**

### 步骤4: 配置Kubernetes凭证

由于Jenkins运行在Kubernetes集群内，它会自动使用ServiceAccount访问Kubernetes API，通常不需要额外配置。

如果需要手动配置:

1. 进入 **Manage Jenkins** → **Manage Credentials**
2. 点击 **global** → **Add Credentials**
3. Kind: 选择 **Secret file**
4. File: 上传 `~/.kube/config`
5. ID: `kubeconfig`
6. 点击 **Create**

### 步骤5: 创建Pipeline任务

1. 点击 **New Item**
2. 输入任务名称: `demo-app-pipeline`
3. 选择 **Pipeline**，点击 **OK**
4. 在 **Pipeline** 部分:
   - Definition: 选择 **Pipeline script from SCM**
   - SCM: 选择 **Git**
   - Repository URL: `/Users/bjsttlp324/Desktop/learn/software/CICD/demo-app`

     注意: 如果使用本地路径，需要配置为 `file:///Users/bjsttlp324/Desktop/learn/software/CICD/demo-app`

     **推荐做法**: 将代码推送到GitHub/GitLab，然后使用远程仓库URL

   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
5. 点击 **Save**

---

## 使用GitHub进行完整CI/CD (推荐)

### 步骤1: 创建GitHub仓库

```bash
# 在GitHub上创建新仓库: demo-app

# 添加远程仓库
cd /Users/bjsttlp324/Desktop/learn/software/CICD/demo-app
git remote add origin https://github.com/你的用户名/demo-app.git

# 推送代码
git branch -M main
git push -u origin main
```

### 步骤2: 在Jenkins中配置GitHub仓库

1. 编辑Pipeline任务
2. Repository URL: 输入你的GitHub仓库地址
3. 如果是私有仓库，需要添加GitHub凭证:
   - Credentials → Add → Username with password
   - Username: GitHub用户名
   - Password: GitHub Personal Access Token

### 步骤3: 配置Webhook (可选 - 自动触发构建)

1. 在GitHub仓库中: Settings → Webhooks → Add webhook
2. Payload URL: `http://你的Jenkins地址:30080/github-webhook/`
3. Content type: `application/json`
4. 触发事件: 选择 `Just the push event`
5. 在Jenkins任务配置中勾选: **GitHub hook trigger for GITScm polling**

---

## 执行CI/CD流程

### 方式1: 手动触发

1. 进入Jenkins任务页面
2. 点击 **Build Now**
3. 查看 **Build History** 中的构建进度
4. 点击构建号 → **Console Output** 查看详细日志

### 方式2: Git推送触发 (需配置Webhook)

```bash
# 修改代码后提交
git add .
git commit -m "Update feature"
git push origin main

# Jenkins会自动触发构建
```

---

## Pipeline流程说明

Jenkins Pipeline包含以下6个阶段:

### 1. 代码检出 (Checkout)
- 从Git仓库拉取最新代码
- 验证代码完整性

### 2. Maven构建 (Build)
- 使用 `mvn clean package` 编译代码
- 生成JAR文件到 `target/` 目录
- 缓存Maven依赖以加快后续构建

### 3. 单元测试 (Test)
- 执行 `mvn test` 运行所有单元测试
- 生成测试报告
- 如果测试失败，Pipeline会中断

### 4. Docker镜像构建 (Docker Build)
- 基于Dockerfile构建Docker镜像
- 标记为 `demo-app:1.0.0` 和 `demo-app:latest`
- 镜像使用多阶段构建优化体积

### 5. 部署到Kubernetes (Deploy)
- 应用Deployment和Service配置
- 使用 `kubectl apply` 部署到集群
- 等待Deployment rollout完成
- 验证Pod状态

### 6. 部署验证 (Verify)
- 等待Service就绪
- 调用 `/api/hello` 端点验证部署成功
- 输出访问地址

---

## 验证部署

### 查看Kubernetes资源

```bash
# 查看Pod
kubectl get pods -l app=demo-app

# 查看Service
kubectl get svc demo-app

# 查看Deployment
kubectl get deployment demo-app

# 查看Pod详细信息
kubectl describe pod -l app=demo-app

# 查看Pod日志
kubectl logs -l app=demo-app -f
```

### 访问应用

```bash
# 获取NodePort
kubectl get svc demo-app -o jsonpath='{.spec.ports[0].nodePort}'

# 访问API (默认端口: 30088)
curl http://localhost:30088/api/hello
curl http://localhost:30088/api/greet?name=Jenkins
curl http://localhost:30088/api/info

# 使用浏览器访问
open http://localhost:30088/api/hello
```

### 查看应用日志

```bash
# 实时查看日志
kubectl logs -l app=demo-app -f

# 查看最近100行日志
kubectl logs -l app=demo-app --tail=100

# 查看特定Pod日志
kubectl logs demo-app-xxxxxxxxxx-xxxxx
```

---

## 滚动更新与回滚

### 更新应用版本

```bash
# 1. 修改代码后重新构建镜像
docker build -t demo-app:1.0.1 .

# 2. 更新Deployment镜像
kubectl set image deployment/demo-app demo-app=demo-app:1.0.1

# 3. 查看更新状态
kubectl rollout status deployment/demo-app

# 4. 查看更新历史
kubectl rollout history deployment/demo-app
```

### 回滚到上一版本

```bash
# 回滚到上一个版本
kubectl rollout undo deployment/demo-app

# 回滚到指定版本
kubectl rollout undo deployment/demo-app --to-revision=2

# 查看回滚状态
kubectl rollout status deployment/demo-app
```

---

## 扩缩容

### 手动扩缩容

```bash
# 扩容到5个副本
kubectl scale deployment demo-app --replicas=5

# 查看扩容状态
kubectl get pods -l app=demo-app -w

# 缩容到2个副本
kubectl scale deployment demo-app --replicas=2
```

### 自动扩缩容 (HPA)

```bash
# 创建HPA (基于CPU使用率)
kubectl autoscale deployment demo-app --cpu-percent=50 --min=2 --max=10

# 查看HPA状态
kubectl get hpa

# 删除HPA
kubectl delete hpa demo-app
```

---

## 监控与观测

### Prometheus监控

```bash
# 访问Prometheus
open http://localhost:30090

# 常用查询 (在Prometheus UI中执行)
# 查询应用CPU使用率
rate(process_cpu_seconds_total{job="demo-app"}[5m])

# 查询应用内存使用
process_resident_memory_bytes{job="demo-app"}

# 查询HTTP请求数
rate(http_server_requests_total{job="demo-app"}[5m])
```

### Grafana仪表板

```bash
# 访问Grafana
open http://localhost:30030

# 登录凭证
用户名: admin
密码: Admin@Grafana2024

# 导入常用Dashboard
# Dashboard ID: 4701 (JVM Dashboard)
# Dashboard ID: 10280 (Spring Boot Dashboard)
```

### 查看应用指标

```bash
# 访问Actuator Metrics
curl http://localhost:30088/actuator/metrics

# 查看特定指标
curl http://localhost:30088/actuator/metrics/jvm.memory.used
curl http://localhost:30088/actuator/metrics/http.server.requests
```

---

## 故障排查

### Jenkins Pipeline失败

**问题1: Maven构建失败**
```bash
# 查看Jenkins Console Output
# 常见原因:
# - 网络问题导致依赖下载失败
# - JDK版本不匹配
# - 代码编译错误

# 解决方法:
# 1. 在Jenkins中配置Maven镜像 (阿里云镜像)
# 2. 检查JDK版本是否为17
# 3. 修复代码编译错误
```

**问题2: Docker镜像构建失败**
```bash
# 检查Docker是否运行
docker ps

# 检查磁盘空间
df -h

# 清理未使用的镜像
docker system prune -a
```

**问题3: Kubernetes部署失败**
```bash
# 查看Pod事件
kubectl describe pod -l app=demo-app

# 查看Pod日志
kubectl logs -l app=demo-app

# 常见错误:
# - ImagePullBackOff: 镜像拉取失败 (镜像不存在或名称错误)
# - CrashLoopBackOff: 应用启动失败 (检查应用日志)
# - Pending: 资源不足 (检查节点资源)
```

### 应用运行时问题

**问题: API无法访问**
```bash
# 1. 检查Pod状态
kubectl get pods -l app=demo-app

# 2. 检查Service
kubectl get svc demo-app

# 3. 检查端口转发
kubectl port-forward svc/demo-app 8080:8080

# 4. 测试Pod内部连接
kubectl exec -it <pod-name> -- wget -O- http://localhost:8080/api/hello
```

**问题: Pod频繁重启**
```bash
# 查看Pod日志
kubectl logs -l app=demo-app --previous

# 检查资源限制
kubectl describe pod -l app=demo-app | grep -A 5 "Limits"

# 调整探针参数 (修改 deployment.yaml)
# - 增加 initialDelaySeconds
# - 增加 timeoutSeconds
# - 减少 failureThreshold
```

---

## 清理资源

### 删除应用

```bash
# 删除Deployment和Service
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/service.yaml

# 或使用标签删除
kubectl delete deployment,service -l app=demo-app

# 删除Docker镜像
docker rmi demo-app:1.0.0
docker rmi demo-app:latest
```

### 删除Jenkins任务

1. 进入Jenkins
2. 找到任务 `demo-app-pipeline`
3. 点击 **Delete Pipeline**

---

## 最佳实践

### 1. 版本管理
- 使用语义化版本号 (Semantic Versioning)
- 为每个版本打Git标签: `git tag v1.0.0`
- 在Dockerfile和K8s配置中使用明确的版本号

### 2. 镜像优化
- 使用多阶段构建减小镜像体积
- 使用Alpine Linux作为基础镜像
- 不要在镜像中包含敏感信息

### 3. 健康检查
- 配置Liveness Probe检测应用是否存活
- 配置Readiness Probe检测应用是否就绪
- 配置Startup Probe给应用充足的启动时间

### 4. 资源限制
- 为每个容器设置合理的资源requests和limits
- 避免资源过度分配或不足

### 5. 日志管理
- 使用结构化日志 (JSON格式)
- 日志输出到stdout/stderr
- 集成ELK或Loki进行日志聚合

### 6. 安全性
- 使用非root用户运行容器
- 定期扫描镜像漏洞
- 敏感信息使用Secret管理

---

## 下一步学习

1. **高级CI/CD功能**
   - 多环境部署 (dev/test/prod)
   - 蓝绿部署和金丝雀发布
   - GitOps with ArgoCD

2. **Service Mesh**
   - Istio流量管理
   - 服务网格可观测性
   - 分布式追踪 (Jaeger)

3. **高可用架构**
   - 多副本部署
   - Pod反亲和性
   - 跨可用区部署

4. **完整微服务项目**
   - Spring Cloud微服务架构
   - 服务注册与发现 (Consul)
   - 配置中心 (Spring Cloud Config)
   - API网关 (Spring Cloud Gateway)

---

## 常用命令速查

```bash
# Maven
mvn clean package              # 编译打包
mvn test                       # 运行测试
mvn spring-boot:run           # 运行应用

# Docker
docker build -t <image>:<tag> .    # 构建镜像
docker run -d -p 8080:8080 <image> # 运行容器
docker logs -f <container>         # 查看日志
docker exec -it <container> sh     # 进入容器

# Kubernetes
kubectl get pods                   # 查看Pod
kubectl get svc                    # 查看Service
kubectl logs <pod>                 # 查看日志
kubectl describe pod <pod>         # 查看详情
kubectl delete pod <pod>           # 删除Pod
kubectl rollout restart deployment/<name>  # 重启Deployment

# Git
git status                         # 查看状态
git add .                          # 添加所有文件
git commit -m "message"            # 提交
git push origin main               # 推送到远程
```

---

## 联系与支持

如有问题或建议，请查看以下资源:

- **项目主文档**: `/Users/bjsttlp324/Desktop/learn/software/README.md`
- **安装说明**: `/Users/bjsttlp324/Desktop/learn/software/最终安装报告.md`
- **学习路径**: `/Users/bjsttlp324/Desktop/learn/software/learning-path.md`

---

**祝你CI/CD之旅顺利！** 🚀
