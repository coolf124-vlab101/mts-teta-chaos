#!/bin/bash
sudo fio --filename=/tmp/ssd.test.file --size=10GB --direct=1 --rw=randrw --bs=64k --ioengine=libaio --iodepth=64 --runtime=120 --numjobs=4 --time_based --group_reporting --name=throughput-test-job --eta-newline=1
sudo fio ssd-test.fio
