# Kopia Windows Service Installation Script

This script is designed to set up the Kopia service on a Windows 10 64-bit system.

Kopia version used: [v0.16.1](https://github.com/kopia/kopia/releases/tag/v0.16.1)
(Due to a bug in version v0.17.0 when using VSS in root drive directories [#3482](https://github.com/kopia/kopia/issues/3842))

![v0 9 1](https://github.com/user-attachments/assets/52215d8e-9445-46f5-862a-e65bc4ecd3e9)

## Script Overview

This script installs the Kopia application as a Windows service with the following features:

- Specify any Windows account to run the Kopia service.
- Configures Windows Firewall to allow Kopia traffic.
- Sets up SSL certificates for secure connections.
- Configures login credentials for the Web UI.
- Sets up repository with Rclone for flexible storage options.

## Third-Party Tools

The script utilizes the following third-party tools, which are included with the script package. However, you can download them from their respective websites if needed:

- **OpenSSL (Win-64 3.3.1)** [OpenSSL](https://wiki.overbyte.eu/wiki/index.php/ICS_Download#Download_OpenSSL_Binaries)
- **Rclone (v1.67.0)** [Rclone](https://rclone.org/downloads/)
- **WinSW (v2.12.0)** [WinSW](https://github.com/winsw/winsw)
- **htpasswd (Apache 2.4.62-240718 Win64)** [htpasswd](https://www.apachelounge.com/download/)

## Installation Instructions

1. **Download and Extract the Script Package**: Download the entire code from the GitHub repository and extract it.
2. **Run the Installation Script**: Execute the `Install-Script.cmd` file.

## Notes
- For best results, place the Kopia folder in the root directory, such as `C:/Kopia` or `D:/Kopia`.
- Ensure that all paths and configurations are correct before running the script.
