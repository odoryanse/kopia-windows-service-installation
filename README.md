# Kopia Windows Service Installation Script

This script is designed to set up the Kopia service on a Windows 10 64-bit system.

## Script Overview

- **Platform Tested**: Windows 10 64-bit
- **Service Account**: Runs using the user's Windows account
- **Certificate**: Includes a Root CA certificate
- **User Requirement**: Knowledge of installing Rclone and administrative rights to install the service

## Third-Party Tools

The script utilizes the following third-party tools, which are included with the script package. However, you can download them from their respective websites if needed:

- **OpenSSL (Win-64 3.3.1)** [OpenSSL](https://wiki.overbyte.eu/wiki/index.php/ICS_Download#Download_OpenSSL_Binaries)
- **Rclone (v1.67.0)** [Rclone](https://rclone.org/downloads/)
- **Shawl (v1.5.0)** [Shawl](https://github.com/mtkennerly/shawl)
- **htpasswd (Apache 2.4.62-240718 Win64)** [htpasswd](https://www.apachelounge.com/download/)
- **PrivMan (v1.0.2)** [PrivMan](https://github.com/Bill-Stewart/PrivMan)

## Installation Instructions

1. **Download and Extract the Script Package**: Download the entire code from the GitHub repository and extract it.
2. **Run the Installation Script**: Execute the `kopia_windows_service_installation.cmd` file.

## Notes
- For best results, place the Kopia folder in the root directory, such as `C:/` or `D:/`.
- Ensure that all paths and configurations are correct before running the script.
