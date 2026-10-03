# Active Directory Home Lab: Setup Guide

Windows Server 2022 domain environment built on VMware Workstation Pro, with Windows 11 Enterprise domain-joined clients.

> Screenshots: search for `SCREENSHOT` in this file to find every place a screenshot still needs to be added.

## Table of Contents

0. [Requirements](#0-requirements)
1. [VMware Workstation Setup](#1-vmware-workstation-setup)
2. [Active Directory Setup](#2-active-directory-setup)
3. [Active Directory Users and Computers (OU)](#3-active-directory-users-and-computers-ou)
4. [Group Policy Management](#4-group-policy-management)
5. [Setting Up the Network](#5-setting-up-the-network)
6. [DHCP and DNS Configuration](#6-dhcp-and-dns-configuration) *(TODO)*
7. [File Sharing](#7-file-sharing)
8. [Security Policy](#8-security-policy)
9. [Service Accounts and Sysinternals](#9-service-accounts-and-sysinternals)
10. [Automation: Bulk User Creation](#10-automation-bulk-user-creation) *(TODO)*
11. [Problems and Resolutions](#problems-and-resolutions)

---

## 0. Requirements

| Purpose | Software |
|---|---|
| Hypervisor | [VMware Workstation Pro 26H1 for Windows (26H1u1)](https://knowledge.broadcom.com/external/article?articleNumber=368667) |
| Server (AD) | [Windows Server 2022 ISO](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022) |
| Guest users (client) | [Windows 11 Enterprise](https://info.microsoft.com/ww-landing-windows-11-enterprise.html) |

---

## 1. VMware Workstation Setup

1. Open VMware Workstation and click `Create a New Virtual Machine`.
   1. Select `Typical`.
   2. Select `I will install the operating system later`.
      > Selecting the ISO image at this step does not work properly (VMware triggers Easy Install), so attach it afterwards.
   3. Select `Microsoft Windows`, then Version = `Windows Server 2022`.
2. Open the VM's CD/DVD settings.
   1. Select `Use ISO image file`.
   2. Browse to the Windows Server 2022 ISO.
   3. Click `OK`.
3. Power on the virtual machine.
4. During installation, select `Windows Server 2022 Standard Evaluation (Desktop Experience)`.
5. Wait for the installation to complete.
6. Run `winver` from the search bar and confirm the version is `21H2`.

<!-- SCREENSHOT: VM hardware summary (CPU / RAM / disk / network adapter) -->
<!-- SCREENSHOT: winver output showing 21H2 -->

---

## 2. Active Directory Setup

1. Open `Server Manager`.
2. Click `Manage` (top right) -> `Add Roles and Features`.
3. On `Server Roles`, select:
   1. Active Directory Domain Services
   2. DHCP Server
   3. DNS Server
   4. File and Storage Services
   5. Remote Access
   6. Active Directory Certificate Services
      > Install AD CS **after** the server is promoted to a domain controller. Installing it first causes the promotion prerequisite check to fail. See [Problem 1](#problems-and-resolutions).
4. Click `Install`. Do **not** close the installation window.
5. When finished, click `Promote this server to a domain controller`.
   1. Select `Add a new forest`.
   2. Create the AD domain `[name].local`.
   3. Install.
6. After the restart, the logon page shows `domainName\Administrator`.

<!-- SCREENSHOT: Server Roles selection -->
<!-- SCREENSHOT: Domain controller promotion (Deployment Configuration) -->
<!-- SCREENSHOT: Logon page showing domainName\Administrator -->

---

## 3. Active Directory Users and Computers (OU)

Set up Organizational Units (OUs).

1. Open `Active Directory Users and Computers`.
2. Right-click `domainName.local` -> `New` -> `Organizational Unit`.
   - OUs can be nested inside other OUs.

<!-- SCREENSHOT: OU structure in ADUC -->

---

## 4. Group Policy Management

Create each GPO by right-clicking the domain and selecting `Create a GPO in this domain, and Link it here...`, then right-click the GPO -> `Edit`.

| GPO | Path |
|---|---|
| Password Policy | Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Account Policies -> Password Policy |
| Drive Mapping | User Configuration -> Preferences -> Windows Settings -> Drive Maps -> New -> Mapped Drive |
| Wallpaper Policy | User Configuration -> Policies -> Administrative Templates -> Desktop -> Desktop -> Desktop Wallpaper |
| Restrict Control Panel | User Configuration -> Policies -> Administrative Templates -> Control Panel -> Prohibit access to Control Panel and PC settings |
| Disable USB Storage | Computer Configuration -> Policies -> Administrative Templates -> System -> Removable Storage Access -> All Removable Storage classes: Deny all access |

<!-- SCREENSHOT: Group Policy Management console with GPO list -->

### Applying and Testing GPOs

1. Client OS must be Windows 10/11 Pro or Enterprise. This lab uses [Windows 11 Enterprise](https://info.microsoft.com/ww-landing-windows-11-enterprise.html).
   - Requirements: memory 4 GB or higher, disk space above 15 GB.
2. Set the client's DNS server to the Server's IP address.
   1. Verify connectivity: `ping [IP_address]`
   2. Verify name resolution: `nslookup [domainName].local`
3. Join the domain: `File Explorer` -> `This PC` -> `Properties` -> set Domain to `[domainName].local`.
   - Credentials: `administrator` and the domain password.
4. After the reboot, choose **Other user** and log in with a domain user.
5. On the server, drag the GPO from `Group Policy Objects` onto the target OU.
6. In `Active Directory Users and Computers`, move the client computer object into the corresponding OU.

<!-- SCREENSHOT: Successful domain join -->
<!-- SCREENSHOT: gpresult /r output on the client showing applied GPOs -->

---

## 5. Setting Up the Network

1. On the server, run `ipconfig` to find the current IP address, mask, and gateway.
2. Open `Control Panel`.
   > If blocked, see [Problem 2](#problems-and-resolutions).
3. Open `Ethernet0` -> `Properties`.
4. Select `Internet Protocol Version 4 (TCP/IPv4)`.
5. Select `Use the following IP address` and enter the IP address, subnet mask, and gateway from step 1.
6. DNS is configured in [Section 6](#6-dhcp-and-dns-configuration).

<!-- SCREENSHOT: Static IPv4 configuration -->

---

## 6. DHCP and DNS Configuration

> **TODO:** Not yet configured. The DHCP and DNS roles are installed, but scope and zone configuration is still pending.

### DHCP
<!-- TODO: authorize DHCP server in AD -->
<!-- TODO: create IPv4 scope (range, exclusions, lease duration) -->
<!-- TODO: scope options (003 Router, 006 DNS Servers, 015 DNS Domain Name) -->
<!-- TODO: reservation for one client by MAC address -->
<!-- TODO: verify on client (ipconfig /release, ipconfig /renew, ipconfig /all) -->
<!-- SCREENSHOT: DHCP scope and scope options -->
<!-- SCREENSHOT: Client lease visible in Address Leases -->

### DNS
<!-- TODO: confirm forward lookup zone and _msdcs records -->
<!-- TODO: create reverse lookup zone -->
<!-- TODO: configure forwarder -->
<!-- TODO: verify (nslookup, Resolve-DnsName, dcdiag /test:dns) -->
<!-- SCREENSHOT: DNS Manager zones and records -->

---

## 7. File Sharing

### Network Method

1. Create a folder in `C:\` named `jh.shared`.
2. Open the folder's `Properties`.
   1. `Sharing` tab -> `Advanced Sharing`.
   2. Check `Share this folder`.
   3. Click `Permissions` -> `Add` -> look up the domain group -> `Apply`.
3. Open the `Security` tab (NTFS permissions) and adjust permissions as needed.
4. On the client VM:
   1. Open `File Explorer`, right-click `Network` -> `Map network drive`.
   2. On the server, run `hostname` in CMD to find the host name.
   3. Enter the path `\\[hostname]\folder_name`.

> **Problem:** the mapped drive disappears after a reboot.

### Mapped Method (GPO Drive Maps)

Solves the persistence problem of the Network Method.

1. On the server, open `Group Policy Management`.
2. Create a new GPO.
   1. User Configuration -> Preferences -> Windows Settings -> Drive Maps.
   2. New -> Mapped Drive.
   3. Enter the path `\\[hostname]\folder_name`.
3. Drag the GPO onto the target OU.
4. The drive is now mapped at every logon, including after a reboot.

### File Server Resource Manager (FSRM)

1. Install:
   1. `Server Manager` -> `Manage` -> `Add Roles and Features`.
   2. `Server Roles` -> `File and Storage Services` -> `File and iSCSI Services` -> **File Server Resource Manager**.
2. Open `File Server Resource Manager`.
   1. **Quota Management** sets the maximum amount of data allowed -> `Create Quota`.
   2. **File Screen Management** controls which file types are allowed -> `Create File Screen`.

<!-- SCREENSHOT: Quota and file screen configured, plus a blocked-file test -->

### Inheritance

> Permissions set on a parent folder are automatically passed down to its subfolders and files. A permission granted on the parent is inherited exactly by its children.

1. In `Active Directory Users and Computers`, create a Project group with **Global** group scope.
2. Create a root folder `Common` in `C:\`, with two subfolders: `Project` and `Events`.
3. Right-click the root folder and give `Everyone` Full Control.
4. The permission is inherited by all subfolders.
   - Is it correct for everyone to see the `Project` folder? No. Fix it below.

#### Restricting the Project Folder

1. Open the `Project` folder's `Properties` -> `Security` -> `Advanced`.
2. Click `Disable inheritance`. Two options appear:
   - **Convert inherited permissions into explicit permissions**: stops inheriting from the parent; already-inherited permissions stay.
   - **Remove all inherited permissions**: stops inheriting and removes everything inherited.
3. Choose **Convert**.
4. Remove only `Everyone`, then `Apply`.
5. Click `Add` -> `Select a Principal`, choose the Project group, assign permissions, then `OK`.

<!-- SCREENSHOT: Project folder Advanced Security Settings after disabling inheritance -->

### Effective Permissions

> The actual, final permissions a specific user or group has on a specific file or folder.
>
> 1. **Additive:** permissions are cumulative. If Group A grants Read and Group B grants Write, the user gets both.
> 2. **Deny wins:** an explicit `Deny` overrides any `Allow`. A single explicit Deny blocks the user even if multiple groups allow access.

1. Create a folder `Confidential` inside the parent folder.
2. Open `Properties` -> `Security`.
3. Add one user to deny (example: Declan Rice).
4. Select the permissions to deny, then `Apply`.

<!-- SCREENSHOT: Effective Access tab for the denied user -->

### Access-Based Enumeration (ABE)

> Without ABE, users see folders they cannot open and get "Access Denied". With ABE enabled, Windows filters the directory listing so folders a user has no permission to access do not appear at all.
>
> **Caution:** ABE only hides folders. It does not protect files if the permissions themselves are misconfigured.

1. Set the folder permissions in `Security` (as above).
2. Open `Server Manager` -> `File and Storage Services` -> `Shares`.
3. Right-click the share -> `Properties` -> `Settings`.
4. Check `Enable access-based enumeration`.

<!-- SCREENSHOT: Same share viewed by two users (folder visible vs hidden) -->

---

## 8. Security Policy

### Account Lockout Policy

> Protects against brute-force attacks. Key settings: account lockout threshold and account lockout duration.

1. Open `Group Policy Management`.
2. Create a new GPO, or edit the `Default Domain Policy`.
3. Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Account Policies -> Account Lockout Policy.

### User Rights Assignment

> Assign and restrict user rights to harden the environment, for example restricting Remote Desktop and denying local logon.

1. Open `Group Policy Management` and create a new GPO.
2. Computer Configuration -> Policies -> Windows Settings -> Security Settings -> Local Policies -> User Rights Assignment.

### Fine-Grained Password Policies

> Apply different password policies to different groups of users.
>
> **Scenario:** stricter password requirements for administrative accounts, less stringent requirements for standard users.

1. Open `Active Directory Administrative Center` (ADAC).
2. Go to `[domain] (local)` -> `System` -> `Password Settings Container`.
3. `New` -> `Password Settings`.
   - **Precedence** decides which policy wins when multiple Password Settings apply to the same user or group. **A lower number means higher priority.**

<!-- SCREENSHOT: Password Settings object for admins -->

---

## 9. Service Accounts and Sysinternals

> Service accounts are not for people. They exist for specific tasks, for example a computer that displays a restaurant menu 24/7.

1. Create a `Service Accounts` OU and add a new user inside it.
2. On the client VM, open a browser and download the [Sysinternals Suite](https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite).
3. Set up `Autologon64`.
4. Reboot. The automatic logon is complete.
5. Configure the browser to display the target page.

<!-- SCREENSHOT: Autologon64 configuration -->

---

## 10. Automation: Bulk User Creation

> **TODO:** Link the PowerShell script and add before/after timing.

Manual creation takes roughly 15 seconds per user. For 100 users that is 15 x 100 = 1,500 seconds (about 25 minutes). See [Problem 3](#problems-and-resolutions).

<!-- TODO: link to script in repository -->
<!-- TODO: sample CSV (anonymized) -->
<!-- TODO: measured runtime for N users -->
<!-- SCREENSHOT: Script run output and resulting users in the correct OUs -->

---

## Problems and Resolutions

### Problem 1: Domain controller promotion prerequisite check failed

- **Symptom:** during the prerequisite check in `Promote this server to a domain controller`, it failed with "verification of prerequisites for domain controller promotion failed. Certificate server is installed".
- **Cause:** AD DS must be set up first. AD CS was already installed before promotion.
- **Resolution:** removed AD CS and restarted the machine. The error was gone.

### Problem 2: Control Panel blocked while configuring the network

- **Symptom:** Control Panel was blocked during [Setting Up the Network](#5-setting-up-the-network).
- **Cause:** the [Restrict Control Panel](#4-group-policy-management) GPO had been applied to all users, because the groups had not been created yet.
- **Resolution:**
  1. Removed the admin group from the Restrict Control Panel GPO scope for the time being.
  2. Opened `Win + R` and ran `gpupdate /force`.

### Problem 3: Manual user creation does not scale

- **Symptom:** adding users in AD by hand takes about 15 seconds each. 100 users would take about 25 minutes.
- **Resolution:** automate. See [Section 10](#10-automation-bulk-user-creation).