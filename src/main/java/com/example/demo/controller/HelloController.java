package com.example.demo.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * REST API控制器 - 提供测试端点
 * Hello Controller for CI/CD Testing
 */
@RestController
@RequestMapping("/api")
public class HelloController {

    /**
     * 健康检查端点
     * GET /api/hello
     */
    @GetMapping("/hello")
    public Map<String, Object> hello() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Hello from Demo App!");
        response.put("timestamp", getCurrentTime());
        response.put("version", "1.0.0");
        response.put("environment", "Kubernetes");
        return response;
    }

    /**
     * 个性化问候端点
     * GET /api/greet?name=YourName
     */
    @GetMapping("/greet")
    public Map<String, Object> greet(@RequestParam(value = "name", defaultValue = "World") String name) {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Hello, " + name + "!");
        response.put("timestamp", getCurrentTime());
        return response;
    }

    /**
     * 系统信息端点
     * GET /api/info
     */
    @GetMapping("/info")
    public Map<String, Object> info() {
        Map<String, Object> response = new HashMap<>();
        response.put("application", "demo-app");
        response.put("version", "1.0.0");
        response.put("java_version", System.getProperty("java.version"));
        response.put("os", System.getProperty("os.name"));
        response.put("timestamp", getCurrentTime());

        // 获取环境变量（Kubernetes会注入）
        String podName = System.getenv("HOSTNAME");
        String namespace = System.getenv("NAMESPACE");

        if (podName != null) {
            response.put("pod_name", podName);
        }
        if (namespace != null) {
            response.put("namespace", namespace);
        }

        return response;
    }

    /**
     * 获取当前格式化时间
     */
    private String getCurrentTime() {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        return LocalDateTime.now().format(formatter);
    }
}
