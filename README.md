# System Usage Information
Linux System Usage Information Script

Copyright © 2020 Teal Dulcet

Script to quickly output system usage information on Linux, including:

* Processor (CPU) usage
	* CPU Sockets/Cores/Threads
	* CPU Thread usage
* Load average (1, 5, 15 minutes)
* ^^Pressure Stall (PSI) average (10 seconds, 1, 5 minutes)
	* PSI Some CPU
	* PSI Some RAM
	* PSI Some IO
* \*Temperature(es)
* Memory (RAM) usage
* Swap space usage
* Users logged in (number of)
* Idle time (last activity)
* Processes/Threads
* Disk space usage
* Disk IO usage (read/write)
* Network usage (receive/transmit)
* ^Graphics Processor (GPU) usage
	* GPU Memory (RAM) usage
	* GPU Temperature(es)
* \*Battery (percentage charged and status)
* Uptime
* Hostname (FQDN)
* Private IP address(es)
* \*\*[Public IP address](https://github.com/major/icanhaz)(es)
* \*\*[Weather](https://github.com/chubin/wttr.in)

\* If present\
\*\* Optional\
^ Requires Nvidia GPU(s)\
^^ Requires Linux kernel ≥ 4.20

RAM, swap space, disk and network usage is output in both IEC (powers of 1024) and SI (powers of 1000) units, but with [more precision](https://github.com/tdulcet/Numbers-Tool#comparison-of---to-option) then the [numfmt](https://www.gnu.org/software/coreutils/manual/html_node/numfmt-invocation.html) command from GNU Coreutils. Uses [terminal colors and formatting](https://misc.flogisoft.com/bash/tip_colors_and_formatting) to output the information to the console. For the colors, green means good, yellow means warning and red means critical.

Requires Bash 4+. Compared to similar programs, this script outputs much more information. Useful for displaying a [message of the day](https://en.wikipedia.org/wiki/Motd_(Unix)) (motd) upon login on Linux. All the values are saved to variables, which makes this easy to incorporate into larger scripts.

To monitor the status of one or more servers, please see the [Remote Servers Status Monitoring](https://github.com/tdulcet/Remote-Servers-Status) script.

❤️ Please visit [tealdulcet.com](https://www.tealdulcet.com/) to support this script and my other software development.

![](images/Ubuntu%20Desktop.png)

Also see the [Linux System Information](https://github.com/tdulcet/Linux-System-Information) script.

## Usage

Supports all modern Linux distributions and the [Windows Subsystem for Linux](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux) (WSL).

See [Help](#help) below for full usage information.

### wget

```bash
wget https://raw.github.com/tdulcet/System-Usage-Information/master/usage.sh -qO - | bash -s --
```

### curl

```bash
curl https://raw.github.com/tdulcet/System-Usage-Information/master/usage.sh | bash -s --
```

### Message of the day (motd)

1. Download the script ([usage.sh](usage.sh)). Run: `wget https://raw.github.com/tdulcet/System-Usage-Information/master/usage.sh`.
2. There are some variables at the top of the script users can set to change the output, including the thresholds for the colors.
3. Install the script. Run: `sudo mv usage.sh /usr/local/bin/usage` and `sudo chmod +x /usr/local/bin/usage`.
4. Create a new script in the `/etc/update-motd.d/` directory that runs Linux System Usage Information script, for example called `50-sys-usage-info`:
```bash
#!/bin/sh

usage -sw
```
5. Execute the new script once to make sure there are no errors. For example, run: `sudo chmod +x /etc/update-motd.d/50-sys-usage-info` and `/etc/update-motd.d/50-sys-usage-info`.

See [here](https://ownyourbits.com/2017/04/05/customize-your-motd-login-message-in-debian-and-ubuntu/) for more information.

## Help

```
$ usage -h
Usage:  usage [OPTION(S)]...

Options:
    -p              Show Public IP addresses and hostnames
                        Requires internet connection.
    -w              Show current Weather
                        Requires internet connection.
    -s              Shorten output
                        Do not show CPU Thread usage and PSI averages. Useful for displaying a message of the day (motd).
    -u              Use Unicode usage bars

    -h              Display this help and exit
    -v              Output version information and exit

Examples:
    Output everything
    $ usage -pw

```

## Contributing

Pull requests welcome! Ideas for contributions:

* Add more system usage information
	* Show Wi-Fi signal quality without using the deprecated [Wireless tools](https://en.wikipedia.org/wiki/Wireless_tools_for_Linux) or `/proc/net/wireless` file.
	* Show total Disk IO and Network usage.
* Add more examples
* Improve the performance
* Support more GPUs
* Port to C/C++ or Rust
