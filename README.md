

---

### **BELABOX Installation Tutorial on Android via Linux Deploy**  
**Prerequisites:**  
- Rooted Android device.  
- **Linux Deploy** app installed (configured for Ubuntu).  
- Basic familiarity with Linux terminal.  

---

### **Step 1: Upgrade Ubuntu to 20.04 LTS**  
**Why?** Linux Deploy may default to an unsupported Ubuntu version. `libsrt-dev` (required for BELABOX) is only available in Ubuntu 20.04 ("Focal").  

1. Open the terminal in Linux Deploy and run:  
   ```bash
   sudo nano /etc/apt/sources.list
   ```  
2. Replace all instances of `jammy` (Ubuntu 22.04) with **`focal`** (Ubuntu 20.04).  
3. Save changes (`Ctrl+O` → Enter) and exit (`Ctrl+X`).  
4. Update the system:  
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```  
   - **Important:** If prompted about SSH configuration, select **"keep the local version"**.  
5. Reboot your phone.  

---

### **Step 2: Configure SFTP (Optional)**  
To access SFTP as root:  
1. In the terminal:  
   ```bash
   su
   passwd
   ```  
2. Set a password for the `root` account.  

---

### **Step 3: Install Dependencies for belacoder**  
1. Install required packages:  
   ```bash
   sudo apt-get install build-essential git libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libsrt-dev -y
   ```  

---

### **Step 4: Compile belacoder**  
1. Navigate to the root directory and clone the repository:  
   ```bash
   cd ~
   git clone https://github.com/BELABOX/belacoder.git
   cd belacoder
   make
   ```  
   - **If compilation fails (missing SRT libraries):**  
     ```bash
     cd ~
     git clone https://github.com/Haivision/srt.git  # Use the official SRT repo
     cd srt
     ./configure --prefix=/usr/local
     make -j4
     sudo make install
     sudo ldconfig  # Refresh library paths
     ```  
     Return to belacoder and retry:  
     ```bash
     cd ~/belacoder
     make
     ```  

---

### **Step 5: Install belaUI**  
1. Install dependencies:  
   ```bash
   sudo apt-get install nano build-essential git tcl libssl-dev nodejs npm usb-modeswitch libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev -y
   ```  
2. Clone the repository and switch to the correct branch:  
   ```bash
   cd ~
   git clone https://github.com/BELABOX/belaUI.git
   cd belaUI
   git checkout ws_nodejs
   ```  
3. Create a `package.json` file with:  
   ```bash
   echo '{
     "dependencies": {
       "serve-static": "^1.14.1",
       "finalhandler": "^1.1.2",
       "bcrypt": "^5.1.1",
       "ws": "^7.4.4"
     }
   }' > package.json
   ```  
4. Install Node.js modules:  
   ```bash
   npm install
   ```  

---

### **Step 6: Configure BELABOX Settings**  
1. Navigate to the `belaUI` directory:  
   ```bash
   cd ~/belaUI
   ```  
2. Create/edit the configuration file:  
   ```bash
   sudo nano setup.json
   ```  
3. Paste this configuration (adjust paths/hardware as needed):  
   ```json
   {
     "hw": "rk3588",  # Change to your device's chipset (e.g., "raspberrypi", "odroid")
     "belacoder_path": "/root/belacoder/",
     "srtla_path": "/root/srtla/",  # Optional: Only if using SRTLA
     "bitrate_file": "/tmp/belacoder_br",
     "ips_file": "/tmp/srtla_ips"
   }
   ```  
   - **Note:** Replace `rk3588` with your actual hardware (check device specs).  
4. Save the file (`Ctrl+O` → Enter) and exit (`Ctrl+X`).  

---

### **Step 7: Launch belaUI**  
1. Start the interface:  
   ```bash
   sudo node belaUI.js  # Use "node" instead of "nodejs" if needed
   ```  
2. Access BELABOX via a web browser at: `http://<your_phone_IP>:8080`.  

---

### **Summary**  
- **System:** Ubuntu 20.04 LTS (verify with `lsb_release -a`).  
- **BELABOX Components:**  
  - Encoder: `belacoder` (run via `./belacoder` in `~/belacoder`).  
  - Web UI: `belaUI` (launched with `sudo node belaUI.js`).  
- **SFTP Access:** Use root credentials set earlier.  

**Troubleshooting Tips:**  
1. **Dependency Issues:**  
   ```bash
   sudo apt --fix-broken install  # Resolve broken packages
   ```  
2. **Node.js Errors:**  
   - Confirm Node.js version: `node -v` (recommended: v12+).  
   - Reinstall modules: `rm -rf node_modules && npm install`.  
3. **Hardware Mismatch:**  
   - Edit `setup.json` to match your device’s chipset.  
4. **Permissions:** Avoid running as root if possible. Create a dedicated user:  
   ```bash
   sudo adduser belabox
   sudo usermod -aG sudo belabox
   ```  

---

Now BELABOX is ready with your custom configuration! 🚀  
**Need Help?**  
- Check BELABOX documentation: [BELABOX GitHub](https://github.com/BELABOX).  
- Visit forums for hardware-specific guidance (e.g., Rockchip, Raspberry Pi).  

---

**Key Improvements:**  
- Fixed SRT repository URL (now points to official Haivision repo).  
- Added hardware compatibility notes for `setup.json`.  
- Clarified Node.js command (`node` vs. `nodejs`).  
- Added troubleshooting tips for dependency/node issues.  
- Emphasized security by suggesting a non-root user.
