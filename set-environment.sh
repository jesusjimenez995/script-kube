#!/bin/bash
#
# Manages the local kubernetes cluster for development purpouses

set -o errexit
set -o pipefail
#set -o nounset
# set -o xtrace

IFS=$'\n\t'
readonly IAC_MINIKUBE_BIN="minikube"
readonly IAC_DOCKER_BIN="docker"
readonly IAC_K8S_PROFILE="iac-minikube"

deps() {
  echo "[1/2]🔎   checking dependencies: minikube"
  if ! command -v "${IAC_MINIKUBE_BIN}" > /dev/null; then
    echo "💀   You must install minikube on your system before setup can continue"
    echo "ℹ️   visit https://minikube.sigs.k8s.io/docs/start/"
    exit 1
  fi

  echo "[2/2]🔎   checking dependencies: docker"
  if ! command -v "${IAC_DOCKER_BIN}" > /dev/null; then
    echo "💀   You must install docker on your system before setup can continue"
    exit 1
  fi
}

usage() {
cat<<EOF
Manage your local k8s cluster
Usage: $0
    up    Starts a minikube cluter
    down  Stops local minikube cluster
    clean Clean local minikube cluster (deletes it)
    docker-env use with eval to configure docker variables
               to connect to this minikube cluster instance
    ssh   Jump to an ssh session in minikube machine
EOF
}

_up() {
  local IAC_K8S_MEM="${IAC_K8S_MEM:-8192}"
  local IAC_K8S_CPUS="${IAC_K8S_CPUS:-2}"
  local IAC_K8S_DISK="${IAC_K8S_DISK:-50g}"
  local IAC_K8S_DRIVER="${IAC_K8S_DRIVER:-docker}"

  echo "[1/4]🏄   configure local ~/.minikube folder"
  if [ -f ~/.docker/config.json ]; then
    mkdir -p ~/.minikube/home/docker/.docker
    cp ~/.docker/config.json ~/.minikube/home/docker/.docker/config.json
  fi

  echo "[2/4]🔎   checking for existing minikube instance"

  # Check if there's already a running instance of minikube
  if ! minikube status --profile="${IAC_K8S_PROFILE}" > /dev/null; then
    echo "[3/4]ℹ️   Creating new ${IAC_K8S_PROFILE} instance"
    minikube start  --memory "${IAC_K8S_MEM}" --cpus "${IAC_K8S_CPUS}" \
                    --disk-size "${IAC_K8S_DISK}" --driver="${IAC_K8S_DRIVER}" \
                    --profile "${IAC_K8S_PROFILE}"
  else
     echo "[3/4]🏄   Found an ${IAC_K8S_PROFILE} instance, starting it"
     minikube start --profile "${IAC_K8S_PROFILE}"
  fi
}

_docker() {
  echo "[1/1]🏄   Configuring docker profile to your ${IAC_K8S_PROFILE} cluster instance"
  minikube docker-env --profile "${IAC_K8S_PROFILE}" --shell "$SHELL"
}

_ssh() {
  echo "[1/2]🔎   checking for running instance"
  # Check if there's already a running instance of minikube
  if minikube status --profile="${IAC_K8S_PROFILE}" > /dev/null; then
    echo "[2/2]ℹ️   SSHing into ${IAC_K8S_PROFILE} instance"
    minikube ssh  --profile "${IAC_K8S_PROFILE}"
  else
     echo "[2/2]ℹ️   Instance ${IAC_K8S_PROFILE} not found, have you 'up' first?"
  fi
}

_down() {
  echo "[1/2]🔎   checking for running instance"

  # Check if there's already a running instance of minikube
  if minikube status --profile="${IAC_K8S_PROFILE}" > /dev/null; then
    echo "[2/2]✋   Stopping ${IAC_K8S_PROFILE} instance"
    minikube stop  --profile "${IAC_K8S_PROFILE}"
  else
     echo "[2/2]ℹ️   Instance ${IAC_K8S_PROFILE} not found, have you 'up' first?"
  fi

}

_clean() {
  minikube delete --profile "${IAC_K8S_PROFILE}"
  eval "$(minikube docker-env --profile "${IAC_K8S_PROFILE}" --shell "$SHELL" --unset)"
}

# .............................................................................
# ENTRYPOINT
# .............................................................................
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

case $1 in
  up)
    deps
    _up
    ;;
  down)
    deps
    _down
    ;;
  clean)
    deps
    _clean
    ;;
  docker-env)
    deps
    _docker
    ;;
  ssh)
    deps
    _ssh
    ;;
  *)
    usage
    exit
    ;;
esac
