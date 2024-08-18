---
title: "Understanding Cronjob Self-Deletion: Behavior and Implications When Restarting Cron Service on OpenWRT"
description: "This article explores whether a cronjob can finish its execution after removing itself from the crontab and restarting the cron service, using a practical test on OpenWRT version 23.05.3."
date: 2024-08-18T01:58:40.873Z
draft: false
tags: [openwrt, cronjob]
categories: [Computers, Linux]
thumbnail: "/article/openwrt-understanding-cronjob-self-deletion/thumb.png"
---

### Intro

The article addresses the question: Will a cronjob complete its run if it removes itself from the crontab and restarts the cron service? We conducted tests on OpenWRT version 23.05.3 240325 to find out.

### Test

To answer this question, we wrote a short Perl script, `b.pl`:

```perl
#!/usr/bin/perl

print "Start\n";
`sed -i /b.pl/d /etc/crontabs/root`;
print "Removed crontab entry\n";
`service cron restart`;
print "Restarted cron service\n";
sleep(10);
print "Slept 10 sec and now exiting\n";
```

We added the following crontab entry using `crontab -e`:

```text
* * * * * /root/b.pl > b.log
```

The cronjob is set to run every minute. When it runs for the first time, it prints "Start," then removes its own entry from the crontab using `sed`, printing "Removed crontab entry" afterward. It then restarts the cron service and prints "Restarted cron service," followed by sleeping for 10 seconds and printing "Slept 10 sec and now exiting." All these outputs are logged to the `b.log` file.

If removing the entry from the crontab terminates the cronjob, we would not see the "Removed crontab entry" message in the log. If restarting the cron service causes the cronjob to terminate, we would not see the "Restarted cron service" message, nor the final message, "Slept 10 sec and now exiting."

We tested it, and here is the content of the log:

```bash
cat b.log 
Start
Removed crontab entry
Restarted cron service
Slept 10 sec and now exiting
```

Since all the output is present, this means the cronjob was allowed to finish its run.

We also confirmed that the crontab is empty.

### Conclusion

Our experiment demonstrates that a cronjob can successfully complete its execution even after removing itself from the crontab and restarting the cron service. The output from our test script clearly shows that all the expected steps were completed without interruption, including the removal of the crontab entry and the restart of the cron service. This indicates that the cron daemon allows a job to finish its current execution before terminating it, even if the job modifies the crontab or restarts the service. 

For system administrators and developers working with cronjobs, this behavior is essential to understand, especially when designing scripts that involve self-removal or service restarts. The results provide confidence that such cronjobs can be designed without worrying about premature termination, ensuring that all critical tasks within the job are completed as intended.