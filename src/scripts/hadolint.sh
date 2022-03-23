if [ -n "$PARAM_IGNORE_RULES" ]; then
  readonly ignore_rules="$(printf '%s\n' \"--ignore ${PARAM_IGNORE_RULES//,/ --ignore}\")"
fi

if [ -n "$PARAM_TRUSTED_REGISTRIES" ]; then
  readonly trusted_registries="$(printf '%s\n' \"--trusted-registry ${PARAM_TRUSTED_REGISTRIES//,/ --trusted-registry}\")"
fi

printf '%s\n' "Running hadolint with the following options..."
printf '%s\n' "$ignore_rules"
printf '%s\n' "$trusted_registries"

readonly dockerfiles="$PARAM_DOCKERFILES"

# use colon delimiters to create array
arrDOCKERFILES=(${DOCKERFILES//:/ })
let END=${#arrDOCKERFILES[@]}

for ((i=0;i<END;i++)); do
  DOCKERFILE="${arrDOCKERFILES[i]}"

  hadolint \
    ${ignore_rules:+"$ignore_rules"} \
    ${trusted_registries:+"$trusted_registries"} \
    $DOCKERFILE

  printf '%s\n' "Success! $DOCKERFILE linted; no issues found"
done
