💊 Pharmacy Management System (Bash)
A lightweight terminal-based pharmacy system for managing medicines, users, sales, and inventory.

⚙️ Features
👤 User Roles

Admin 👨‍⚕️

Seller 🧑‍💼

🛠 Admin Tools

➕ Add medicine

📝 Update stock/price

🔍 Search/view medicines

❌ Delete items

📉 Low stock alerts

🔁 Restock

🧹 Expired medicine cleanup

💾 Backup data

🛒 Seller Tools

🔎 Search & sell medicine

🧾 Print receipts (with seller name)

📦 Track cart

📆 Daily sales reports

🛡 Validations

Date, quantity, and price checks

Auto-detect malformed entries

📁 Files
File	Purpose
pharmacy.sh	Main script
medicines.txt	Medicine database
users.txt	Login credentials
receipts/	Receipts & daily reports
cart.tmp	Temporary seller cart
backup/	Backed-up data

🚀 Quick Start
bash
Copy
Edit
chmod +x pharmacy.sh
./pharmacy.sh
🧑‍💻 Default Users (edit users.txt):

pgsql
Copy
Edit
admin,admin123,admin
seller1,pass1,seller
