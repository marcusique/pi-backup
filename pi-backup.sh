#!/bin/bash

###################################
# Define Variables
###################################

# Storage device as defined in your /etc/fstab.
mountpoint='/media/TimeMachine'

# Path were the image of your SD card should be saved to
STORAGEPATH="/media/TimeMachine/pi-backup"

MOSTRECENTPATH="/media/TimeMachine/pi-backup/recent"

# Image name
IMAGENAME="pi-copy"

# Log File location and name
LOGFILE="/var/log/pi-backup.log"

###################################
# Check Mount point Availability
###################################

if [ "$(findmnt ${mountpoint})" ]; then
    echo $(date +%Y-%m-%d_%H-%M-%S) " - The backup drive is accessible on "$HOSTNAME >>${LOGFILE}
else
    echo $(date +%Y-%m-%d_%H-%M-%S) " - Mount point was not accessible, please mind your device as defined in /etc/fstab" >>${LOGFILE}

    #This command mounts all storages defined in /etc/fstab
    mount -a

    if [ $? != 0 ]; then
        echo $(date +%Y-%m-%d_%H-%M-%S) " - The backup drive mounted" >>${LOGFILE}
        sleep 5
        mount -a
        if [ $? != 0 ]; then
            echo $(date +%Y-%m-%d_%H-%M-%S) " - Backup failed! The backup drive was not mounted. Please check it manually" >>${LOGFILE}
            #echo "Sent backup status via e-mail" | mutt ${EMAIL} -a ${LOGFILE} -s $HOSTNAME" - Backup FAILED" >> ${LOGFILE}
            exit
        fi
    fi
fi

##################################################################
# Remove old Images from Storage Device
##################################################################

echo $(date +%Y-%m-%d_%H-%M-%S) " - Starting to delete files older than 7 days" >>${LOGFILE}

# Remove files older than 7 days
find ${STORAGEPATH}/*.* -mtime +7 -exec rm -r {} \;

if [ $? != 0 ]; then
    echo $(date +%Y-%m-%d_%H-%M-%S) " - Old images successfully removed" >>${LOGFILE}
    if [ $? != 0 ]; then
        echo $(date +%Y-%m-%d_%H-%M-%S) " - Was not able to delete old image files. You have to check it manually" >>${LOGFILE}
        break
    fi
fi

###################################
# Clone SD Card Image
###################################

echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to clone pi image" >>${LOGFILE}

# Saves a plain img file
sudo dd if=/dev/mmcblk0 of=${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img bs=8MB

echo $(date +%Y-%m-%d_%H-%M-%S) " - Finished to clone image" >>${LOGFILE}

###################################
# Resize dd Image
###################################
# Resize image with pishrink
# Please see https://github.com/Drewsif/PiShrink for further details
# pishrink.sh must be located in the same directory as this script!

echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to compress the image" >>${LOGFILE}
sudo /bin/bash /usr/local/bin/pishrink.sh -d ${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img ${STORAGEPATH}/${IMAGENAME}_$(date +%Y-%m-%d)-compressed.img
echo $(date +%Y-%m-%d_%H-%M-%S) " - Finished compressing the image" >>${LOGFILE}

#Delete big image file
echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to delete the original image" >>${LOGFILE}
sudo rm ${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img
echo $(date +%Y-%m-%d_%H-%M-%S) " - Deleted the original image" >>${LOGFILE}

###################################
# Move the backup to the recent folder
###################################

#Remove files from recent folder
echo $(date +%Y-%m-%d_%H-%M-%S) " - Purging the recent folder" >>${LOGFILE}
find ${MOSTRECENTPATH}/*.img -exec rm -r {} \;
echo $(date +%Y-%m-%d_%H-%M-%S) " - The recent folder has been purged" >>${LOGFILE}

#Move the backup to the recent folder
echo $(date +%Y-%m-%d_%H-%M-%S) " - Moving backup to the recent folder" >>${LOGFILE}
sudo mv ${STORAGEPATH}/${IMAGENAME}_$(date +%Y-%m-%d)-compressed.img ${MOSTRECENTPATH}/${IMAGENAME}-recent.img
echo $(date +%Y-%m-%d_%H-%M-%S) " - Backup has been moved to the recent folder" >>${LOGFILE}

# Script finished
echo $(date +%Y-%m-%d_%H-%M-%S) " - Backup successful" >>${LOGFILE}
