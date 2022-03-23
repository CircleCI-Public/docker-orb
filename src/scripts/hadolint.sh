if [ -n "$PARAM_IGNORE_RULES" ]; then
  readonly ignore_rules="$(printf '%s\n' \"--ignore ${PARAM_IGNORE_RULES//,/ --ignore}\")"
fi

if [ -n "$PARAM_TRUSTED_REGISTRIES" ]; then
  readonly trusted_registries="$(printf '%s\n' \"--trusted-registry ${PARAM_TRUSTED_REGISTRIES//,/ --trusted-registry}\")"
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
    ${ignore_rules:+"$ignore_rules"} \
    ${trusted_registries:+"$trusted_registries"} \
    $dockerfile

  printf '%s\n' "Success! $dockerfile linted; no issues found"
done
