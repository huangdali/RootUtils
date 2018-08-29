#!/system/bin/sh

 busybox tar xf ./root.tar -C ./

 sleep 5

 mount -o remount,rw /system
 
 cp ./root/xbin/daemonsu /system/xbin/daemonsu
 cp ./root/xbin/su /system/xbin/su
 cp ./root/app/Superuser.apk /system/priv-app/Superuser.apk
 chmod 0644 /system/priv-app/Superuser.apk
 chmod 06755 /system/xbin/su
 chmod 0755 /system/xbin/daemonsu

 cp ./root/lib/libdummy.so /system/lib/
 
 if [ ! -f /system/etc/install-recovery.sh ]; then
 echo "install-recovery.sh is not exist,so copy it"
 cp -f ./root/install-recovery.sh /system/etc/
 chmod 777 /system/etc/install-recovery.sh
 else 
 	if grep -q "/system/xbin/daemonsu --auto-daemon &" /system/etc/install-recovery.sh
 		then
 		echo "install-recovery.sh  already run the su service"
 	else
 		echo "run the su service in install-recovery.sh"
 		sed -i '$a/system\/xbin\/daemonsu --auto-daemon &' /system/etc/install-recovery.sh
 	fi

 fi

 echo "root done,after 2s wiill reboot"
 rm -rf root
 sleep 2
 reboot


#add end
