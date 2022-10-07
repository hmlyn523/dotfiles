PREFIX="/sys/class/backlight/intel_backlight"
# PREFIX="/sys/class/backlight/acpi_video0"

MAX=$(cat ${PREFIX}/max_brightness)
CURRENT=$(cat ${PREFIX}/brightness)

PER=$((MAX/100))
case "$1" in
    up)
        VALUE=$(echo "${CURRENT} + ${PER}" | bc) ;;
    down)
        VALUE=$(echo "${CURRENT} - ${PER}" | bc) ;;
    *)
        echo "Invalid argument."
        exit 1 ;;
esac

[ ${VALUE} -gt ${MAX} ] && VALUE=${MAX}
[ ${VALUE} -lt  1 ] && VALUE=1

echo ${VALUE} | sudo tee ${PREFIX}/brightness >/dev/null
