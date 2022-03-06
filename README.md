# merlin-tkg


# Pre-Req:

## Binaries
- Download tanzu cli from https://customerconnect.vmware.com/en/downloads/info/slug/infrastructure_operations_management/vmware_tanzu_kubernetes_grid/1_x (eg: 1.5.1. You must download the linux version regardless of your host OS) and place it in binaries directory.




# KB: AVI latest version issue with tkgm
https://kb.vmware.com/s/article/87640
kubectl patch pkgi ako-operator -n tkg-system --type "json" -p '[{"op":"replace","path":"/spec/paused","value":true}]'
kubectl set env deployment/ako-operator-controller-manager avi_controller_version="21.1.3" -n tkg-system-networking
AKOoperatorPod=kubectl get pod -n tkg-system-networking -o json | jq -r '.items[] | select(.metadata.name | startswith("ako-operator-controller-manager-")) | .metadata.name'
kubectl delete pod $AKOoperatorPod -n tkg-system-networking
unset AKOoperatorPod

