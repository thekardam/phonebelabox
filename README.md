### **BELABOX Installation Tutorial on Android via Linux Deploy**  
**Prerequisites:**  
- Rooted Android device.  
- **Linux Deploy** app installed (configured for Ubuntu).  
- Basic familiarity with Linux terminal.  

---

### **Step 1: Upgrade Ubuntu to 20.04 LTS**  
The default Linux Deploy installation may use an outdated Ubuntu version. Fix this:  

1. Open the terminal in Linux Deploy and run:  
   ```bash
   sudo nano /etc/apt/sources.list
   ```  
2. Replace all instances of `jammy` with **`focal`** (to switch to Ubuntu 20.04).  
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
   - **If compilation fails:**  
     ```bash
     cd ~
     git clone https://github.com/BELABOX/srt.git
     cd srt
     ./configure --prefix=/usr/local
     make -j4
     sudo make install
     sudo ldconfig
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
3. Create a `package.json` file with the following content:  
   ```json
   {
     "dependencies": {
       "serve-static": "^1.14.1",
       "finalhandler": "^1.1.2",
       "bcrypt": "^5.1.1",
       "ws": "^7.4.4"
     }
   }
   ```  
4. Install Node.js modules:  
   ```bash
   npm install
   ```  

---

### **Step 6: Launch belaUI**  
1. Start the interface:  
   ```bash
   sudo nodejs belaUI.js
   ```  
2. Access BELABOX via a web browser at: `http://<your_phone_IP>:8080`.  

---

### **Summary**  
- System: Ubuntu 20.04 LTS (verify with `lsb_release -a`).  
- BELABOX: Runs via belacoder (use `./belacoder` in `~/belacoder`) and belaUI.  
- SFTP: Access as root using the password you set.  

**Troubleshooting Tips:**  
- Ensure all dependencies are installed.  
- Confirm Ubuntu version is **20.04 (Focal)**.  
- If compilation errors occur, run `sudo ldconfig` and retry the steps.
