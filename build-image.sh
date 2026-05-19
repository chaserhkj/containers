#!/bin/bash
# bash-based helper script to construct build command line from envs

set -e

[[ -n ${CTR_DEBUG} ]] && set -x
tool=${CTR_BUILD_TOOL:-podman}
sub_cmd=${CTR_BUILD_TOOL_SUB_CMD:-build}
echo Build command: "$tool $sub_cmd"

# Read extra build flags set from env using null-termed strings
extra_build_flags=()
while IFS= read -r -d '' item; do
    extra_build_flags+=("$item")
done < <(echo "${CTR_BUILD_FLAGS}" | xargs printf '%s\0')

build_flags=()

# Read build args from env CTR_BUILD_ARG_<build arg name>
for build_arg_var_name in "${!CTR_BUILD_ARG_@}"; do
  value="${!build_arg_var_name}"
  build_arg_name="${build_arg_var_name#CTR_BUILD_ARG_}"
  export "$build_arg_name"="$value"
  echo Build arg: "$build_arg_name"="'$value'"
  build_flags+=("--build-arg" "$build_arg_name")
done

# Read build context image redirection from env
# CTR_BUILD_CONTEXT_FROM_<id> and CTR_BUILD_CONTEXT_IMG_<id>
# Values are supposed to be container image refs
for build_context_var_name in "${!CTR_BUILD_CONTEXT_FROM_@}"; do
  context_id="${build_context_var_name#CTR_BUILD_CONTEXT_FROM_}"
  context_from="${!build_context_var_name}"
  [[ -z $context_from ]] && continue
  value_var="CTR_BUILD_CONTEXT_IMG_${context_id}"
  value="${!value_var:?${value_var} not set}"
  spec="container-image://$value"
  echo Build context: "$context_from"="$spec"
  build_flags+=("--build-context" "$context_from=$spec")
done

[[ -n "${CTR_BUILD_FROM}" ]] && build_flags+=("--from" "${CTR_BUILD_FROM}")

[[ -n "${extra_build_flags[@]}" ]] && build_flags+=("${extra_build_flags[@]}")

declare -p build_flags

[[ -n "${CTR_BUILD_DRY_RUN}" ]] && exit 0

exec "$tool" "$sub_cmd" "${build_flags[@]}" "$@"
