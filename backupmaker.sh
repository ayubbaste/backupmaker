#!/bin/bash

# Launch from MAIN BACKUP FOLDER
timestamp=$(date +'%d-%m-%Y-%H-%M')
backup_files_num=5

printf "\n\nZiping all remote project folders with zip -9 ...\n\n"
# get every project folder name in the remote www dir and zip them
ssh user@your.ip.addr.here 'cd /way2/projects/folder && for dir in $(ls -d */ | sed "s#/##"); do zip "${dir%/}.zip" -9 -r "$dir" -x "*/env/*" "*.sock*"; done'
sleep 3


printf "\nStart downloading backups from remote server ...\n"
# detect all .zip files in remote www dir and download them
backup_files=$(ssh user@your.ip.addr.here 'find /way2/projects/folder -name "*.zip"')
for file in ${backup_files%/}; do scp user@your.ip.addr.here:"$file" . && sleep 3; done


printf "\nStart renaming backup files with timestamps and moving them to their folders ...\n"
# rename backup files with timestamps and move to their folders
# if there is no folder then create it
backup_files=$(find -maxdepth 1 -name "*.zip" | sed 's/^..//')
for file in ${backup_files%/}; do
  folder_name=$(echo "$file" | sed 's/....$//');
  if [[ -d "$folder_name" ]]
  then
    new_file_name="$folder_name-${timestamp}.zip";
    mv $file "$folder_name/$new_file_name";
  else
    mkdir "$folder_name";
    new_file_name="$folder_name-${timestamp}.zip";
    mv $file "$folder_name/$new_file_name";
  fi
done


printf "\nStart deleting all backup files from remote server ...\n"
# delete all .zip files in remote www dir
ssh user@your.ip.addr.here 'find /way2/projects/folder -maxdepth 1 -name "*.zip" -delete'


printf "\nStart removing old backup files from every backup folder ...\n"
# check every folder in main backup folder
# if there is more backup files then $backup_files_num
# delete the oldest one
for dir in $(ls -d */ | sed "s#/##"); do
cd $dir
files_count=$(ls | wc -l)
oldest_file=$(ls -1t | tail -1)
if (($files_count > $backup_files_num)); then
        rm $oldest_file
fi
cd ../
done

printf "\n* * *\nAll tasks complete.\n* * *\n"
