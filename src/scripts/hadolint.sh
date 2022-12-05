# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

if [ -n "$PARAM_IGNORE_RULES" ]; then
  ignore_rules=$(printf '%s' "--ignore ${PARAM_IGNORE_RULES//,/ --ignore }")
  readonly ignore_rules
fi

if [ -n "$PARAM_TRUSTED_REGISTRIES" ]; then
  trusted_registries=$(printf '%s' "--trusted-registry ${PARAM_TRUSTED_REGISTRIES//,/ --trusted-registry }")
  readonly trusted_registries
fi

printf '%s\n' "Running hadolint with the following options..."
printf '%s\n' "$ignore_rules"
printf '%s\n' "$trusted_registries"

# use colon delimiters to create array
readonly old_ifs="$IFS"
IFS=":"

read -ra dockerfiles <<< "$PARAM_DOCKERFILES"
IFS="$old_ifs"

for dockerfile in "${dockerfiles[@]}"; do
  hadolint \
    ${PARAM_IGNORE_RULES:+$ignore_rules} \
    ${PARAM_TRUSTED_REGISTRIES:+$trusted_registries} \
    $dockerfile

  printf '%s\n' "Success! $dockerfile linted; no issues found"
done
