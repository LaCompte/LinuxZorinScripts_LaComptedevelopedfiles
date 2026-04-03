# LinuxZorinScripts_LaComptedevelopedfiles
La Compte scripts developed for the purpose of maintaining Linux maintenance and associated work.

# Files Uploaded
All are bash files based on the requirement of La Compte work on Zorin OS Core 17.3 towards ensuring NHSD, KKO and La Compte Files as well as Reach to be Heard Files are stored on the relevant accessible Onedrive. This Onedrive is hosted by La Compte for access to all four entities.

La Compte acknowledges that the scripts were developed with the assistance of Claude Pro using Sonnet 4.4. However, La Compte consistently checked the bash first first to ensure it was functional and was fulfilling requirements, and furthermore, to make improvements based on our requirements.

All uploaded bash files will be highlighted based on date of upload.

## Upload date: 3 April 2026
### classify_project_files.sh
This specific file is meant to allocate a logfile based on already uploaded materials on the onedrive, so that when the fresh "copy_to_onedrive_improved.sh" bash script is run, it does not reupload the same files twice. It is specifically scripted with the purpose of guiding on what the files are, where they belong in the Onedrive folders, and what type they are accordingly.
### copy_to_onedrive_improved.sh
This is a three part bash file. It first identifies the folders from which the files will be uploaded on to Onedrive. These files and folders are identified in terms of their filetype (for this, they are PDF, CDR, AI, DOCX, DOC, XLSX and so on) as well as their folder name (La Compte, Reach to be Heard, NHSD, KKO). The second part confirms whether the Onedrive token is validated and is working. Once this is activated, it then proceeds to upload all relevant files according to their folder classification and type. It concludes by sharing a log file which highlights what files were uploaded, how long it took, where they are stored, and what time it began and ended. This is also used by this script to ensure duplication is not undertaken during the process.
### log_previous_backup.sh
This is to generate a logfile. In the original version of "copy_to_onedrive.sh", there was no logfile which was uploaded and the files were simply uploaded in OneDrive into a single folder That was structured as "ZORINFILES_$(date)". This is fine if you want to simply use the Onedrive built in search function and thus are willing to let Onedrive undertake indexing in the background, but functionally it is not concerned with duplication because that was not considered. Essentially, this particular bash was simply confirming that the previous backups had happened and the files they contain are as under. This also prevented duplication and also ensured that the files were uploaded in their relevant folders, per the requirements, and were validated.
### rsync-resource-limited_2.sh
This is a sample script for being able to run rsync through prompts. It is an attempt to slightly automate the rsync process by simply selecting the files to be run via rsync for transfer. In the original script there were also variables for $CORES and $RAM so as to utilize systemd resource allocation for faster file transfers. However, this one is only focused on Source and Destination for the time being. Those can be edited to suit the requirements of bash script users. In my setting I have 16GB DDR3 1333MHZ RAM and I allocated 4 cores (I have a Core i7 4th Gen processor, but I found that 4 is a reasonable amount to use for the purpose of doing these rsync processes). 
