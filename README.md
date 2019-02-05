# Coldfusion Based dnsTools

This provides tools for bulk dns functions like digs as well as the ability to take AWS Route 53 exports and converts them to creates. Install 
Docker and run docker-compose file to launch container. Open a browser to http://localhost/ to access tools. 

**Note:** This application has not been hardened or vulnerability tested and is not intended for production use.

## Features 
- awsFormatter.cfm: Take AWS JSON Exports and Converts them per [AWS Route 53 rules](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-migrating.html#hosted-zones-migrating-edit-records) to allow creates. 
- digDug.cfm: Basic DNS tools.
  - Allows Bulk DNS Lookups against specific Name Servers
  - Allows for a "source" Name Server to compare entries
  - Allow for processing existing AWS Route 53 exports to run compares
- whoVille.cfm: Performs a Whois Lookup on a Domain or IP Address.
- dbParse.cfm: Parses a Bind output file to list contents.
  - This may not assume a standard Bind file. Was designed for unknown provided file.


### Folder Structure

**/srv**
- Custom configs for Lucee and Logs. Does NOT set admin password.
- Contains Dockerfile for Lucee build.

**/www**
- Source Files

**/www/assets**
- AWS JSON files (input/output).
- Contents in gitignore.


