#!/bin/bash
sudo tc qdisc del dev ens160 root
sudo tc qdisc add dev ens160 root handle 1: prio
sudo tc filter add dev ens160 parent 1:0 protocol ip pref 55 handle ::55 u32 match ip dst 10.0.10.3 flowid 2:1
sudo tc qdisc add dev ens160 parent 1:1 handle 2: netem delay 1000ms 500ms loss 25.0%
sudo at now + 5 minutes sudo tc qdisc del dev ens160 root
