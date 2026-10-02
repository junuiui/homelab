# Set up Guide

## 0. Requirements
1. [VMware Workstation Pro 26H1 for Windows (26H1u1)](https://knowledge.broadcom.com/external/article?articleNumber=368667)
2. [Window Server 2022 ISO](https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022) for Server (AD)
3. [Windows 11 Enterprise](https://info.microsoft.com/ww-landing-windows-11-enterprise.html) for Guest Users

## 1. VMware Workstation Setting
1. Open up
2. Click `Create a New Virtual Machine`
   1. Select `Typical`
   2. `I will install the operating system later` -> because if select ISO image in the beginning, it doesn't work properly
   3. `Microsoft Windows`
      1. Version = `Windows Server 2022`
3. After, go to CD/DVD setting
   1. `Use ISO Image file`
   2. put the `Window Server 2022 ISO` image
   3. Click `OK`
4. Power up Virtual Machine
5. Install, and make sure to select `Windows Server 2022 Standard Evaluation (Desktop Experience)`
6. Wait for installation to complete
7. make sure the version is `21H2` by using `winver` in search tool

## 2. Active Directory Set-up
1. Go to `Server Manager`
2. Click `Add Roles and Features` in `Manager` on the right-top side
3. On `Server Roles`, select 
   1. Active Directory Domain Service
   2. Active Directory Certificate Services
   3. DHCP Server
   4. DNS Server
   5. File and Storage Services
   6. Remote Access
4. Install (DO NOT close the installation window)
5. Once done, click `Promote this server to domain controller` 
   1. Add a new forest
   2. Create an AD domain `[name].local`
   3. Install
6. Now, after retart, you can see `domainName\Administrator` on Logon page.

## 3. AD Users and Computers
> this step is to set up OU
1. Go to `Active Directory Users and Computers`
2. Right click, `domainName.local` -> New -> Organization Unit
   1. OU in OU is possible!

## 4. Group Policy Management
1. Right Click your domain
2. Select `Create a GPO..`
   1. Use `Password Policy`
      1. Right click to edit
      2. Should be Computer and Policies
      3. Window Setting
      4. Security Setting
      5. Account Policies
      6. Password Policy
      7. Do whatever you want to set up
   2. Use `Drive Mapping`
      1. Right click to edit
      2. User and Preferences
      3. Windows Settings
      4. Drive Maps
      5. New Mapped Drive
   3. Use `Wallpaper Policy`
      1. Right click to edit
      2. User and Policies
      3. Admin...
      4. Desktop
      5. Desktop
   4. Use `Restrict Control Panel`
      1. Right click to edit
      2. User and Policies
      3. Admin..
      4. Control Panel
      5. Prohibit ...
   5. User `Disable USB Storage`
      1. Computer and Policies
      2. Admin...
      3. System
      4. Removable Storage Access
      5. All Removable Storage classes..

### Applying and Testing GPOs
1. Only Windows 11 Pro (or 10 or 11 Enterprice)
2. Using [Windows 11 Enterprise](https://info.microsoft.com/ww-landing-windows-11-enterprise.html)
   1. Noted: Memory must be 4 GB (or higher) and Disk space must be > 15 GB
3. Set Up the DNS server as the Server IP address
   1. make sure to `ping [IP_address]`
   2. and `nslookup [domainName].local`
4. Once done, go to File -> Computer Properties -> set up Domain as `[domainName].local`
   1. administrator, yourPassword
5. When reboot is completed, choose **Other User** and log in with the user
6. From the AD, drag the policies (or preferences) from *Group Policy Objects* to the OU
7. Go to `Active Directory Users and Computers` then click Computer and move the computer you set up before to correspond OU

## 5. Setting up Network
1. Find the IP address of the server machine (`ipconfig`)
2. Control Panel (if blocked, check [Problem 2](#problems))
3. Go to Ethernet0 Properties
4. IPv4 (TCP/IPv4)
5. Use the following IP address:
   1. Then type the ip address, mask and gateway which are shown on the terminal
6. DNS will be set later!

## File Sharing
### Network Method
1. Create a folder in `C:\`
2. Named it, `jh.shared`
3. go to property
   1. Sharing tab
   2. Advanced Sharing
   3. Click `Share this folder`
   4. Permissions
   5. Add -> look for domain
   6. Apply!
4. go to Security (for NTFS) 
   1. You can change permissions as you want
5. go to Client (another VM)
   1. File Explorer
   2. Right click Network
   3. Map Ntwork Drive
   4. and go back to Server (VM) and type `hostname` in CMD to find out the name of the host
   5. Then, in the Map Network Drive, put the `\\[hostname]\folder_name` path

> Problem: when you restart (reboot), it will disappear.

### Mapped Method
> it solves the issues with Network Method
1. Go to Server (VM)
2. Group Policy Management
3. Create new GPO
   1. User and Preferences
   2. Windows Settings
   3. Drive Maps
   4. new drive
   5. Put `\\[hostname]\folder_name` path
   6. drag it into OU 
4. Now, they can see even if they reboot

### File Server resource Manager (FSRM)
1. Installation
   1. Go to Server Manager
   2. Manage -> Add Roles and Features
   3. Server Roles -> File and Storage Services -> File and iSCSI Services -> **File Server Resource Manager**
2. Open `File Server Resource Manager`
   1. Quota Management (to set up maximum amount of data limit)
      1. Create quota
   2. File Screen Management (controlling the file types allowed)
      1. Create File Screen

## Security Policy
### Account Lockout Policy Configuration
> Configure an account lockout policy to protect against brute-force attack  
> 1. password threshold
> 2. password lockout duration

1. Group Policy Management
2. Create new GPO or edit the `default domain policy`
3. Computer configuration -> Pollicies -> Windows Settings -> Security Settings -> Account Policies -> Account Lockout Policy

### User Rights Asrsignment
> Assign and restrict user rights to enhance security  
> restrict remote desktops, deny logon locally

1. GPO
2. Create new GPO
3. Computer Config -> Policies -> Windows Settings -> Security Settings -> Local Policies -> User Rights Assignments

### Implementing Fine-Grained Password Poilicies
> Apply different password policies to different groups of users.  
> Scenario: The organization wants to apply strcter password policies to adminstrative accounts while allowing standard users to have less stringent requirements

1. Active Directory Administrative Center (ADAC)
2. jh (local) > System > Password Setting Container
3. New password setting
   1. Precedence: determines the order in which policy objects are applied when multiple Password Settings are applied to a user or group. (Lower number the highest priority)


## Service Accounts & SysInternals
### Service Accounts
> Not for person. For specific tasks and purposes  
> a computer that displays a program 24/7 (restaurant menu, ...)
1. Create OU (Service Account OU)
   1. create new user
2. In client VM, go to internet browser
   1. Download [Sysinternal Suite](https://learn.microsoft.com/en-us/sysinternals/downloads/sysinternals-suite)
3. Set up `Autologon64`
4. reboot, then autologin completed!
5. then setup browser to show.







## Problems
1. While doing Pre-req check in `Prmote this erver to domain controller`, encountered pre-req failed due to "verification of preq for mc promotion failed. certificate server is installed".
   1. It's because AD DS has to be the first, not after AD CS is installed. 
   2. So, Removed AD CS, and restarted the machine.
   3. Error Removed.
2. Control Pannel Blocked while setting up for [Setting Network](#5-setting-up-network).
   1. It is because I previously set up the GPO for [Restrict Control Panel](#4-group-policy-management). It blocked all the users (since I have not made the groups YET!!)
   2. So, removed the admin group in the [Restrict Control Panel](#4-group-policy-management) just for now
   3. And `Win + R` to open up run.exe then `gpupdate /force` 
3. When Adding Users to AD, manual addtion takes too much time. (roughly 15 seconds by hand). It seems small just for 1 person, but what if we have to add 100 people at once? It would take approximately, 15*100 = 1500 seconds (= 25 minutes)
   1. Solution would be very obvious. **AUTOMATE**!!
   2. check []() for automation processes