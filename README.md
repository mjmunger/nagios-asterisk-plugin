# nagios-asterisk-plugin
Monitor sip extensions using nagios + nrpe server.

## Setup
1. Install nagios + nagios-nrpe-server on your asterisk box.
1. Configure security as appropriate. (Asterisk boxes are high value targets for bad guys!)
1. Give your nagios user sudo rights, because this needs to execute `asterisk -rx'sip show peers'`. Then, put this in the path, and make the following config settings:

1. in /etc/nagios/nrpe.cfg, add:

    command[check_phone]=sudo /usr/local/bin/check_phone.sh $ARG1$

1. Configure nrpe to allow arguments to be accepted (don't_blame_nrpe=1)
1. On your monitoring server to use check_nrpe to check phones on the asterisk box:

    define command {
        command_name    check_phone
        command_line    /usr/local/bin/check_nrpe -H $HOSTADDRESS$ -c check_phone -a $ARG1$
    }

1. Setup your service definition:

    define service {
       use                 generic-service
       service_description SIP 102
       host                your-voip-host
       check_command       check_phone!102
       #check_period       your-monitoring-time
    }

## How it works
1. First, we grep the result to get the line that "starts with extension #123". 
1. Next, we are using `awk` to parse that line and looking to see what the last whitespace delimited column is. if it is "ms)", then we know the peer on this line is connected and "OK". If it's *UNKNOWN* or *Unmonitored*, no further processing is necessary . The peer is either dead or we unmonitored. We return a critical or warning on the spot.
1. If the peer is OK (online), we re-parse the line on "OK" to get the round trip time.
1. Lastly, we return an "OK (xx ms)" with an exit 0.

## ToDo
1. Refactor. Code is messy, but it works. Setting debug to syslog should be much cleaner. Maybe I'll conver to python. Who knows.
1. If the sip ping is greater than 200ms, we should return a warning because although this peer can make and receive calls, the lag will cause awful performance.