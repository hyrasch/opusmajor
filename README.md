# player-data-api

A minimal Go service that exposes player data for a multiplayer game, deployed on Kubernetes via ArgoCD.

## Architecture

playerDataApi/   Go HTTP service (/player-data, /healthz)
k8s/
  base/          Deployment + ClusterIP Service
  overlays/
    local/       Patches service to NodePort :30080 for local access
argocd/          ArgoCD Application manifest pointing at k8s/overlays/local


The image is tagged with `git describe --tags` and the tag is written into `k8s/base/kustomization.yaml` on each publish. ArgoCD detects that change and rolls out the new version automatically

## Prerequisites

- Docker
- kubectl + Minikube
- kustomize CLI

## First-time setup

```bash
minikube start
make argocd-install      # installs ArgoCD into the argocd namespace
make argocd-apply        # registers the Application with ArgoCD
```

ArgoCD will sync within 3 minutes and deploy the service. To force an immediate sync:
```bash
make argocd-refresh
```

## Accessing the service

This is done because of the minikube base driver (docker) which is causing issues on windows.
I could have switched it to hyperv or use this feature from minikube
source: https://stackoverflow.com/questions/71714919/unable-to-access-my-minikube-cluster-from-the-browser-because-you-are-using-a

```bash
make open                # opens the service URL via minikube tunnel
```

## Observability

Logs and cluster health can be observed using k9s

Endpoints:
- `GET /player-data` — returns static player list
- `GET /healthz` — liveness/readiness probe

## Deploying a new version

```bash
git tag v1.x.x
make docker-publish
```

This builds and pushes the image, updates the image tag in `k8s/base/kustomization.yaml`, and pushes to GitHub. ArgoCD picks up the change and deploys automatically.

## Spec ambiguity

Both /player-data and /update-player-data are mentionned in the specs but it's also mentionned that the Go application should only have a GET endpoint /player-dat so I ignore /update-player-data

## Trade-offs

- **`latest` tag replaced by git describe** — using `latest` in a GitOps setup means ArgoCD can never detect an image change since the manifest doesn't change. Tags derived from git make every release traceable and detectable.
- **No CI pipeline** — `make docker-publish` manually does what a GitHub Actions workflow would do in production (build, push, update manifest, commit). The steps are identical, just not automated on push.
- **Single overlay** — only a `local` overlay exists. A production setup would add a `prod` overlay with higher replica counts, stricter resource limits, and a proper ingress.
- **NodePort exposure** — chosen for simplicity with Minikube. On a real cluster this would be an Ingress or a cloud load balancer.
