IMAGE_NAME ?= player-data-api
IMAGE_TAG  ?= latest
REGISTRY   ?= docker.io/lanrell

FULL_IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

# ── Go ────────────────────────────────────────────────────────────────────────

.PHONY: run
run:
	cd playerDataApi && go run .

# ── Docker ────────────────────────────────────────────────────────────────────

.PHONY: docker-build
docker-build:
	docker build -t $(FULL_IMAGE) ./playerDataApi

.PHONY: docker-push
docker-push:
	docker push $(FULL_IMAGE)

.PHONY: docker-publish
docker-publish: docker-build docker-push

# ── K8S / ArgoCD ───────────────────────────────────────────────────────

.PHONY: deploy
deploy:
	kubectl apply -k k8s/overlays/local

.PHONY: undeploy
undeploy:
	kubectl delete -k k8s/overlays/local

.PHONY: argocd-install
argocd-install:
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl wait --for=condition=available --timeout=120s deployment/argocd-server -n argocd

.PHONY: argocd-apply
argocd-apply:
	kubectl apply -f argocd/application.yaml