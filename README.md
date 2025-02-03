### **Step 7: Configure BELABOX Settings**  
Create/modify the `setup.json` file for BELABOX hardware configuration:  

1. Navigate to the `belaUI` directory:  
   ```bash
   cd ~/belaUI
   ```  
2. Create/edit the configuration file:  
   ```bash
   sudo nano setup.json
   ```  
3. Paste this configuration (adjust paths if needed):  
   ```json
   {
     "hw": "rk3588",
     "belacoder_path": "/root/belacoder/",
     "srtla_path": "/root/srtla/",
     "bitrate_file": "/tmp/belacoder_br",
     "ips_file": "/tmp/srtla_ips"
   }
   ```  
   - **Key parameters:**  
     - `hw`: Your device chipset (e.g., `rk3588` for Rockchip).  
     - `belacoder_path`: Path to your compiled belacoder.  
     - `srtla_path`: Path to SRTLA (if used).  
4. Save the file (`Ctrl+O` → Enter) and exit (`Ctrl+X`).  

---

### **Updated Summary**  
- **Configuration:** Customized via `setup.json` for hardware and paths.  
- **Paths:** Verify locations match your installation (e.g., `/root/belacoder/`).  
- **Hardware:** Set `hw` to match your device (critical for compatibility).  

**Final Command to Start BELABOX:**  
```bash
sudo nodejs belaUI.js
```  

Now BELABOX will use your custom configuration! 🚀
