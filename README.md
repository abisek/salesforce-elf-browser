# Event Log File Browser

A Salesforce connected web app to access and download Event Log Files. **Access it on [Heroku](https://salesforce-elf.herokuapp.com/).**

## Overview

[Salesforce event log file](https://www.salesforce.com/us/developer/docs/api_rest/Content/using_resources_event_log_files.htm) is a file-based API to get your Salesforce organization's application log data. These files provide visibility into your org for security auditing, application performance, and feature adoption. 

Event log file browser is a Salesforce connected app built with Ruby on Rails to help you access and download event log files. The downloads are streamed to the web client via the Rails application using Rail's `ActionController::Streaming`.

## Hosting your own instance of Salesforce Event Log File Browser

### Heroku
[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

### Other platforms
Follow these steps if you wish to host your own instance of the application on any Rails hosting platform.

#### Create Salesforce consumer key and secret
This step can be performed from any Salesforce organization.

1. Navigate to **Setup > Create > Apps > Connected Apps > New**
2. In the **New Connected App** page, check **Enable OAuth Settings**.
3. Enter the callback URL. For localhost, use `http://localhost:3000/auth/salesforce/callback`. If it's hosted, use `https://<your domain>/auth/salesforce/callback`. If you do not use SSL, you must set `config.forcessl = false` in **config/environments/production.rb**
4. Add **Access and manage your data (api)** to the **Selected OAuth Scopes**.
5. Fill out the remaining required fields and click **Save**.
6. Once you save, you'll be taken to a page that has the consumer key and consumer secret.
7. Repeat steps 1-6 for sandbox instance with a slight change in step 3 -- replace `.../auth/salesforce/callback` with `.../auth/salesforcesandbox/callback`
8. Note your consumer key and secret and for both production and sandbox instances.

#### Configure and start Rails or Docker
Configure the following environment variables.

1. `SALESFORCE_ELF_CONSUMER_KEY`: (required) Salesforce consumer key for production from previous section.
2. `SALESFORCE_ELF_CONSUMER_SECRET`: (required) Salesforce consumer secret for production from previous section.
3. `SALESFORCE_ELF_SANDBOX_CONSUMER_KEY`: (required) Salesforce consumer key for sandbox from previous section.
4. `SALESFORCE_ELF_SANDBOX_CONSUMER_SECRET`: (required) Salesforce consumer secret for sandbox from previous section.
5. `SECRET_KEY_BASE`: (required) Secret key for encryption that you can generate using `rake secret`. Rotate the keys periodically.
6. `ELF_MAX_DOWNLOAD_FILE_SIZE_IN_BYTES`: (optional) The maximum size of file allowed via streaming download. Default is 5_000_000 (~5MB).
7. `ELF_GOOGLE_ANALYTICS_TRACKING_ID`: (optional) For Google Analytics tracking.

If using Rails, once the environment variables are setup, you can start the application using `rails server` or `foreman start`.

If using Docker, the environment variables can be added to a `.env` file or passed through to the container and started with `docker-compose up`

## Issues
Report bugs and issues [here](https://github.com/abisek/salesforce-elf-browser/issues).

## ELF Browser Security
The ELF browser is a stateless application running on Heroku, an official Salesforce property which is using https. The Salesforce browser is always deployed from code which is checked into the public open source repository, allowing anybody to audit to security of the applications code. At this time, the only people who have commit privileges which allow merging of pull requests to the open source repository are official Salesforce employees. The only people that can deploy the ELF browser are official Salesforce employees.

The ELF browser application doesn’t store any customer data including logins or oauth credentials. The application does use Google Analytics for tracking application user metrics such as browser types, and locations.

The ELF browser uses oauth for the login flow which is done through Salesforce, so when the user logs in they are using an official Salesforce login. When a user first authorizes the Salesforce browser to do operations (query and retrieve event log files) on the users behalf a connected app is installed in the users org and can be uninstalled or locked down by the orgs administrator. The org that contains the connected app is also maintained by an official Salesforce employee.

We maintain a secret key within the Heroku deployment which is rotated periodically, which allows us to invalidate all logins and reinitiating the login flow again.

Log data is not stored in Heroku. The only data which is stored are generic user metrics via Google Analytics. All logins and authorizations are done through Salesforce allowing the user full control of the authorizations so it’s no different as far as security is concerned, than logging into the official Salesforce front pages (https://login.salesforce.com for production or https://test.salesforce.com for sandbox). The app can also be deployed by a customer using the instructions at https://github.com/abisek/salesforce-elf-browser in their own Heroku instance and utilizing their own Developer Edition org to deploy a connected app in which to control oauth scopes.

## Safe Harbor
Safe harbor, the Salesforce ELF browser is not an official Salesforce product we make no guarantees on the safety, security, or maintenance of the project or the deployed app and customers should not base their purchasing decision on the current feature set or future roadmap of this application.

## Contributors
(Listed in no particular order)

* [Abhishek Sreenivasa](https://github.com/abisek) - developer and maintainer
* [Adam Torman](https://github.com/atorman) - QA and product management
* Soumen Bandyopadhyay - QA
* Ivan Weiss - QA
* Justine Heritage - documentation
* Aakash Pradeep - QA


