
                       Aerial v. 0.14.0.9  - Thu 09 Oct 2014

What is it ?
=======
  Aerial is on of the easiest ways to create a full capable*, high speed*, at any band (5GHz or
  2.4GHz), high through IEEE 802.11n* or not, with Wi-Fi protected setup* (WPS)
  or not, Software Access point on a Kali-Linux box with manipulated/intercepted/injected/
  forced/proxied/MITMed or not traffic.
  
  *When Hostapd is used and depending on your wireless NIC's capabilities.

History
=======
  Aerial is the continuous development of 2009's "wlan_nick" bash script:
  * <a href="http://www.backtrack-linux.org/forums/showthread.php?t=23068">How to: E-Z setup a Multi Mode WLAN based on a Fake AP/</a>

  First of all Aerial is a HUGH bash script. Maybe it's the longest bash script
  you ever seen. It's an 8000 lines long including comments, references, examples etc. 
  I think, this is no good. I'm sure that there is a easiest way to write it but 
  unfortunately I only know bash scripting and my programming skills are very limited.
  (Self learning person). My main concerned was and is to write it in a way that it 
  should be understandable by me. My main goal was to setup a safe environment to run
  my tests and do my experiments and as an result I write Aerial. Aerial is a summary
  of various small bash scripts. I modified it allot, I add so many examples of correct 
  usage, so it could be understandable by any person and not only by me. 
  I decide to release it to the public with the hope that it should  be useful 
  for someone else except me.

About the script
================
The script is meanly splitted in two major sections:

 1. How will we create the SoftAP and how we want it to act. e.g. Hostapd or airbase-ng based / in which band it will broadcast / it should be encrypted (WEP/WPA2) or not (OPEN) / WPS should be enabled/ DHCP server / DNS forward etc.
 2. Now that we have created the SoftAP, what we should do with the incoming and outgoing traffic ? (encrypted or not). Here comes the "14 modes". As long as we have the clients connected to our Kali box, we can do whatever we want with that traffic. We can intercept, proxy, redirect, do MITM attacks, force the clients to visit a specific page, inject Java code etc.

Installation
============
  No installation is required.
  Just run it by :
  
  sh Aerial.sh

  Relax and let the script download/install, create CA certificates etc that
  is needed. DO NOT INTERRUPT IT. Let it finish.
  A new folder named "Aerial" will be created. Everything you want to find
  will be in that folder, e.g.
  -aerial.conf (This script's configuration file)
  -hostapd.conf (Hostapd configuration file)
  -CA-certificates folder and the included certificates.
  -Backup folder with the included files.
  -etc

  When a "Mode" in executed then a new folder will be created with the corresponding 
  name (e.g sslsplit) into the "Aerial" folder with all the files (configuration, logs etc)
  that invoke that "Mode". So the only thing that you have to do, is to run any "Mode" and 
  then look at the corresponding folder of that "Mode".
  If a "Mode" is never executed, none folder will be created for that "Mode".
  
Features
========
  
  * Menu driven.
  * Kali Linux x86 and x64 architectures compatible.
  * BackTrack 5R3 Linux x86 and x64  architectures compatible. (some modes).
  * A configuration file (aerial.conf) with the ability to enable/disable some of the Aerial's menus (speed things up) and/or change directly script's values (ex Internet interface, wireless interface, channel, etc). Please refer to aerial.conf for detailed instructions.
  * Selectable language/date format/long URLs for SARG.
  * All inputs from users are filtered. You can't enter an invalid input. e.g. Internet interface, wireless interface, channel, CRDA, password, etc
  * Multiple examples for correct usage of the script.
  * Backup/restore of any configuration files or folders that it might be changed into the OS by the script.
  * Downloading and installation of all required programs, if they are not present:
    - UDHCPD: Very small Busybox based DHCP server.
    - Aircrack-ng Suite: Wireless WEP/WPA cracking utilities.
    - Proxychains: Redirect connections through proxy servers.
    - Proxyresolv: DNS resolving.
    - Mogrify: Image manipulation programs.
    - Jp2a: Converts jpg images to ASCII.
    - Ghostscript: Interpreter for the PostScript language and for PDF.
    - Apache2: HTTP Server.
    - Dnsmasq: A small caching DNS proxy and DHCP/TFTP server.
    - Haveged: Linux entropy source using the HAVEGE algorithm.
    - Squid3 v3.1.20 :Proxy caching server for web clients.
    - Sarg: Squid Analysis Report Generator.
    - Hostapd v2.3 devel: User space IEEE 802.11 AP and IEEE 802.1X/WPA/WPA2/EAP Authenticator.
      - Hostapd v2.3 devel patch: Disable bss neighbor check/force 40 MHz channels. see (1)
    - TOR: The Onion Router: A connection-based low-latency anonymous communication system.
    - ARM: The Anonymizing Relay Monitor - Terminal status monitor for TOR.
    - I2P router: The Invisible Internet Project.
    - Sslstrip: SSL/TLS man-in-the-middle attack tool.
    - Sslsplit: Transparent and scalable SSL/TLS interception.
    - Mitmproxy: SSL-capable man-in-the-middle HTTP proxy.
    - Honey Proxy: HTTP(S) Traffic investigation and analysis.
  * Supplied with Aerial.0.x.x.tar.bz2:
     - Airchat v2.1a: Wireless Fun. (No installation is required. The script will handles this).
     - Installation packages Squid3-i386 and Squid3-amd64 v.3.3.8 compiled with SSL Bumping 
       and Dynamic SSL Certificate Generation.
       (No installation is required. The script will handles this)
  * Unique (per run) Trust Anchor Certificate.
  * One common CA root certificate for the modes that requires a Trust Anchor Certificate:
    - SSLsplit.
    - Mitmproxy.
    - Honeyproxy.
    - Squid in the Middle.
  * Multiple formats of the CA certificate for all kind of clients:
    - IOS. (not tested)
    - IOS Simulator. (not tested)
    - Firefox. (tested)
    - Java. (not tested)
    - OSX. (not tested)
    - *nix systems. (tested)
    - Windows platforms. (tested)
    - Android 4.x devices. (tested)		
  * Backup of the generated CA-certificates. (Just in case).
  * Stop/kill of any running processes when we re-run the script.
  * Ability to use any wireless NIC for the creation of the SoftAP. (In case that more than one is installed)
  * Auto-detect of Internet interface.
  * Auto-detect of Wireless interface(s).
  * Auto-detect of Wireless interface in monitor mode.
  * Auto-detect of Wireless interface's capabilities :
    - Access point mode. (hostapd compatible).
    - Monitor mode. (airbase-ng compatible).
    - Supported band :
      - IEEE 802.11a - 5GHz (airbase-ng or hostapd). (not tested).
      - IEEE 802.11g - 2.4 GHz (airbase-ng or hostapd). (tested).
      - IEEE 802.11a/n - 5GHz High Throughput (Only with hostapd). (not tested).
      - IEEE 802.11g/n - 2.4GHz High Throughput (Only with hostapd). (tested).
  * Ability to use Airbase-ng for the creation of the SoftAP. (Your wireless NIC MUST support monitor mode).
  * Ability to use Hostapd for the creation of the SoftAP. (Your wireless NIC MUST support AP mode).
  * Ability to set/change ESSID: Extended Service Set Identification.
  * Ability to set/change MAC address: Media Access Control Address.
  * Ability to set/change CRDA: Central Regulatory Domain Agent.
  * Ability to set/change channel :
    - Permitted to use channels are :
     - IEEE 802.11g - 802.11g/n: 01 02 03 04 05 06 07 08 09 10 11 12 13 (tested).
     - IEEE 802.11a - 802.11a/n: 36 40 44 48 52 56 60 64 (not tested).
    - Non permitted to uses channels are :
     - IEEE 802.11g - 802.11g/n: 14 (Japan) (tested).
     - IEEE 802.11a - 802.11a/n: 100 104 108 112 116 120 124 128 132 136 140 149 153 157 161 165 (not tested).
  * Informations about suggested channels to use for :
    - IEEE 802.11a   - 5GHz (not tested)
    - IEEE 802.11a/n - 5GHz 20Mhz channel width. (not tested).
    - IEEE 802.11a/n - 5GHz 40Mhz channel width. (not tested).
    - IEEE 802.11g   - 2.4GHz (tested).
    - IEEE 802.11g/n - 2.4GHz 20Mhz channel width. (tested).
    - IEEE 802.11g/n - 2.4GHz 40Mhz channel width. (tested).
  * Wireless card's IEEE 802.11n capabilities and auto-usage in hostapd : (only when hostapd is selected).
    - Available Antenna(s).
    - Configured Antenna(s).
    - Supported channel width set (20Mhz/40Mhz).
    - LDPC coding capability.
    - Spatial Multiplexing (SM) Power Save.
    - HT-Greenfield.
    - SGI-Short Guard Interval for 20 MHz.
    - SGI-Short Guard Interval for 40 MHz.
    - Tx STBC-Space–Time Block Codes.
    - Tx Max spatial streams.
    - Rx STBC-Space–Time Block Codes. (One, two or three Spatial streams.)
    - Maximum A-MSDU length.
    - DSSS/CCK Mode in 40 MHz.
    - HT TX/RX MCS rate indexes supported.
  * Ability to set/change Encryption :
    - For airbase-ng based SoftAP :
      - OPEN no encryption.
      - WEP (ASCII password 40bits or 104bits).
      - WEP (HEX password 40bits or 104bits).
    - For hostapd based SoftAP :
      - OPEN no encryption.
      - WEP (ASCII password 40bits or 104bits).
      - WEP (HEX password 40bits or 104bits).
      - WPA2 pre shared key. (8 to 32 characters long)
        - When WPA2 encryption is selected you will have the ability to:
          - enable/disable Wi-Fi protected setup (WPS).
          - set WPS pin.
  * Free Disk Space and free RAM Calculation for optimizing Squid3's functionality.
  * Ability to use alternative DNS servers. (I'm using OPEN DNS servers.)
  * Summary/information about Internet interface and the created SoftAP.
  * Kernel's Entropy Pool Calculation. We make sure that hostapd will not run out from random number. We use the Haveged algorithm.
  * Real time reports about who, what, when was visited by our WLAN.
  * Detailed reports about who, what, when top sites, top sites/users etc was visited by our WLAN.
  * Informations about which daemons/programs are running and which and where the configuration files are used.
  * Log files for almost all the modes.
  * Specially for mode 10 due to a massive number of log files a search script will be created (search.sh) to help do search queries into the sslsplit's log files.
  * Real time information about connected clients, SoftAP's statistic informations and leases granted by udhcp server (offered IPs to our clients).

Fourteen Access Point modes :
================

    1.  Simple WLAN - Clients can access Internet.
    ----------------------------------------------
        Aerial will act as an Access Point. No interception, no nothing.
        Mode's folder name:none
    
    2.  Transparent HTTP Proxied WLAN Optimized for low Internet Speeds RTR*
    ------------------------------------------------------------------------
        When low Internet speed is the case, this mode might be founded useful.
        We are trying to achieve high "HIT" rates with Squid3 and in some case we 
        violating http regulations. We keep cached files longer then it should be.
        Of course this mode can be used as an http proxied WLAN.
        This is the only not that we cache file into our disk (HDD/SDD).
        Mode's folder name:none - Suid3's log : /var/log/squid3

    3.  Airchat - Wireless Fun: Clients will chat with AP and each other.
    ---------------------------------------------------------------------
        Then client's of our WLAN they will forced to chat with our SoftAP and each other.
        They cannot access the Internet.
        Mode's folder name:none - Airchat's folder: /var/www/

    4.  TOR - Transparent anonymous Surfing - Deep Web access .onion sites.
    -----------------------------------------------------------------------
        The clients of our WLAN will Transparently, Anonymous surfing the web 
        through the TOR network and they can access .onion sites. DNS queries will
        also passed through TOR. In this mode we also running ARM an relay monitor program.
        Mode's folder name:none.

    5.  I2P - Manual anonymous Surfing - Deep Web access .i2p sites
    ---------------------------------------------------------------
        The clients of our WLAN will Manual, Anonymously* surfing the web and they can 
        access .i2p sites through i2p network. This is the only NON transparent mode. You
        have to manually set your client's browser to use our http and https proxy that is
        running into the Kali box. DNS requests will pass also through our Linux box and as
        such we might have DNS leaks. Finally please have in mind that i2p network is extremely
        slow. Sometimes you have to let it run for an hour or more to be able to visit some pages.
        Mode's folder name:none.
         
    6.  MiTM - Transparent SSLstriped WLAN (Sslstrip).
    --------------------------------------------------
        The all known sslstrip. The clients of our WLAN will Transparently and "sslstripped"
        surfing the web. Limitations see "Known bugs" below.
        Mode's folder name: ../../Aerial/sslstrip/

    7.  MiTM - Transparent Proxied and SSLstriped WLAN (Squid3 <-> Sslstrip) RTR*
    -----------------------------------------------------------------------------
        Same as above but in this mode we cached transparently the visited pages with Squid3.
        Mode's folder name: ../../Aerial/sslstrip/

    8.  MiTM - Flip, Blur, Swirl, ASCII, Tourette client's browser images RTR*
    --------------------------------------------------------------------------
        Mode's folder name:none - Suid3's log : /var/log/squid3 and /var/www/images/

        8.1 Upside down images RTR*
        ---------------------------
        Your clients browser (http) images will be Upside Down.

        8.2 Blur images RTR*
        --------------------
        Your clients browser (http) images will be Blurred.

        8.3 Swirl images RTR*
        ---------------------
        Your clients browser (http) images will be Swirled.

        8.4 ASCII Images RTR*
        ---------------------
        Your clients browser (http) images will be converted into ASCII art.

        8.5 Tourette Images RTR*
        ------------------------
        Your clients browser (http) images will be added by words.

    9.  MiTM - Forced downloading files RTR*
    ----------------------------------------
    Your clients will be forced to download our files. The clients will transparently HTTP 
    Proxied BUT they will be forced to download our test.(exe, zip, rar, doc, msi) when they
    asked to download ANY file from ANY HTTP site and that file matches the above extension, 
    *.exe *.zip *.rar *.doc *.msi. Then the script will rename our test.* to the original 
    filename and will serve it back to the client. Only http sites will get affected. This 
    mode has no affect to https sites.
    Mode's folder name: ../../Aerial/bad_files/

    10. MiTM - Transparent and scalable SSL/TLS intercepted WLAN (SSLsplit).
    ------------------------------------------------------------------------
    The clients of WLAN will surf our transparent and scalable SSL/TLS intercepted WLAN.
    The clients can surf the web and we Transparently sniffing:
    non-SSL traffic  : HTTP, WhatsApp and
    SSL-based traffic: HTTPS, SMTP over SSL and IMAP over SSL.
    SSLsplit is a generic transparent TLS/SSL proxy for performing man-in-the-middle attacks 
    on all kinds of secure communication protocols. Using SSLsplit, you can intercept and 
    save SSL-based traffic and thereby listen in on any secure connection.
    Mode's folder name: ../../Aerial/sslsplit/
    Search script     : ../../Aerial/sslsplit/search.sh

    11. MiTM - Transparent HTTP(S) intercepted WLAN (mitmproxy).
    ------------------------------------------------------------
    Almost same as the above. The clients of WLAN will surf our transparent 
    SSL/TLS intercepted WLAN. The main difference is that mitmproxy is an interactive 
    console program that allows traffic flows to be inspected and edited on the fly.
    Mode's folder name: ../../Aerial/mitmproxy/


    12. MiTM - Honey Proxy - Transparent HTTP(S) intercepted WLAN.
    --------------------------------------------------------------
    The same as the above. The clients of WLAN will surf our transparent SSL/TLS 
    intercepted WLAN. In this mode we get transparent HTTP(S) WLAN traffic investigating
    and analysis. HoneyProxy is a lightweight man-in-the-middle proxy that helps you
    analyze HTTP(S) traffic flows. It is tailored to the needs of security researchers 
    and allows both real-time and log analysis. It focuses on features that are useful
    in a forensic context and allows extended visualization capabilities.
    Mode's folder name: ../../Aerial/honeyproxy/					

    13. SiTM - Squid in The Middle - Transparent HTTP(S) proxied WLAN RTR*
    ----------------------------------------------------------------------
    The clients of our WLAN they will be transparent http and https proxied.
    Mode's folder name:none - Suid3's log : /var/log/squid3.
    Dynamically generated certificates folder: /var/lib/ssl_db/

    14. JiTM - JavaScript in The Middle - Java Code Inject RTR*"
    ----------------------------------------------------------------------
    Squid will inject each JavaScript file passing through the proxy.
    You can inject:
         1. A simple script that inject an annoying alert with a message.
         2. A script that captures the submitted form content without being noticed by the user.
            (submitted form must be in Java and it's not working quite well).
         3. Your own Java Script.
    Mode's folder name: ../../Aerial/Java_Inject/

    (*RTR: Real Time Reports with SARG.)


(1) Disable bss neighbor check/force 40 MHz channels patch.
===========================================================

  By default Hostapd does a check for overlapping channels with neighboring bss's 
  before enabling 40 MHz channels as proposed by IEEE 802.11(a/g)n. This however might
  result in switching to 20 MHz channels in dense wlan areas:
  
    hostapd -d /etc/hostapd/hostapd.conf
    40 MHz affected channel range: [2407,2457] MHz
    Neighboring BSS: 00:19:xx:xx:xx:xx freq=2412 pri=0 sec=0
    Neighboring BSS: 9c:c7:xx:xx:xx:xx freq=2412 pri=1 sec=0
    Neighboring BSS: 88:25:xx:xx:xx:xx freq=2412 pri=1 sec=5
    40 MHz pri/sec mismatch with BSS 88:25:xx:xx:xx:xx <2412,2432> (chan=1+) vs. <2442,2422>
    20/40 MHz operation not permitted on channel pri=7 sec=3 based on overlapping BSSes
  
  As a matter of fact hostapd acts as the regulations required, but most manufactures does 
  not perform that check and they broadcast with 40Mhz channels width no matter what.
  With this patch we let hostapd do that check but the results are ignored and we forcing
  hostapd to use 40Mhz channel width.
  
  A working/forced example of 40MHz channel width :
  
    hostapd -d /etc/hostapd/hostapd.conf
    40 MHz affected channel range: [2407,2457] MHz
    Neighboring BSS: 00:19:xx:xx:xx:xx freq=2412 pri=0 sec=0
    Neighboring BSS: 9c:c7:xx:xx:xx:xx freq=2412 pri=1 sec=0
    Neighboring BSS: 88:25:xx:xx:xx:xx freq=2412 pri=1 sec=5
    40 MHz pri/sec mismatch with BSS 88:25:xx:xx:xx:xx <2412,2432> (chan=1+) vs. <2442,2422>
    20/40 MHz operation not permitted on channel pri=7 sec=3 based on overlapping BSSes
    DFS 0 channels required radar detection
    nl80211: Set freq 2442 (ht_enabled=1, vht_enabled=0, bandwidth=40 MHz, cf1=2422 MHz, cf2=0 MHz)
    HT40: control channel: 7  secondary channel: 3
    Completing interface initialization

 * http://patchwork.ozlabs.org/patch/144477/
 * http://www.smallnetbuilder.com/wireless/wireless-features/31744-bye-bye-40-mhz-mode-in-24-ghz-part-2
 * http://www.brunsware.de/blog/gentoo/hostapd-40mhz-disable-neighbor-check.html

Known bugs
==========

  * By default the script will install Squid3 v3.1.20 from Kali repos. When mode 13 (Squid in the middle) is selected you will be prompted to uninstall Squid3 3.1.20 and install Squid3 v3.3.8 with SSL support. Squid3 3.1.20 and Squid3 3.3.8 they cannot co-exist. They are incompatible. Unfortunately when Squid3 3.3.8 installed mode 8 (Flip, Blur, Swirl etc) and sub-menu for mode 8 will be dead. I couldn't find a way to make g0tmilk's scripts to work with Squid3 3.3.8. So, you will be prompt again to uninstall Squid3 3.3.8 and install again Squid3 3.1.20. If you have an idea how make g0tmilk's scripts to work with Squid3 3.3.8 please let know. It's very annoying this install/uninstall process.
  * In modes 6 & 7 where sslstrip is used it's very common to encouraged corrupt or broken https sites. This has nothing to do with the script. Sslstrip doesn't works if :
    - The client requests an address with HTTPS directly, e.g. HTTPS://www.example.com
    - The web site have the support for HSTS, that forces a browser to solely 
      interact with the server using HTTPS.
    - The client is a smart-phone AND the user use an app (app like gmail, facebook etc. works only with HTTPS).

* https://forums.kali.org/showthread.php?17926-Fake-access-point-ettercap-sslstrip&p=29220&viewfull=1#post29220
* http://blog.csnc.ch/tag/sslstrip/
* http://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security

Credits to repzeroworld (Kali Forums) for clarifying me how sslstrip works.

Tested
======

  - Script running on:
    - Kali Linux 1.0.6 (x32 x64).
    - Kali Linux 1.0.7 (x32 x64).
    - Kali Linux 1.0.8 (x32 x64).
    - Kali Linux 1.0.9 (x32 x64).
    - BackTrack 5R3 (x32 x64) some modes are working.
  - Wireless NICs:
    - rt2800 pci-e - AP and monitor mode supported.
    - rt2800 usb - AP and monitor mode supported.
    - ath5k pci - AP and monitor mode supported.
    - zd1211rw usb - AP and monitor mode supported.
  - Clients:
    - Kali Linux 1.0.x (x32 x64).
    - Windows 8.0 32bit.
    - Windows 8.0 64bit.
    - Windows 8.1 64bit.
    - Android 4.x devices.

The Latest Version
==================

  Details of the latest version can be found on the Kali forums and here at github :
* <a href="https://forums.kali.org/showthread.php?23028-Aerial-Multi-mode-wireless-LAN-Based-on-a-Software-Access-point">Aerial Multi mode wireless LAN Based on a Software Access point/</a>

Documentation
=============

  No documentation available yet. Only this README file.

Licensing
=========

  Please see the file called COPYING.

Credits
=========

To my mentor: Gitsnik
For their replies: zimmaro dataghost

Contacts
========

  You can contact me at :
* <a href="https://forums.kali.org/member.php?24689-Nick_the_Greek">Nick_the_Greek - Kali Forums/</a>

(c) 2014 Nick_the_Greek
