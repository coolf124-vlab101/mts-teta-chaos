#!/bin/bash
sudo ifdown ens160
sleep 301
sudo ifup ens160
sudo netplan apply

