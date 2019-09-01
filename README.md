# VSSAdmin Writers Utility

[Git Repo](https://github.com/nathancrjackson/ps-vss-writers-util)

If you manage backups for a lot of Windows Server installs, you will sometimes find yourself needing to run the following command:
```
VSSAdmin List Writers
```

It's helpful but it could be better. This script runs the command for you, parses the results and outputs:
- The same information as the command but with the writers sorted by name
- How long the command took to run
- A summary of the writers that did have issues

After the output you are given the options "Press r to rerun or any other key to exit"

This script has been tested on both Server 2008 and Server 2019 assuming everything in the middle just works.

##### Example summary
```
The following is a list of non-stable writers and their errors:

Writer name                    State                      Last error
-----------                    -----                      ----------
Dhcp Jet Writer                [10] Failed                Non-retryable error
DFS Replication service writer [10] Failed                Timed out
WMI Writer                     [5] Waiting for completion No error
```