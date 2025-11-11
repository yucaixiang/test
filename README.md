# Demo App

Spring Boot 示例应用，用于演示企业级 CI/CD 流程。

## 项目结构

```
demo-app/
├── src/                    # Java源代码
├── demo-app-chart/         # Helm Chart部署配置
├── Dockerfile              # Docker镜像构建文件
├── Jenkinsfile             # Jenkins CI/CD Pipeline
└── pom.xml                 # Maven项目配置
```

## 快速开始

### 本地运行

```bash
# 编译
mvn clean package

# 运行
java -jar target/demo-app.jar

# 访问
curl http://localhost:8080/api/hello
```

### Docker构建

```bash
# 构建镜像
docker build -t localhost:30002/demo-app/demo-app:1.0.0 .

# 推送到Harbor
docker push localhost:30002/demo-app/demo-app:1.0.0
```

### Helm部署

```bash
# 安装
helm install demo-app demo-app-chart/ --namespace default

# 升级
helm upgrade demo-app demo-app-chart/ --namespace default --set image.tag=2

# 卸载
helm uninstall demo-app --namespace default
```

## API端点

- `GET /api/hello` - 基础问候接口
- `GET /api/greet?name=<name>` - 个性化问候
- `GET /api/info` - 系统信息
- `GET /actuator/health` - 健康检查

## CI/CD流程

Jenkins Pipeline自动执行：

1. 代码检出
2. Maven构建
3. 单元测试
4. Kaniko构建Docker镜像
5. 推送到Harbor
6. Helm部署到Kubernetes

访问Jenkins: http://localhost:30080

## 部署验证

```bash
# 查看Pod
kubectl get pods -l app=demo-app

# 查看Service
kubectl get svc demo-app

# 测试API
curl http://localhost:30088/api/hello
```

## 配置说明

详细的配置和使用文档请参考上级目录的 `docs/` 文件夹。
