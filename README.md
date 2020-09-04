# git-storyid

Helps to attach [Pivotal Tracker](https://www.pivotaltracker.com/) story id to git commit.

## Installation

``` sh
gem install git-storyid
```

## Usage

``` sh
git storyid -m "Initial implementation of campaign tags"
# Api token (https://www.pivotaltracker.com/profile): a56f0e9a4fbXXXXXXXXXXXXXX
# Use SSL (y/n): y
# Your pivotal initials (e.g. BG): BG
# Project ID: 494XXX
```

Interactive menu to select an ID of **Started stories**

```
[1] Removing Billing Page
[2] Welcome Email
[3] Email Shares -  Capture
[4] Speed up activities by dates aggregation
[5] Mass Email to Customer List - thurs AM
[6] Investigate production error
[7] Tag campaign insertion points and campaigns with an identifier

Indexes(csv): 7
[campaign-tags 3020407]  [#44116647] Initial implementation of campaign tags
 1 file changed, 1 insertion(+), 2 deletions(-)
```

Result commit:

```
commit 3020407e92cb125083cf50ad494ff15169a7f2e6
Author: Bogdan Gusiev <agresso@gmail.com>
Date:   Fri Mar 15 12:42:32 2013 +0200

[#44116647] Initial implementation of campaign tags

Feature: Tag campaign insertion points and 
campaigns with an identifier, 
so only campaigns with matching identifier will get shown
```

## Supported options

```
-m, --message [MESSAGE]          Add addional MESSAGE to comit
-f, --finish                     Specify that this commit finishes a story or fixes a bug
-d, --deliver                    Specify that this commit delivers a story or a bug
```
