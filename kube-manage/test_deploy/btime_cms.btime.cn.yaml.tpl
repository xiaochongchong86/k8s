apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: btime-cms
spec:
  replicas: 1
  template:
    metadata:
      name: btime-cms
      labels:
        app: btime-cms
        #release-tag: {{.ImageTag}}
    spec:
      containers:
      - image: kub01.news.bjyt.qihoo.net:5000/cms.btime.cn:{{.ImageTag}}
        name: cms
        env:
          - name: MY_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: MY_POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
        ports:
          - containerPort: 8360
        securityContext:
          capabilities:
            add:
              - SYS_PTRACE
        volumeMounts:
          - mountPath: /etc/localtime
            name: timezone-prc
            readOnly: true
          - mountPath: /home/s/apps/qlogd/log
            name: data
          - mountPath: /home/s/logs
            name: log
          - mountPath: /home/s/apps/nginx/logs
            name: log
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "rm -rf /home/s/logs/* && rm -rf /home/s/apps/nginx/logs/*"] 

      - image: kub01.news.bjyt.qihoo.net:5000/btime_qconf:1.0.5
        name: qconf
        env:
          - name: MY_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: MY_POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
        volumeMounts:
          - mountPath: /etc/localtime
            name: timezone-prc
            readOnly: true

      - image: kub01.news.bjyt.qihoo.net:5000/btime_qlogd:1.0.1
        name: qlogd
        env:
          - name: MY_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: MY_POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
        ports:
          - containerPort: 8999
        volumeMounts:
          - mountPath: /etc/localtime
            name: timezone-prc
            readOnly: true

      volumes:
        - name: data
          emptyDir: {}
        - name: timezone-prc
          hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai
        - name: log
          glusterfs:
            endpoints: glusterfs-cluster-test
            path: "gv03"
            readOnly: false

# 测试用service入口
---
apiVersion: v1 
kind: Service
metadata:
  name: btime-cms-4test
spec:
  ports:
  - port: 8360
    targetPort: 8360
    protocol: TCP
  selector:
    app: btime-cms

# 线上流量用service入口
---
apiVersion: v1 
kind: Service
metadata:
  name: btime-cms-4product
spec:
  ports:
  - port: 8360
    targetPort: 8360
    protocol: TCP
  selector:
    app: none # 默认线上流量为下线状态

# http ingress 测试用
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: btime-cms-4test
  namespace: default
spec:
  rules:
  - host: cms.test.btime-kube.net
    http:
      paths:
      - backend:
          serviceName: btime-cms-4test
          servicePort: 8360
