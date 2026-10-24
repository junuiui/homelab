# Active Directory Home Lab: Setup Guide

Windows Server 2022 domain environment built on VMware Workstation Pro, with Windows 11 Enterprise domain-joined clients.

---

## Table of Contents

0. [Requirements](#0-requirements)
1. [VMware Workstation Setup](#1-vmware-workstation-setup)
2. [Active Directory Setup](#2-active-directory-setup)
3. [Active Directory Users and Computers (OU)](#3-active-directory-users-and-computers-ou)
4. [Group Policy Management](#4-group-policy-management)
5. [Setting Up the Network](#5-setting-up-the-network)
6. [DHCP and DNS Configuration](#6-dhcp-and-dns-configuration)
7. [File Sharing](#7-file-sharing)
8. [Security Policy](#8-security-policy)
9. [Service Accounts and Sysinternals](#9-service-accounts-and-sysinternals)
10. [Automation: Bulk User Creation & Offboarding](#10-automation-bulk-user-creation--offboarding)
11. [Problems and Resolutions](#11-problems-and-resolutions)

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
   2. Select `I will install the operating system later` *(Selecting the ISO image at this step triggers VMware Easy Install, so attach it afterwards)*.
   3. Select `Microsoft Windows`, then Version = `Windows Server 2022`.
2. Open the VM's CD/DVD settings.
   1. Select `Use ISO image file`.
   2. Browse to the Windows Server 2022 ISO.
   3. Click `OK`.
3. Power on the virtual machine.
4. During installation, select `Windows Server 2022 Standard Evaluation (Desktop Experience)`.
5. Wait for the installation to complete.
6. Run `winver` from the search bar and confirm the version is `21H2`.

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
   6. Active Directory Certificate Services *(Install AD CS **after** the server is promoted to a domain controller. Installing it first causes the promotion prerequisite check to fail. See [Problem 1](#11-problems-and-resolutions))*.
4. Click `Install`. Do **not** close the installation window.
5. When finished, click `Promote this server to a domain controller`.
   1. Select `Add a new forest`.
   2. Create the AD domain `[name].local`.
   3. Install.
6. After the restart, the logon page shows `domainName\Administrator`.

---

## 3. Active Directory Users and Computers (OU)

Set up Organizational Units (OUs) to structure users, computers, and administrative boundaries cleanly.

1. Open `Active Directory Users and Computers`.
2. Right-click `domainName.local` -> `New` -> `Organizational Unit`.
3. Nest OUs logically by department, devices, and service accounts.

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

### Applying and Testing GPOs

1. Client OS must be Windows 10/11 Pro or Enterprise. This lab uses Windows 11 Enterprise.
2. Set the client's DNS server to the Server's IP address.
   - Verify connectivity: `ping [IP_address]`
   - Verify name resolution: `nslookup [domainName].local`
3. Join the domain: `File Explorer` -> `This PC` -> `Properties` -> set Domain to `[domainName].local`.
4. After rebooting, log in using a domain user account.
5. On the server, link GPOs to target OUs and verify with `gpresult /r` on the client.

---

## 5. Setting Up the Network

1. On the server, run `ipconfig` to find the current IP address, mask, and gateway.
2. Open `Control Panel` *(If blocked, see [Problem 2](#11-problems-and-resolutions))*.
3. Open `Ethernet0` -> `Properties` -> `Internet Protocol Version 4 (TCP/IPv4)`.
4. Configure a static IP address, subnet mask, and gateway.

---

## 6. DHCP and DNS Configuration

### DHCP Setup

1. Open **Server Manager** -> **Tools** -> **DHCP**.
2. Select your server name, right-click **IPv4**, and select **New Scope**.
3. Configure the Scope Options:
   - **Scope Name**: e.g., `HQ-DHCP-Scope`.
   - **IP Address Range**: `10.0.0.1` to `10.0.0.254` (Subnet Mask: `255.255.255.0`).
   - **Exclusions**: Exclude static IP ranges used by servers and infrastructure devices.
   - **003 Router**: Gateway IP address.
   - **006 DNS Servers**: Active Directory Domain Controller IP.
   - **015 DNS Domain Name**: `[domainName].local`.
4. Authorize the DHCP server in Active Directory and activate the scope.

| DHCP Configuration & Server Setup | Exclusions & Leases |
|---|---|
| ![DHCP Server](resources/dhcp-server.png) | ![DHCP Excludes](resources/dhcp-excludes.png) |
| ![DHCP Setup Wizard](resources/dhcp-server-setups.png) | ![DHCP Leases](resources/dhcp-lingard.png) |

---

### DNS Setup

1. Open **Server Manager** -> **Tools** -> **DNS**.
2. **Forward Lookup Zones**: Confirm default Active Directory records (`_msdcs`, `DomainControllers`, SRV records) exist.
3. **Reverse Lookup Zone**:
   - Right-click **Reverse Lookup Zones** -> **New Zone**.
   - Select Primary zone, IPv4, enter Network ID (e.g., `10.0.0`), and allow secure dynamic updates.
4. **Forwarders**: Add public DNS servers (e.g., Google `8.8.8.8` or Cloudflare `1.1.1.1`) to resolve external queries.
5. **Verification**: Execute `nslookup [domainName].local` and `dcdiag /test:dns`.

| DNS Zones & Forwarders | Verification & Name Resolution |
|---|---|
| ![DNS Forward Zone](resources/dns-server-forward.png) | ![DNS NSLookup](resources/dns-nslookup.png) |
| ![DNS Reverse Zone](resources/dns-server-reverse.png) | ![DNS Diagnostics](resources/dns-test.png) |

---

## 7. File Sharing

### Group Policy Mapped Drives

To prevent mapped drives from disappearing after reboots, deploy drives using GPO Preferences:
1. `Group Policy Management` -> User Configuration -> Preferences -> Windows Settings -> Drive Maps.
2. Target the specific user OU to ensure automatic drive mapping upon logon.

### File Server Resource Manager (FSRM)

1. Install **File Server Resource Manager** via Server Roles.
2. Set up **Quota Management** to cap maximum folder usage and **File Screen Management** to block specific file extensions (e.g., `.exe`, `.mp3`).

![FSRM File Screen Configuration](resources/homelab-filescreen.png)

### Inheritance, Permissions & Access-Based Enumeration (ABE)

- **Inheritance & Explicit Permissions**: Disabled inheritance on sensitive folders (e.g., `Project`) and converted permissions to explicit ACLs, ensuring only authorized groups have access.
- **Effective Permissions**: Verified user rights using the *Effective Access* tab to guarantee cumulative permissions and explicit `Deny` rules behave as expected.
- **Access-Based Enumeration (ABE)**: Enabled ABE under Share Properties so users only see folders and files they have read permissions for.

---

## 8. Security Policy

### Account Lockout Policy
Protects the domain against brute-force attacks by limiting failed logon attempts.

![Password Security Policy](resources/homelab-password_security.png)

### User Rights Assignment & Fine-Grained Password Policies
Configured user rights to harden security by restricting local logon rights and Remote Desktop Protocol (RDP) access for standard accounts.

| User Rights Assignment Settings | Policy Application |
|---|---|
| ![User Rights Admin](resources/homelab-user_right_password_admin.png) | ![User Rights User](resources/homelab-user_right_password_user.png) |
| ![User Rights Security](resources/homelab-user_right_security%20(2).png) | |

---

## 9. Service Accounts and Sysinternals

Dedicated service accounts were created inside a restricted `Service Accounts` OU to handle automated tasks without human interaction.

1. Created non-interactive service accounts.
2. Utilized Sysinternals **Autologon64** on target clients for automated workspace setups.

| Sysinternals Autologon Configuration | Automated Session |
|---|---|
| ![Autologon Config](resources/service_account-website-login.png) | ![Service Account Desktop](resources/service_account-website.png) |

---

## 10. Automation: Bulk User Creation & Offboarding

To eliminate manual GUI overhead, PowerShell scripts were developed to automate onboarding (reading CSV files, creating accounts, setting password policies, allocating OUs) and offboarding (disabling accounts, revoking group memberships, archiving user data).

### Script Execution & Workflow

| Script Overview & Single User | CSV Bulk Creation |
|---|---|
| ![PowerShell Script](resources/new-user-script.png) | ![CSV File Input](resources/new-user-script-csv.png) |
| ![User Creation Result](resources/new-user-script-newUser.png) | ![Bulk Users Result](resources/new-user-script-csv-newUsers.png) |

### Offboarding Automation

![Offboarding Script Execution](resources/offboarding.png)

---

## 11. Problems and Resolutions

### Problem 1: Domain controller promotion prerequisite check failed
- **Symptom:** Promotion wizard failed stating Active Directory Certificate Services (AD CS) was already installed.
- **Cause:** AD DS must be promoted before installing AD CS.
- **Resolution:** Uninstalled AD CS, promoted the domain controller successfully, and then re-installed AD CS.

### Problem 2: Control Panel blocked while configuring network settings
- **Symptom:** Control Panel was blocked during static IP setup.
- **Cause:** The *Restrict Control Panel* GPO was linked broadly prior to completing user and group OU assignments.
- **Resolution:** Temporarily excluded the Domain Admin group from the GPO scope and executed `gpupdate /force`.

### Problem 3: Manual account provisioning inefficiency
- **Symptom:** Creating accounts manually took ~15 seconds per account, making large-scale management unviable.
- **Resolution:** Developed PowerShell onboarding scripts (`new-user-csv.ps1`) to process CSV input files in bulk.

---

## Todo:
1. Script on GPO settings
