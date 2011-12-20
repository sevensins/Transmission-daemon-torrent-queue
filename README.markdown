<p>
This script is intended to queue torrents in <a href="http://www.transmissionbt.com" target="_blank">Transmission Bittorrent client</a> which is running in daemon mode.
</p>
<br />
<strong>What you need to do:</strong><br>
Replace the following variables :
<ol>
<li><strong>USERNAME</strong> : The default username for transmission-remote is transmission</li>
<li><strong>PASSWORD</strong> : The default password for transmission-remote is transmission</li>
<li><strong>MAXDOWN</strong> : This is the maximum number of torrents that you would like to have in queue for downloading</li>
<li><strong>MAXACTIVE</strong> : This is the maximum number of active torrents in your list.</li>
</ol>
<br />
Save the script to a suitable location and use cron to schedule it to run every 5 minutes or whatever time you deem suitable and enjoy your Transmission.