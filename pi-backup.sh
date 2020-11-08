#!/bin/bash

###################################
# Define Variables
###################################

# Storage device as defined in your /etc/fstab.
mountpoint='/media/TimeMachine'

# Path were the image of your SD card should be saved to
STORAGEPATH="/media/TimeMachine/pi-backup"

# Image name
IMAGENAME="pi-copy"

#Log File location and name
LOGFILE="/var/log/pi-backup.log"

###################################
# MOUNTPOINT Section - Check Mount point Availability
###################################

if [ "$(findmnt ${mountpoint})" ] ;
    then
        echo $(date +%Y-%m-%d_%H-%M-%S) " - The backup drive is accessible on "$HOSTNAME >> ${LOGFILE}
    else
        echo $(date +%Y-%m-%d_%H-%M-%S) " - Mount point was not accessible, please mind your device as defined in /etc/fstab" >> ${LOGFILE}

    #This command mounts all storages defined in /etc/fstab
    mount -a
 
    if [ $? != 0 ]
        then
            echo $(date +%Y-%m-%d_%H-%M-%S) " - The backup drive mounted" >> ${LOGFILE}
        sleep 5
            mount -a
        if [ $? != 0 ]
        then
            echo $(date +%Y-%m-%d_%H-%M-%S) " - Backup failed! The backup drive was not mounted. Please check it manually" >> ${LOGFILE}
            #echo "Sent backup status via e-mail" | mutt ${EMAIL} -a ${LOGFILE} -s $HOSTNAME" - Backup FAILED" >> ${LOGFILE}
        exit
        fi
    fi
fi

##################################################################
# DELETION Section - Remove old Images from Storage Device
##################################################################

echo $(date +%Y-%m-%d_%H-%M-%S) " - Starting to delete files older than defined time (3 days)" >> ${LOGFILE}

# Uncomment if the files should be identified by days, file > 32 days than it gets deleted
find ${STORAGEPATH}/*.* -mtime +3 -exec rm -r {} \;

# Uncomment if you would like to use minutes file > 10080 minutes than it gets deleted
#find ${STORAGEPATH}/*.* -type f -mmin +43200 -exec rm {} \;

if [ $? != 0 ]
    then
        echo $(date +%Y-%m-%d_%H-%M-%S) " - Old images successfully removed" >> ${LOGFILE}
     if [ $? != 0 ]
     then
        echo $(date +%Y-%m-%d_%H-%M-%S) " - Was not able to delete old image files. You have to check it manually" >> ${LOGFILE}
    break
    fi
fi
 
###################################
# CLONE Section - Clone SD Card Image
###################################
# This line creates a full copy of the SD card and writes it as an image file to the defined patch
 
echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to clone pi image" >> ${LOGFILE}
 
# Saves a plain img file on your storage device
sudo dd if=/dev/mmcblk0 of=${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img bs=8MB
 
echo $(date +%Y-%m-%d_%H-%M-%S) " - Finished to clone image" >> ${LOGFILE}

###################################
# Resize dd Image
###################################
# Resize image with pishrink
# Please see https://github.com/Drewsif/PiShrink for further details
# pishrink.sh must be located in the same directory as this script!
 
echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to compress the image" >> ${LOGFILE}
sudo /bin/bash /usr/local/bin/pishrink.sh -d ${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img ${STORAGEPATH}/${IMAGENAME}_$(date +%Y-%m-%d)-compressed.img
echo $(date +%Y-%m-%d_%H-%M-%S) " - Finished compressing the image" >> ${LOGFILE}

#Delete big image file
echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to delete the original image" >> ${LOGFILE}
sudo rm ${STORAGEPATH}/${IMAGENAME}-$(date +%Y-%m-%d).img
echo $(date +%Y-%m-%d_%H-%M-%S) " - Deleted the original image" >> ${LOGFILE}
 
# Creates a compressed file of the resized image
# This command will create a compressed gz archive of the small image file.
# The small file will get deleted during the process if you would like to keep
# the small image file use the command gzip -k ${STORAGEPATH}/${IMAGENAME}_$(date +%Y-%m-%d)-small.img
# Before you change the compression process check your disk space size
 
# echo $(date +%Y-%m-%d_%H-%M-%S) " - Started to compress small image" >> ${LOGFILE}
 
# gzip -q ${STORAGEPATH}/${IMAGENAME}_$(date +%Y-%m-%d)-small.img
 
# echo $(date +%Y-%m-%d_%H-%M-%S) " - Finished to compress small image" >> ${LOGFILE}
 
 
# if [ $? != 0 ]
#     then
#         echo $(date +%Y-%m-%d_%H-%M-%S) " - Image file created" >> ${LOGFILE}
#      if [ $? != 0 ]
#     then
#         echo $(date +%Y-%m-%d_%H-%M-%S) " - Was not able to create your image file. You have to check it manually." >> ${LOGFILE}
#     break
#     fi
# fi

# Script finished
echo $(date +%Y-%m-%d_%H-%M-%S) " - Mission Accomplished!!!" >> ${LOGFILE}