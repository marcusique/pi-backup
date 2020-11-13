#!/bin/bash

###################################
# Define Variables
###################################

# Elapsed time
SECONDS=0

# Storage device as defined in your /etc/fstab.
MOUNTPOINT="/media/TimeMachine"

# Path were the image of your SD card should be saved to
STORAGEPATH="/media/TimeMachine/pi-backup"

# Folder path for the most recent backup
MOSTRECENTPATH="/media/TimeMachine/pi-backup/recent"

# Image name
IMAGENAME="pi-copy"

# Log File location and name
LOGFILE="/var/log/pi-backup.log"

###################################
# Check Mount point Availability
###################################
echo $(date +%Y-%m-%d_%H-%M-%S) ">>>>>BACKUP STARTED<<<<<"

if [ "$(findmnt ${MOUNTPOINT})" ]; then
    echo $(date +%Y-%m-%d_%H-%M-%S) " - The backup drive is available on "$HOSTNAME >>${LOGFILE}
else
    echo $(date +%Y-%m-%d_%H-%M-%S) " - Error: mount point was not available, please mount your device as defined in /etc/fstab" >>${LOGFILE}

    #This command mounts all storages defined in /etc/fstab
    mount -a

    if [ $? != 0 ]; then
        echo $(date +%Y-%m-%d_%H-%M-%S) " - The backup drive mounted on "${MOUNTPOINT} >>${LOGFILE}
        sleep 5
        mount -a
        if [ $? != 0 ]; then
            echo $(date +%Y-%m-%d_%H-%M-%S) " - Error: the backup drive was not mounted. Please check it manually" >>${LOGFILE}
            exit
        fi
    fi
fi

##################################################################
# Remove old Images from Storage Device
##################################################################

echo $(date +%Y-%m-%d_%H-%M-%S) " - Starting to delete files older than 7 days in ${STORAGEPATH}" >>${LOGFILE}

# Remove files older than 7 days
find ${STORAGEPATH}/*.* -mtime +7 -exec rm -r {} \;

if [ $? != 0 ]; then
    echo $(date +%Y-%m-%d_%H-%M-%S) " - Old images successfully removed" >>${LOGFILE}
    if [ $? != 0 ]; then
        echo $(date +%Y-%m-%d_%H-%M-%S) " - Error: was not able to delete old image files in ${STORAGEPATH}. Please check manually" >>${LOGFILE}
        break
    fi
fi

###################################
# Clone SD Card Image
###################################

echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to clone pi image to "${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img >>${LOGFILE}

# Saves a plain img file
sudo dd if=/dev/mmcblk0 of=${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img bs=8MB

echo $(date +%Y-%m-%d_%H-%M-%S) " - Finished to clone image to "${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img >>${LOGFILE}

###################################
# Resize dd Image
###################################
# Resize image with pishrink
# Please see https://github.com/Drewsif/PiShrink for further details
# pishrink.sh must be located in the same directory as this script!

echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to compress the image to "${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img >>${LOGFILE}
sudo /bin/bash /usr/local/bin/pishrink.sh -d ${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img ${STORAGEPATH}/${IMAGENAME}_$(date +%Y-%m-%d)-compressed.img
echo $(date +%Y-%m-%d_%H-%M-%S) " - Finished compressing the image to "${STORAGEPATH}/${IMAGENAME}_$(date +%Y-%m-%d)-compressed.img >>${LOGFILE}

#Delete big image file
echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to delete the original image "${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img >>${LOGFILE}
sudo rm ${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img
echo $(date +%Y-%m-%d_%H-%M-%S) " - Deleted the original image "${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img >>${LOGFILE}

###################################
# Move the backup to the recent folder
###################################

#Remove files from recent folder
echo $(date +%Y-%m-%d_%H-%M-%S) " - Purging the recent folder "${MOSTRECENTPATH} >>${LOGFILE}
find ${MOSTRECENTPATH}/*.img -exec rm -r {} \;
echo $(date +%Y-%m-%d_%H-%M-%S) " - The recent folder has been purged "${MOSTRECENTPATH} >>${LOGFILE}

#Move the backup to the recent folder
echo $(date +%Y-%m-%d_%H-%M-%S) " - Moving backup to "${MOSTRECENTPATH}/${IMAGENAME}-recent.img >>${LOGFILE}
sudo mv ${STORAGEPATH}/${IMAGENAME}_$(date +%Y-%m-%d)-compressed.img ${MOSTRECENTPATH}/${IMAGENAME}-recent.img
echo $(date +%Y-%m-%d_%H-%M-%S) " - Backup has been moved to "${MOSTRECENTPATH}/${IMAGENAME}-recent.img >>${LOGFILE}

# Script finished
duration=$SECONDS
echo $(date +%Y-%m-%d_%H-%M-%S) " - Backup completed in ${duration} seconds" >>${LOGFILE}
echo $(date +%Y-%m-%d_%H-%M-%S) ">>>>>BACKUP FINISHED<<<<<"
