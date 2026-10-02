# Terms
> Documents for explaining the tech terms in Windows Server 2022

## Server Roles

### Active Directory Certificate Services
**Active Directory Certificate Services** (AD CS) is used to create certification authorities and related role services that allow you to issue and manage certificates used in a variety of applications

### Active Directory Domain Services
**Active Directory Domain Services (AD DS)** stores information about objects on the network and makes this information available to users and network adminstrators. AD DS uses domain controllers to give network users access to permitted resources anywhere on the network through a single logon process

### DHCP Server
**Dynamic Host Configuration Protocol** (DHCP) Server enables you to centrally configure, manage, and provide temporary IP addresses and related information for client computers

### DNS Server
**Domain Name System** (DNS) Server provides name resolution for TCP/IP networks. 

### File and Storage Services
Includes services that are always installed, as well as functionality that you can install to help manage file servers and storage

### Print and Document Services
Enables you to centralize print server and network printer management tasks

### Remote Access
provides seamless connectivity through DirectAccess, VPN, and Web Application Proxy. 

#### DirectAccess
Provides an Always On and Always Managed experience. 

#### RAS
Provides traditional VPN services, including site-to-site (branch-office or cloud-based)

#### Web Application Proxy
Enables the publishing of selected HTTP- and HTTPS- based applications from your corporate network to client devices outside of the corporate network. 

#### Routing
Provides traditional routing capabilities, including NAT and other connectivity options. RAS and Routing can be deloyed in single-tenant or multi-tanent mode.

## Basics
### Organizational Unit (OU)
> Container that store objects

### Group

#### Group Scope
| Group Scope | Membership (Who can be a member?) | Conversion Rules | Main Purpose & Use Case (AGDLP / AGUDLP Pattern) |
| :--- | :--- | :--- | :--- |
| **Domain Local** | • Accounts from **any domain**<br>• Global groups from **any domain**<br>• Universal groups from **any domain**<br>• Domain Local groups from the **same domain** | Can be converted to **Universal**, provided it does not contain any other Domain Local groups as members. | **Assigning Permissions (P)**<br>• Used to grant access rights to local resources (e.g., file shares, printers) in the local domain. |
| **Global** | • Accounts from the **same domain**<br>• Global groups from the **same domain** | Can be converted to **Universal**, provided it is not a member of any other Global group. | **Grouping Accounts (G)**<br>• Used to organize users who share similar job roles or business needs within the same domain. |
| **Universal** | • Accounts from **any domain**<br>• Global groups from **any domain**<br>• Universal groups from **any domain** | Cannot be converted to any other scope directly if its members violate scope restrictions. | **Cross-Domain Consolidation (U)**<br>• Used to consolidate groups that span across multiple domains in a multi-domain forest. |

#### Group types
* **Group Type:** All administrative and resource-access groups are deployed strictly as **Security Groups** to leverage Access Control Lists (ACLs) and enforce the AGDLP access management framework.
* **Group Scopes:** Utilized Global Groups for role-based aggregation and Domain Local Groups for micro-resource permission assignment.

#### Group Type
| Group Type | Primary Purpose | Security Identifier (SID)? | Homelab & Enterprise Use Cases |
| :--- | :--- | :--- | :--- |
| **Security Groups**<br>(보안 그룹) | • **Access Control & Permissions**<br>• Managing security rights across the network. | **Yes**<br>(Possesses a SID) | • **99% of Homelab use cases**.<br>• Assigning NTFS file/folder permissions (e.g., Read/Write).<br>• Granting system rights (e.g., Remote Desktop access).<br>• Can *also* be used as an email distribution list if needed. |
| **Distribution Groups**<br>(배포 그룹) | • **Mass Communication**<br>• Email broadcasting lists. | **No**<br>(Ignored by ACLs) | • **Exclusively for email applications** (e.g., Microsoft Exchange).<br>• Creating company-wide announcement emails (e.g., `all-staff@company.local`).<br>• Cannot be used to secure or grant access to network resources. |

## Networks
### Domain Controller (Main Server PC)
- IPv4
- Subnet Mask
- Default Gateway
- DNS Server

## File SHring

### NTFS vs sharing
#### NTFS
- File & Folder level

#### Sharing
- Folder level