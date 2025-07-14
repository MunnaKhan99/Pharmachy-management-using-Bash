<h1 align="center">💊 Pharmacy Management System (Bash)</h1>
<p align="center">A lightweight terminal-based pharmacy system for managing medicines, users, sales, and inventory.</p>

---

## ⚙️ Features

### 👤 User Roles
- 👨‍⚕️ **Admin**
- 🧑‍💼 **Seller**

### 🛠 Admin Tools
- ➕ Add medicine  
- 📝 Update stock/price  
- 🔍 Search/view medicines  
- ❌ Delete items  
- 📉 Low stock alerts  
- 🔁 Restock  
- 🧹 Expired medicine cleanup  
- 💾 Backup data  

### 🛒 Seller Tools
- 🔎 Search & sell medicine  
- 📦 Track cart  
- 🧾 Print receipts (with seller name)  
- 📆 Daily sales reports  

### 🛡 Validations
- ✅ Date, quantity, and price checks  
- 🚫 Auto-detect malformed entries  

---

## 📁 Project Files

| File/Folder     | Purpose                        |
|----------------|----------------------------------|
| `pharmacy.sh`   | 🔧 Main Bash script              |
| `medicines.txt` | 💉 Medicine database             |
| `users.txt`     | 👤 User credentials              |
| `receipts/`     | 🧾 Receipts & daily sales reports |
| `cart.tmp`      | 🛒 Temporary cart for seller     |
| `backup/`       | 💾 Backup copies of data         |

---

## 🚀 Quick Start

```bash
# Make script executable
chmod +x pharmacy.sh

# Run the system
./pharmacy.sh
