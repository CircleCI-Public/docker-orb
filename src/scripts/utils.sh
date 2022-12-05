#!/usr/bin/env bash

# Public: Expand the value from environment variables with given prefix.
#
# Takes a prefix as an argument and expands the value of the environment variables
# starting with the prefix. The expansion is done by using the eval command.
#
# $1 - Prefix used to filter the envinronment variables.
#
# Examples
#
#   expand_env_vars_with_prefix "ORB_PARAM_"
#   expand_env_vars_with_prefix "PARAM_"
#
# Returns 1 if no argument is provided or no environment variables were found with prefix.
# Returns 0 if the expansion was successful.
expand_env_vars_with_prefix() {
  if [ "$#" -eq 0 ]; then
    >&2 printf '%s\n' "Please provide a prefix to filter the envinronment variables."
    return 1
  fi

  # Fetch parameters from the environment variables.
  local prefix="$1"
  local env_vars
  env_vars="$(printenv | grep "^$prefix")"

  if [ -z "$env_vars" ]; then
    >&2 printf '%s\n' "No environment variables found with the prefix: \"$prefix\"."
    return 1
  fi

  while IFS= read -ra line; do
    # Split the line into key and value.
    local var_value="${line#*=}"
    local var_name="${line%="$var_value"}"

    # Expand the value.
    local expanded_value
    expanded_value="$(eval echo "$var_value")"

    # The -v option assignes the output to a variable rather than printing it.
    printf -v "$var_name" "%s" "$expanded_value"
  done <<< "$env_vars"
  return 0
}
