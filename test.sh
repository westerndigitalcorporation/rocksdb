#!/bin/bash

ZONEDEV=$1
TARGET_FZ=$((256 * 1024 * 1024))

echo deadline > /sys/class/block/$ZONEDEV/queue/scheduler

# Run db bench

if [ -z "$2" ]; then
	NUM=50000
else
	NUM="$2"
fi

if [ "$3" == "posix" ]; then
	ARGS=""
else
	ARGS="--fs_uri zenfs://$ZONEDEV"
fi

IOSTAT_FILENAME="/tmp/iostat_$ZONEDEV.txt"
if [ "$4" == "iostat" ]; then
  IOSTAT_CMD="iostat -x $ZONEDEV -c 1 -t"
  echo "Running: $IOSTAT_CMD and storing the output in $IOSTAT_FILENAME"
  $IOSTAT_CMD |ts '%s' >$IOSTAT_FILENAME &
fi

ARGS="$ARGS -use_direct_io_for_flush_and_compaction -benchmarks fillrandom -num $NUM  --key_size=20 --value_size=1200 --max_background_jobs=8 --open_files=8 --target_file_size_base=$TARGET_FZ --write_buffer_size=$TARGET_FZ"

echo "RUNNING WITH ARGUMENTS " "$ARGS"

./db_bench $ARGS

ret=$?

if [ $ret -ne 0 ]; then
	echo "TEST FAILED"
else
	echo "TEST OK"
fi

if [ "$4" == "iostat" ]; then
  kill $!
fi
