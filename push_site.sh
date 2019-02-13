#!/bin/sh
#This script requires that httrack is installed prior to using. 
# Edit between these lines only --------------------------------
#Local Hub Information
#Fill in the necessary info
multisite_domain="site.example.com" #(used with multisite) Main URL of subdomain (New Location) ie. site.example.com, do not include the trailing folders.
wordpresss_root="htdocs" #Leave this blank if your wordpress root is in the root of the actual domain folder. ie. /www/url/*, If you have a seperate folder for root, ie. /www/site/htdocs/* than add the extra dir here. 
domain="new-example.com" #This is the final URL of the site ie. new-example.com no trailing subfolders.
site_id="34" #This is the multi-site ID in WordPRess.
workspace_folder="workspace/$sub_folder" #Does not need changed, will be created where script resides on server.
sub_folder="multisite_subfolder" #This is the sub_folder of the hub on the multisite, folder after the domain.
#Amazon S3 Information
s3_subfolder="" #This is the folder/sub_folder on s3 that it resdied in, leave empty qoutes if its the root (would be used if your using a subdomain of a url).
    # !!!Importatnt!!! Remove the --delete from the s3 push command for all top-level multi-site sites at the bottom of the script if there is no s3_subfolder.
s3_bucket="s3 Bucket" #This is the bucket that you are writing too on S3 (Can be a subdomain bucket too)
cloud_front_id="aabbccdd44556677" #This is the cloud_front ID if used
profile="local profile name" #This is the profile of the S3 account, will need to su root and run "aws configure --profile "profil-name" ".
#----------------------------------------------------------------
#Begin Template "NO EDITING BELOW LINE" -----------------------
echo "Scraping $sub_folder to make a usable site"
httrack "http://$multisite_domain/$sub_folder/"  "+*.$multisite_domain/$sub_folder/*" "-*.pinterest.com/*" "-*wlwmanifest*" "-*/wp-content/uploads/*" "-*xmlrpc*" "-*wp-json*" "-*Version*" "-*syndication*" "-*youtube*" "-*youtu.be*" "-*vimeo*" -O "sync/$sub_folder" -q
echo "Getting Images From $sub_folder Site"
mkdir -p /coke/uploads/$site_id
rsync -avz /www/$multisite_domain/$wordpresss_root/wp-content/uploads/sites/$site_id uploads 
echo "Creating Workspace For $sub_folder"
# Clear Working Folder
mkdir -p $workspace_folder/
rm -rfv $workspace_folder/*
mkdir -p $workspace_folder/wp-content/uploads/sites/$site_id
echo "Moving Files From $sub_folder Site To Workspace"
# SYNC FOLDER -- Copy contents of $domain To Working Folder
cp -r sync/$sub_folder/$multisite_domain/$sub_folder/* $workspace_folder/
# SYNC FOLDER -- Copy contents of clients.$domain/wp-contents to working folder wp-contents folder
#cp -r sync/clients.$domain/* $workspace_folder/
#Get From Sites Uploads Folder instead of downloading
cp -r uploads/$site_id/ $workspace_folder/wp-content/uploads/sites
wget "http://$multisite_domain/wp-includes/js/wp-emoji-release.min.js?ver=4.4.2" -O $workspace_folder/wp-includes/js/wp-emoji-release.min.js
#fix permissions
chmod -R 777 sync
chmod -R 777 workspace
echo "Fixing HTML Files to work relatively"
find $workspace_folder -name "*.DS_Store" -type f -delete
#find $workspace_folder -not -iname "index.html" -name "*.html" -type f
find $workspace_folder -not -iname "index.html" -name "index*.html" -type f -delete
find $workspace_folder -name "feed" -type d -print0|xargs -0 rm -r --
find $workspace_folder -name "comments" -type d -print0|xargs -0 rm -r --
# WORKING FOLDER - INDEX.HTML FILES - Find Replace references /clients.$domain/ to /
find $workspace_folder -type f -name '*.html' -exec sed -i -e "s|/$sub_folder/|/|g" {} +
find $workspace_folder -type f -name '*.html' -exec sed -i -e "s|$multisite_domain/$sub_folder||g" {} +
find $workspace_folder -type f -name '*.html' -exec sed -i -e "s|http://$multisite_domain||g" {} +
# WORKING FOLDER - INDEX.HTML FILES - Replace all references of index.html with empty
find $workspace_folder -type f -name '*.html' -exec sed -i -e "s|index.html||g" {} ++
##AMAZON SYNC
echo "Cleaning Up Amazon S3 $s3_bucket Bucket"    #Uncomment the 4 below for top level sites
#aws s3 rm s3://$s3_bucket/index.html --profile $profile
#aws s3 rm s3://$s3_bucket/wp-content --profile $profile --recursive
#aws s3 rm s3://$s3_bucket/wp-admin --profile $profile --recursive
#aws s3 rm s3://$s3_bucket/wp-includes --profile $profile --recursive
echo "Sending To Amazon S3 $s3_bucket Bucket"
aws s3 sync ./$workspace_folder s3://$s3_bucket/$s3_subfolder --profile $profile --acl public-read --delete #Comment out --delete for root sites
aws cloudfront create-invalidation --profile $profile --distribution-id $cloud_front_id --paths /*
echo "The Push for $sub_folder Has Finished!"
#End Template ------------------------------------