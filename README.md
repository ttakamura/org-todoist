# org-todoist

Sync TODOs between a emacs org-mode file and Todoist.

Todoist limit some APIs for only premium user, So you should have premium account.

## How it works

`org-todoist` sync your org-mode file and Todoist tasks by following steps.

1. Pull all Todoist tasks
2. Parse the org-mode file
3. Update Todoist tasks by org-mode tasks
  * Find a org-mode task by ID (in the PROPERTIES section)
  * Update the Todoist task by the org-mode task
4. Push changed tasks to Todoist
5. Export org-mode file

## Install gems

1. Install Ruby 2.0 or later
2. `gem install bundler`
3. Checkout this repository
4. `bundle install`

## Configuration

1. Find your API token from [your account page](https://todoist.com/Users/viewPrefs?page=account).
2. Write a configration file
  * `cp sample.env .env`
  * Edit `.env` file

## Backup

<strong>Please backup your org-mode files and Todoist project before sync.</strong>

* [Todoist backup](https://blog.todoist.com/2012/11/30/accidentally-delete-a-project-retrieve-it-from-a-backup/)

## Run

```
ruby ./sync.rb sample.org updated_sample.org
```
