# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

Install_Hadolint() {
  if uname -a | grep "Darwin"; then
    export SYS_ENV_PLATFORM="Darwin"
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
    set -x
    $SUDO wget -O /bin/hadolint "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-${SYS_ENV_PLATFORM}"
    $SUDO chmod +x /bin/hadolint
    set +x
  fi
}

if [ ! "$(command -v hadolint)" ]; then
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
