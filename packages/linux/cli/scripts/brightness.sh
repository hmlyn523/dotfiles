# PREFIX="/sys/class/backlight/intel_backlight"
PREFIX="/sys/class/backlight/acpi_video0"

MAX=$(cat ${PREFIX}/max_brightness)
CURRENT=$(cat ${PREFIX}/brightness)

ARG=$(echo ${1:?} | awk '{print $1*1}')
VALUE=$(echo "${CURRENT} + ${ARG}" | bc)

[ ${VALUE} -gt ${MAX} ] && VALUE=${MAX}
[ ${VALUE} -lt  1 ] && VALUE=1

echo ${VALUE} | sudo tee ${PREFIX}/brightness >/dev/null
