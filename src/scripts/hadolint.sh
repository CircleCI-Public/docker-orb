# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

Install_Hadolint() {
  if uname -a | grep "Darwin"; then
    SYS_ENV_PLATFORM="Darwin"
    brew install hadolint
  elif uname -a | grep "x86_64 GNU/Linux"; then
    export SYS_ENV_PLATFORM=Linux-x86_64
  elif uname -a | grep  "aarch64 GNU/Linux"; then
    export SYS_ENV_PLATFORM=Linux-arm64
	else 
		echo "This platform appears to be unsupported."
    uname -a
    exit 1
	fi
	
  if [ "${SYS_ENV_PLATFORM}" != "Darwin" ]; then
    $SUDO wget -O /bin/hadolint "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-${SYS_ENV_PLATFORM}"
    $SUDO chmod +x /bin/hadolint
  fi
}

if ! command -v hadolint &> /dev/null; then
	Install_Hadolint
fi 

if [ -n "$PARAM_IGNORE_RULES" ]; then
  ignore_rules=$(printf '%s' "--ignore ${PARAM_IGNORE_RULES//,/ --ignore }")
  readonly ignore_rules
fi


if [ -n "$PARAM_TRUSTED_REGISTRIES" ]; then
  trusted_registries=$(printf '%s' "--trusted-registry ${PARAM_TRUSTED_REGISTRIES//,/ --trusted-registry }")
  readonly trusted_registries
fi

failure_threshold=$(printf '%s' "--failure-threshold ${PARAM_FAILURE_THRESHOLD}")
readonly failure_threshold

printf '%s\n' "Running hadolint with the following options..."
printf '%s\n' "$ignore_rules"
printf '%s\n' "$trusted_registries"
printf '%s\n' "$failure_threshold"

# use colon delimiters to create array
readonly old_ifs="$IFS"
IFS=":"

read -ra dockerfiles <<< "$PARAM_DOCKERFILES"
IFS="$old_ifs"

for dockerfile in "${dockerfiles[@]}"; do
  set -x
  hadolint \
    ${PARAM_FAILURE_THRESHOLD:+$failure_threshold} \
    ${PARAM_IGNORE_RULES:+$ignore_rules} \
    ${PARAM_TRUSTED_REGISTRIES:+$trusted_registries} \
    $dockerfile
  set +x
  printf '%s\n' "Success! $dockerfile linted; no issues found"
done
