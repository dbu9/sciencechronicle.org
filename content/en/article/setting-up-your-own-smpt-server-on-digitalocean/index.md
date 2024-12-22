---
title: "Setting up your own SMTP server on Digital Ocean"
description: "The article explains how to run your own SMPT server on Digital ocean with DKIM, SPF and DMARC, a full setup example is given step byt step."
date: 2024-09-06T01:44:20.758Z
draft: true
tags: [smtp, dkim, spf, dmark, rdns, ptr]
categories: [Linux]
thumbnail: "/news/setting-up-your-own-smtp-server-on-digital-ocean/thumb.png"
---

The main requirement for a working SMTP server is possibility to setup PTR record (reverse DNS, rDNS). Without the record, most SMTP servers cannot function properly, they will be bounced by other parties. 
DigitalOcean enables automatically setting of PTR record for any droplet whih runs which is a great feature. On Amazon EC, you should write to the support for enabling rDNS on aquired IP.

# Terms

DMARC, SPF, and DKIM are mechanisms used in the SMTP (Simple Mail Transfer Protocol) environment to improve email authentication, prevent email spoofing, and enhance deliverability. These technologies work together to ensure that legitimate emails are correctly authenticated and malicious emails are detected and blocked.

Here’s a breakdown of each:

## SPF (Sender Policy Framework)

### What is SPF?

SPF is an email authentication method that helps to prevent spammers from sending emails on behalf of your domain. It allows domain owners to specify which mail servers are authorized to send email on behalf of their domain by publishing a special DNS record (TXT record).

### How SPF Works

- The domain owner creates a DNS TXT record that lists the IP addresses or mail servers allowed to send email for the domain.
- When an email server receives a message, it checks the domain in the "MAIL FROM" header (envelope sender).
- The receiving mail server queries the DNS records for that domain and checks if the IP address of the sending server matches an IP authorized by the domain’s SPF record.
- If the IP address is listed, the email passes SPF; otherwise, it fails.

### SPF Record Example

```txt
v=spf1 ip4:192.168.1.1 include:mail.example.com -all
```

This record states:

- The server at IP `192.168.1.1` and any servers listed in `mail.example.com` are allowed to send mail on behalf of this domain.
- `-all` means that any other servers not listed should fail SPF validation.

### Limitations of SPF
- SPF checks the "envelope sender" during email delivery (which may differ from the visible "From" header), so it doesn't fully prevent all forms of email spoofing.
- SPF can break if emails are forwarded, as the forwarding server's IP may not be in the original sender’s SPF record.


## DKIM (DomainKeys Identified Mail)

### What is DKIM?

DKIM is an email authentication method that allows the sender to "sign" their emails with a cryptographic signature that can be verified by the recipient's email server. It ensures that the email content has not been altered in transit and that the email comes from the domain it claims to come from.

### How DKIM Works

- The sending mail server adds a **DKIM signature** to the email header, which is a hash of the message content (including the body and certain headers) encrypted with the sender’s private key.
- The public key is published as a DNS TXT record for the sending domain, typically under a subdomain like `selector._domainkey.example.com`.
- When the receiving server gets the email, it retrieves the public key from the sender's DNS and uses it to decrypt the DKIM signature.
- If the signature matches the email content, the email is considered authentic.

### DKIM Record Example

```txt
default._domainkey.example.com IN TXT "v=DKIM1; k=rsa; p=MIIBIjANBgkq...your_public_key..."
```

This record contains:
- `v=DKIM1`: Specifies DKIM version 1.
- `k=rsa`: Indicates that RSA is used for key encryption.
- `p=...`: The actual public key used for verification.

### Advantages of DKIM

- It verifies both the domain name and the integrity of the email content.
- Even if an email is forwarded, the DKIM signature remains valid (unlike SPF).

## DMARC (Domain-based Message Authentication, Reporting, and Conformance)

### What is DMARC?
DMARC builds on SPF and DKIM by providing a policy that tells receiving mail servers what to do if an email fails SPF or DKIM checks. It also provides a reporting mechanism so domain owners can see how their domain is being used in emails.

### How DMARC Works

- The domain owner publishes a DMARC policy as a DNS TXT record.
- When an email is received, the receiving mail server checks the DMARC policy of the sending domain.
- DMARC requires alignment of the "From" header (the visible sender) with the SPF and/or DKIM checks. This ensures that both the actual sending server and the message content match the domain in the "From" header.
- Depending on the DMARC policy, the receiving server will either:
  - **Do nothing** (p=none),
  - **Quarantine the email** (p=quarantine), or
  - **Reject the email** (p=reject) if SPF and DKIM checks fail.

DMARC also provides feedback reports to the domain owner about emails that failed validation.

### DMARC Record Example

```txt
_dmarc.example.com IN TXT "v=DMARC1; p=reject; rua=mailto:dmarc-reports@example.com"
```

This record means:

- `p=reject`: If the email fails both SPF and DKIM, it will be rejected.
- `rua=mailto:dmarc-reports@example.com`: DMARC aggregate reports will be sent to this email address.

### DMARC Policy Options

- **p=none**: Monitor mode (no action is taken even if SPF/DKIM fails, but reports are sent).
- **p=quarantine**: Messages that fail are treated suspiciously and are often placed in the spam/junk folder.
- **p=reject**: Messages that fail are rejected outright.

---

## Summary

- **SPF** ensures that the mail is sent from an authorized IP address but has limitations, particularly with forwarded emails.
- **DKIM** provides a cryptographic signature to verify that the email hasn't been tampered with and is from the stated domain.
- **DMARC** ties SPF and DKIM together, adding a policy for what to do when emails fail these checks and providing feedback to the domain owner.

Together, these mechanisms work to protect email users from phishing, spoofing, and fraud, while also improving the deliverability of legitimate emails. By using DMARC with both SPF and DKIM, you greatly enhance the security and trustworthiness of your domain's emails.

# A minimal setup: no DMARC, SPF, DKIM


## Install required software on the instance 

We assume our domain is `0x1.co` on IP `1.1.1.1`. 

We open a smallest droplet on digitalocean with Ubuntu 24.04 (LTS) 0x64, 1 GB RAM, 25 GB disk. The we install `postfix`, `mailutils`, `nettools` (for monitoring).

```bash
apt update -y
apt upgrade -y
apt install postfix -y
apt install mailutils -y
apt install net-tools
```

During postfix installation, several questions are asked. Just ignore them as we are going to setup its config files thereafter.

## Ensure PTR record exists for the instance

Let's check PTR record for our instance:

![ptrrecord](/article/setting-up-your-own-smtp-server-on-digitalocean/ptr.png)

## Set DNS records on your domain registrar

Our registrar is namecheap.com. We setup two dns records, `A` and `MX`. Record `A` assigns `mail.0x1.co` to the instance's IP, `1.1.1.1` and record `MX` says that all emails for domain `0x1.co` should go to `mail.0x1.co`.

![a-record](/article/setting-up-your-own-smtp-server-on-digitalocean/a-record.png)

![mx-record](/article/setting-up-your-own-smtp-server-on-digitalocean/mx-record.png)

## Setup postfix's main.cf

The following fields should be set:

```text
myhostname = mail.0x1.co
mydestination = $myhostname, 0x1.co, mailer, localhost.localdomain, localhost
```

By default for ubuntu 

```text
myorigin = /etc/mailname
```

We update this file with

```text
0x1.co
```

Restart postfix:

```bash
service postfix restart
```

## Testing

### Local email delivery

On Linux systems, email box coincides with user name. For example, user `root` will have email box named `root` and its content is in `/var/mail/root`. 

```bash
echo "Test email for root user" | mail -s "Test Mailbox" root
```

We can read the box by

```bash
cat /var/mail/root
```

or using `mail` command

```bash
mail 
```

The following commands can be used to print recieved messages:

```text
* n: to go to the next message.
* p: to print the current message.
* d: to delete the current message.
* q: to quit the mail client.
```

### Remote email delivery

Because we yet have not installed DMARC, SPF and DKIM, there is a high chance other smtp server will reject to accept email from our server. Therefore, we check email delivery with `https://www.mail-tester.com/`.

We send email to `test-n2k1n8ten@srv1.mail-tester.com` using 

```bash
echo "Test email from my Postfix server" | mail -s "Test Postfix" test-n2k1n8ten@srv1.mail-tester.com
```

and we get 5/10 score:

![score1](/article/setting-up-your-own-smtp-server-on-digitalocean/score1.png)

Additionally, we check our setup with `https://mxtoolbox.com/`:

![mxtoolbox](/article/setting-up-your-own-smtp-server-on-digitalocean/mxtoolbox.png)

# Extending the setup 

##  Sender Policy Framework (SPF)

SPF (Sender Policy Framework) ensures only authorized servers can send emails on behalf of your domain.

To configure SPF, you need to add a TXT record in your DNS settings for your domain. Here's a typical SPF record:

```text
v=spf1 mx a ip4:1.1.1.1 include:_spf.google.com -all
```

Adjust the include: directive based on whether you use any external services to send mail (e.g., Google, SendGrid). For example, 
if we don't want google:

```text
v=spf1 mx a ip4:1.1.1.1 -all
```

This record should be added for the root and mailer domains. In our case, we add

```text
v=spf1 mx a ip4:1.1.1.1 -all
```

for `0x1.co` **and** for `mail.0x1.co` domain.

In `/etc/postfix/mains.cf` we add 

```text
smtp_helo_name=$myhostname
```

where `$myhostname=mail.0x1.co`. 

This setting will prevent `SPF: HELO does not publish an SPF Record` error reported by mail-tester.


## Domain-based Message Authentication, Reporting, and Conformance (DMARC)

We need to add only the following DNS record to the domain registrar: 

```text
_dmarc.0x1.co   IN TXT   "v=DMARC1; p=reject; rua=mailto:dmarc-reports@0x1.co; ruf=mailto:dmarc-failures@0x1.co; fo=1"
```

## DKIM

```text
sudo apt install opendkim opendkim-tools
```

## Testing

```bash
echo "Welcome" | mail -a FROM:robert@0x1.co -s "Thanks for joining our team"  test-mjiuir6hd@srv1.mail-tester.com
```

Note: we use `-a` parameter to avoid postfix to set FROM to hostname's value `root@mail.0x1.co` 

