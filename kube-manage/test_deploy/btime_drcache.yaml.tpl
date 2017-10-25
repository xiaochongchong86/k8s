apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: btime-dagradation-4test
spec:
  replicas: 1
  template:
    metadata:
      name: btime-dagradation-4test
      labels:
        app: btime-dagradation-4test
        release-tag: {{.ImageTag}}
    spec:
      containers:
      #- image: kub01.news.bjyt.qihoo.net:5000/drcache:20170628174650
      - image: kub01.news.bjyt.qihoo.net:5000/drcache:{{.ImageTag}}
        name: degradation
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
          - containerPort: 7576
        volumeMounts:
          - mountPath: /home/s/apps/qlogd/log
            name: data

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
      volumes:
        - name: data
          emptyDir: {}


---
apiVersion: v1 
kind: Service
metadata:
  name: btime-drcache-4test
spec:
  ports:
  - port: 7576
    targetPort: 7576
    protocol: TCP
  selector:
    app: btime-dagradation-4test


#---
#apiVersion: extensions/v1beta1
#kind: Ingress
#metadata:
#  name: btime-drcache-4test
#  namespace: default
#spec:
#  rules:
#  - host: drcache.test.kube.net
#    http:
#      paths:
#      - backend:
#          serviceName: btime-drcache-4test
#          servicePort: 7576
