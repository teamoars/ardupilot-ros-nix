set -eux

for n in $(seq 1 3); do
	gz topic -t "/camera-${n}/enable_streaming" -m gz.msgs.Boolean -p "data: 1"
done
