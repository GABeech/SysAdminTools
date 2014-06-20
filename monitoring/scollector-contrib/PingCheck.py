#!/usr/bin/python
from commands import getoutput
import re
import time
from sys import argv

with open("%s.hosts" % argv[0]) as f:
        hosts=f.readlines()

while 1==1:
        for host in hosts:
                hostname = host.strip("\r\n")
                cmdline="/bin/ping -c 10 %s" % (hostname)
                foo = getoutput(cmdline)

                packetstr=re.search('(\d+) packets transmitted, (\d+) received, (\d+)% packet loss, time (\d+)ms',foo)
                PacketsTx=packetstr.group(1)
                PacketsRx=packetstr.group(2)
                PacketLoss=packetstr.group(3)
                TotalTime=packetstr.group(4)


                rttstr=re.search('rtt.*?= (.*?)\/(.*?)\/(.*?)\/(.*)\ ', foo)
                RttMin=rttstr.group(1)
                RttAvg=rttstr.group(2)
                RttMax=rttstr.group(3)
                RttDev=rttstr.group(4)

                ts=time.time()

                print "net.ping.packets %d %s destination=%s operation=transmitted" % (ts, PacketsTx, hostname)
                print "net.ping.packets %d %s destination=%s operation=received" % (ts, PacketsRx, hostname)
                print "net.ping.packetloss %d %s destination=%s" % (ts, PacketLoss, hostname)

                print "net.ping.rtt %d %s destination=%s calculation=min" % (ts, RttMin, hostname)
                print "net.ping.rtt %d %s destination=%s calculation=avg" % (ts, RttAvg, hostname)
                print "net.ping.rtt %d %s destination=%s calculation=max" % (ts, RttMax, hostname)
                print "net.ping.rtt %d %s destination=%s calculation=dev" % (ts, RttDev, hostname)

                print "net.ping.execution_time %d %s destination=%s" % (ts, TotalTime, hostname)
        time.sleep(5)


