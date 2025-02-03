### **BELABOX Installation Tutorial on Android via Linux Deploy**  
**Latest Version (2025-02-03)**  

---

## **Option 1: Auto-Installation (Recommended)**  
Use the automated installation script:  

1. Connect to your Ubuntu system via SSH and run:  
   ```bash
   sudo -i  # Log in as root
   wget https://raw.githubusercontent.com/thekardam/phonebelabox/main/autoinstaller.sh
   chmod +x autoinstaller.sh
   ./autoinstaller.sh
   ```  
2. Follow the on-screen instructions.  
3. After completion, verify component versions:  
   ```bash
   lsb_release -a  # Ubuntu version
   /root/srtla/srtla -v  # SRTLA version
   node -v  # Node.js version
   ```  

---

## **Option 2: Manual Installation**  

### **Step 1: Upgrade Ubuntu to 20.04 LTS**  
1. Edit package sources:  
   ```bash
   sudo nano /etc/apt/sources.list
   ```  
2. Replace all instances of `jammy` → **`focal`**  
3. Update the system:  
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo reboot
   ```  

### **Step 2: SFTP Configuration**  
1. Set root password:  
   ```bash
   sudo passwd root
   ```  

### **Step 3: System Dependencies**  
```bash
sudo apt install -y \
    net-tools build-essential git cmake libssl-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    nodejs npm usb-modeswitch
```  

### **Step 4: Compile SRT + SRTLA**  
1. SRT:  
   ```bash
   cd ~
   git clone https://github.com/Haivision/srt.git
   cd srt
   ./configure --prefix=/usr/local
   make -j$(nproc)
   sudo make install
   sudo ldconfig
   ```  

2. SRTLA:  
   ```bash
   cd ~
   git clone https://github.com/BELABOX/srtla.git
   cd srtla
   make
   sudo cp srtla_* /usr/local/bin/
   ```  

### **Step 5: Install belacoder**  
```bash
cd ~
git clone https://github.com/BELABOX/belacoder.git
cd belacoder
make
sudo cp belacoder /usr/local/bin/
```  

### **Step 6: Configure belaUI**  
1. Clone the repository:  
   ```bash
   cd ~
   git clone https://github.com/BELABOX/belaUI.git
   cd belaUI
   git checkout ws_nodejs
   ```  

2. Create `package.json`:  
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

3. Install Node.js dependencies:  
   ```bash
   npm install
   ```  

4. Create `setup.json`:  
   ```json
   {
     "hw": "rk3588",
     "belacoder_path": "/usr/local/bin/",
     "srtla_path": "/usr/local/bin/",
     "bitrate_file": "/tmp/belacoder_br",
     "ips_file": "/tmp/srtla_ips"
   }
   ```  

### **Step 7: Launch BELABOX**  
```bash
cd ~/belaUI
node belaUI.js
```  
Access via browser: `http://<PHONE_IP>:8080`  

---

## **Troubleshooting**  
1. **Compilation Errors**:  
   ```bash
   sudo apt --fix-broken install
   sudo rm -rf node_modules && npm install
   ```  

2. **Node.js Issues**:  
   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
   nvm install 21
   nvm use 21
   ```  

3. **Verification**:  
   ```bash
   # Check versions
   srt-live-transmit --version
   /usr/local/bin/srtla_send -v
   lsb_release -a
   ```  

---

## **Important Notes**  
- **Hardware Requirements**:  
  - Min. 2 GB free storage  
  - ARMv8 (aarch64) CPU  

- **Security Best Practices**:  
  ```bash
  # Create a dedicated user
  sudo adduser belabox
  sudo usermod -aG sudo belabox
  ```  

- **Updates**:  
  ```bash
  cd ~/phonebelabox && git pull
  ```  

---

**All scripts and configurations available at**:  
[https://github.com/thekardam/phonebelabox](https://github.com/thekardam/phonebelabox)  

**Technical Support**:  
[Issues · thekardam/phonebelabox](https://github.com/thekardam/phonebelabox/issues)
