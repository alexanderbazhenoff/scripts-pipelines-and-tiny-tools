# innerVPS bridge

An example how to organize the network inside your VPS by linux bridge:

1. Create your loop device on VPS, e.g:

   ```text
   $ cat /etc/network/interfaces

   # The loopback network interface
   auto lo ens192
   iface lo inet loopback
   ```

2. Copy [innerbridge.sh](innerbridge.sh) to `/opt` folder.
3. Add to your network configuration something like `post-up /opt/innerbridge.sh`.
