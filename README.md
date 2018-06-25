Wordpress to static s3/cloudfront

This script requires the HTTrack be installed prior to execution. https://www.httrack.com/
You will also need to have AWS-CLI installed as well. https://aws.amazon.com/cli/

You will need to make sure you have ample space as this clones the site. 

This script will take a single site from Wordpress Multisite, scrape it, flatten it, while preserving link structure and push the flattened site to AWS S3 to be served by cloudfront. You can edit the variables to work with with a standard Wordpress install as well. 

You will need to add a profile to the local machine so AWS-CLI can communicate securly to AWS. First you will need to su root and run "aws configure --profile "profil-name" ". 

It's pretty simple and straightforward except for when it's not. 