# Demo App Docker 部署指南

## 文件说明

- **Dockerfile**: 多阶段构建的 Docker 镜像定义
- **docker-compose.yml**: 完整的服务编排配置（包含应用、MySQL、Redis）
- **.dockerignore**: Docker 构建时忽略的文件

## 快速开始

### 方式一：使用 Docker Compose（推荐）

```bash
# 进入 docker 目录
cd /Users/bjsttlp324/Desktop/learn/software/CICD/demo-app/docker

# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f demo-app

# 停止所有服务
docker-compose down

# 停止并删除数据卷
docker-compose down -v
```

### 方式二：单独构建和运行

```bash
# 构建镜像
docker build -f docker/Dockerfile -t demo-app:1.0.0 ..

# 运行容器
docker run -d \
  --name demo-app \
  -p 8090:8090 \
  demo-app:1.0.0

# 查看日志
docker logs -f demo-app

# 停止容器
docker stop demo-app
docker rm demo-app
```

## 服务访问

### Demo App
- **访问地址**: http://localhost:8090
- **健康检查**: http://localhost:8090/actuator/health
- **API 端点**:
  - GET http://localhost:8090/api/hello
  - GET http://localhost:8090/api/greet?name=YourName
  - GET http://localhost:8090/api/info

### MySQL（如果启用）
- **端口**: 3307
- **用户名**: demo_user
- **密码**: demo123456
- **数据库**: demo_db
- **Root 密码**: root123456

### Redis（如果启用）
- **端口**: 6380
- **密码**: redis123456

## 环境变量

可以通过环境变量配置应用：

```yaml
environment:
  - SPRING_PROFILES_ACTIVE=prod
  - JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0
```

## 构建参数

### 多阶段构建说明

1. **构建阶段**: 使用 Maven 镜像编译和打包应用
2. **运行阶段**: 使用轻量级 JRE 镜像运行应用

### 优化建议

- 利用 Docker 缓存层：先复制 pom.xml 下载依赖
- 使用非 root 用户运行应用（安全）
- 配置健康检查
- 使用多阶段构建减小镜像大小

## 常用命令

```bash
# 重新构建镜像
docker-compose build --no-cache demo-app

# 查看容器资源使用
docker stats demo-app

# 进入容器
docker exec -it demo-app bash

# 查看应用日志
docker-compose logs -f --tail=100 demo-app

# 重启服务
docker-compose restart demo-app

# 扩展服务（多实例）
docker-compose up -d --scale demo-app=3
```

## 生产环境建议

1. **使用具体版本标签**而不是 `latest`
2. **配置资源限制**:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '1'
         memory: 512M
       reservations:
         cpus: '0.5'
         memory: 256M
   ```

3. **配置日志驱动**:
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

4. **使用 secrets 管理敏感信息**
5. **配置网络策略和安全组**

## 故障排查

### 查看容器日志
```bash
docker-compose logs demo-app
```

### 检查健康状态
```bash
curl http://localhost:8090/actuator/health
```

### 进入容器调试
```bash
docker exec -it demo-app bash
```

### 查看容器资源
```bash
docker stats demo-app
```

## 注意事项

1. 确保端口 8090、3307、6380 未被占用
2. 首次启动 MySQL 需要一些时间初始化
3. 数据卷会持久化数据，删除容器不会丢失数据
4. 生产环境请修改默认密码

---

**相关文档**：
- [项目 README](../README.md)
- [CI/CD 文档](../../docs/)

