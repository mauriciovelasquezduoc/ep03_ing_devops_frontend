# Kubernetes - Proyecto frontend

Configuración autónoma para desplegar el frontend (Nginx) en Kubernetes. Este proyecto se instala de forma independiente, sin depender de un repo centralizado.

## Estructura

```
k8s/
├── values.yaml                   # Configuración del proyecto
├── templates/
│   ├── namespace.yaml            # Namespace compartido (idempotente)
│   ├── frontend-deployment.yaml  # Nginx con RollingUpdate + BACKEND_HOST
│   ├── frontend-service.yaml     # LoadBalancer público (AWS internet-facing)
│   └── frontend-hpa.yaml         # Autoscaling por CPU
├── output/                       # YAMLs generados (gitignore)
├── generate.sh                   # Solo genera los YAMLs
└── apply.sh                      # Genera y aplica
```

## Instalación

```bash
cd k8s
./apply.sh
```

Opcionalmente, si el cluster es EKS y quieres actualizar el kubeconfig desde este repo:

```bash
CLUSTER_NAME=laboratorio-ep03-eks ./apply.sh
```

## Previsualizar sin aplicar

```bash
./generate.sh
```

## Configuración

Edita `values.yaml`:

```bash
NAMESPACE=ep03                                  # debe coincidir con database y backend
FRONTEND_IMAGE=<AWSAccountId>.dkr.ecr.us-east-1.amazonaws.com/ep03-frontend:latest
FRONTEND_PORT=80
FRONTEND_REPLICAS=2
FRONTEND_HPA_MIN=2
FRONTEND_HPA_MAX=6
FRONTEND_HPA_CPU=60
```

La cuenta AWS de la imagen no se hardcodea: `apply.sh` la resuelve en runtime con `aws sts get-caller-identity`.

## Prerrequisito: aplicar database y backend primero

El frontend apunta al Service del backend vía `BACKEND_HOST=${NAMESPACE}-backend.${NAMESPACE}.svc.cluster.local`. `apply.sh` valida que ese Service exista y falla con un mensaje claro si no:

```bash
cd ../ep03_ing_devops_database/k8s && ./apply.sh   # 1. database
cd ../ep03_ing_devops_backend/k8s && ./apply.sh    # 2. backend
cd ../ep03_ing_devops_frontend/k8s && ./apply.sh   # 3. frontend (este)
```

## Obtener la URL pública

```bash
kubectl get service ${NAMESPACE}-frontend -n ep03
# El EXTERNAL-IP del LoadBalancer es la URL de la app
```

## Acoplamientos con otros proyectos

| Valor | Origen | Uso |
|---|---|---|
| `NAMESPACE` | database / backend | namespace compartido |
| Service `${NAMESPACE}-backend` | proyecto backend | `BACKEND_HOST` (FQDN) del frontend |

## Verificación

```bash
kubectl get all -n ep03
kubectl get hpa -n ep03
```
