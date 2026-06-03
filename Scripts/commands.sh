LABEL_PODBOI="PodBOI.Managed=true"
LABEL_PODBOI_VALIDATION="PodBOI.Validation=true"

CREATE_CONTAINER=("${ROOT[@]}" "podman" "run" "-d")
START_CONTAINER=("${ROOT[@]}" "podman" "container" "start")
STOP_CONTAINER=("${ROOT[@]}" "podman" "container" "stop")
REMOVE_CONTAINER=("${ROOT[@]}" "podman" "container" "rm")
KILL_CONTAINER=("${ROOT[@]}" "podman" "container" "kill")

ATTACH_TO_CONTAINER=("${ROOT[@]}" "podman" "attach")
DETACH_FROM_CONTAINER=("${ROOT[@]}" "podman" "-d")


EXEC_COMMAND=("${ROOT[@]}" "podman" "exec")
COPY=("${ROOT[@]}" "podman" "cp")


GET_CONTAINERS_BY_LABEL_VALIDATION=("${ROOT[@]}" "podman" "container" "ps" "-a" "-q" "--filter" "label=$LABEL_PODBOI_VALIDATION")
GET_CONTAINERS_BY_LABEL=("${ROOT[@]}" "podman" "container" "ps" "--filter" "label=$LABEL_PODBOI" "-a" "-q")
DISPLAY_CONTAINERS=("${ROOT[@]}" "podman" "container" "ps" "-a" "--filter" "label=$LABEL_PODBOI")

INSPECT_CONTAINER=("${ROOT[@]}" "podman" "container" "inspect" "-f" "'{{.State.Running}}'")


#### Pod Commands ####

POD_EXISTS=("${ROOT[@]}" "podman" "pod" "exists")

CREATE_POD=("${ROOT[@]}" "podman" "pod" "create" "--label=$LABEL_PODBOI")
START_POD=("${ROOT[@]}" "podman" "pod" "start")
STOP_POD=("${ROOT[@]}" "podman" "pod" "stop")
KILL_POD=("${ROOT[@]}" "podman" "pod" "kill")
REMOVE_POD=("${ROOT[@]}" "podman" "pod" "rm")
STATUS_OF_POD=("${ROOT[@]}" "podman" "pod" "ps" --filter label=PodBOI.Managed=true)

GET_PODS_BY_LABEL_VALIDATION=("${ROOT[@]}" "podman" "pod" "ps" "-q" "--filter" "label=$LABEL_PODBOI_VALIDATION")
GET_PODS_BY_LABEL=("${ROOT[@]}" "podman" "pod" "ps" "--filter" "label=$LABEL_PODBOI")


#podman pod ps
DISPLAY_ALL_PODS=("${ROOT[@]}" "podman" "pod" "ps" "--filter" "label=$LABEL_PODBOI")
#-append --filter name=$pod_name
DISPLAY_POD=("${ROOT[@]}" "podman" "pod" "ps" "--filter" "label=$LABEL_PODBOI")

INSPECT_POD=("${ROOT[@]}" "podman" "pod" "inspect")
