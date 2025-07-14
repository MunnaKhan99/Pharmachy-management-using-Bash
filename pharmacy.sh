#!/bin/bash

DB="medicines.txt"
USERDB="users.txt"
CART="cart.tmp"
RECEIPTS="receipts"
mkdir -p "$RECEIPTS"
touch "$DB" "$USERDB" "$CART"

seller_name=""
receipt_id=$(date +%s)

# Function to validate numeric input
validate_number() {
    local input=$1
    if [[ ! $input =~ ^[0-9]+$ ]] || (( input <= 0 )); then
        echo "⚠️ Please enter a positive number."
        return 1
    fi
    return 0
}

# Function to validate date format (YYYY-MM-DD)
validate_date() {
    local date=$1
    if [[ ! $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "⚠️ Invalid date format. Use YYYY-MM-DD."
        return 1
    fi
    date -d "$date" >/dev/null 2>&1 || { echo "⚠️ Invalid date."; return 1; }
    return 0
}

# Function to validate medicines.txt format
validate_db() {
    local file="$1"
    local line_num=0
    local errors=0
    while IFS= read -r line; do
        ((line_num++))
        if [[ -z "$line" ]]; then
            continue
        fi
        if ! [[ "$line" =~ ^[^,]+,[0-9]+,[0-9]+,[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "⚠️ Malformed entry in $file at line $line_num: $line"
            errors=$((errors + 1))
        fi
    done < "$file"
    if (( errors > 0 )); then
        echo "❌ Found $errors malformed entries in $file. Please fix the file."
        return 1
    fi
    return 0
}

function login() {
    echo "======= LOGIN ======="
    read -p "Username: " uname
    read -sp "Password: " upass
    echo ""

    if [[ ! -r "$USERDB" ]]; then
        echo "❌ User database not accessible."
        exit 1
    fi

    line=$(grep "^$uname,$upass," "$USERDB")
    if [[ -n "$line" ]]; then
        role=$(echo "$line" | cut -d',' -f3)
        echo "✅ Login successful as $role"
        if [[ $role == "admin" ]]; then
            admin_panel
        else
            seller_name=$uname
            seller_panel
        fi
    else
        echo "❌ Invalid credentials."
        exit 1
    fi
}

function admin_panel() {
    if [[ -s "$DB" ]] && ! validate_db "$DB"; then
        echo "⚠️ Please fix medicines.txt before continuing."
        return 1
    fi
    while true; do
        echo "===== ADMIN PANEL ====="
        echo "1. Add New Medicine"
        echo "2. View Medicines"
        echo "3. Search Medicine"
        echo "4. Update Stock/Price"
        echo "5. Delete Medicine"
        echo "6. View Low Stock (<10)"
        echo "7. Restock Medicine"
        echo "8. Backup Data"
        echo "9. Remove Expired Medicines"
        echo "10. Logout"
        echo "========================"
        read -p "Choose option [1-10]: " opt

        case $opt in
        1)
            read -p "Name: " name
            [[ -z "$name" ]] && echo "⚠️ Medicine name cannot be empty." && continue
            read -p "Qty: " qty
            validate_number "$qty" || continue
            read -p "Price: " price
            validate_number "$price" || continue
            read -p "Expiry (YYYY-MM-DD): " exp
            validate_date "$exp" || continue
            echo "$name,$qty,$price,$exp" >> "$DB"
            echo "✅ Added $name."
            ;;
        2)
            [[ ! -s "$DB" ]] && echo "❌ No medicines in database." || { echo "📋 Medicine List:"; column -t -s, "$DB"; }
            ;;
        3)
            read -p "Search: " search
            [[ -z "$search" ]] && echo "⚠️ Search term cannot be empty." && continue
            grep -i "$search" "$DB" || echo "❌ Not found."
            ;;
        4)
            read -p "Medicine: " mname
            [[ -z "$mname" ]] && echo "⚠️ Medicine name cannot be empty." && continue
            line=$(grep -F -i "^$mname," "$DB")
            if [[ -n "$line" ]]; then
                read -p "New Qty: " qty
                validate_number "$qty" || continue
                read -p "New Price: " price
                validate_number "$price" || continue
                read -p "New Expiry: " exp
                validate_date "$exp" || continue
                escaped_mname=$(printf '%s' "$mname" | sed 's/[][\.*^$(){}?+|/\\]/\\&/g')
                sed -i "/^$escaped_mname,/d" "$DB"
                echo "$mname,$qty,$price,$exp" >> "$DB"
                echo "✅ Updated $mname."
            else
                echo "❌ Not found."
            fi
            ;;
        5)
            read -p "Medicine to delete: " del
            [[ -z "$del" ]] && echo "⚠️ Medicine name cannot be empty." && continue
            escaped_del=$(printf '%s' "$del" | sed 's/[][\.*^$(){}?+|/\\]/\\&/g')
            grep -F -i "^$escaped_del," "$DB" >/dev/null && sed -i "/^$escaped_del,/d" "$DB" && echo "✅ Deleted $del." || echo "❌ Not found."
            ;;
        6)
            [[ ! -s "$DB" ]] && echo "❌ No medicines in database." || { echo "📉 Low Stock Medicines:"; awk -F, '$2 < 10' "$DB" | column -t -s, || echo "None."; }
            ;;
        7)
            read -p "Medicine to restock: " rmed
            [[ -z "$rmed" ]] && echo "⚠️ Medicine name cannot be empty." && continue
            escaped_rmed=$(printf '%s' "$rmed" | sed 's/[][\.*^$(){}?+|/\\]/\\&/g')
            line=$(grep -F -i "^$escaped_rmed," "$DB")
            if [[ -n "$line" ]]; then
                read -p "Qty to add: " addqty
                validate_number "$addqty" || continue
                name=$(echo "$line" | cut -d',' -f1)
                qty=$(echo "$line" | cut -d',' -f2)
                price=$(echo "$line" | cut -d',' -f3)
                exp=$(echo "$line" | cut -d',' -f4)
                newqty=$((qty + addqty))
                escaped_name=$(printf '%s' "$name" | sed 's/[][\.*^$(){}?+|/\\]/\\&/g')
                sed -i "/^$escaped_name,/d" "$DB"
                echo "$name,$newqty,$price,$exp" >> "$DB"
                echo "✅ Restocked $name."
            else
                echo "❌ Not found."
            fi
            ;;
        8)
            mkdir -p backup
            backup_file="backup/medicines_$(date +%F_%H%M%S).txt"
            cp "$DB" "$backup_file" && cp "$RECEIPTS"/*.txt backup/ 2>/dev/null && echo "✅ Backup complete." || echo "⚠️ Backup failed."
            ;;
        9)
            today=$(date +%F)
            awk -F, -v today="$today" 'BEGIN{OFS=","}
            {
                cmd = "date -d \"" $4 "\" +%s"
                cmd | getline exp_secs
                close(cmd)
                cmd2 = "date -d \"" today "\" +%s"
                cmd2 | getline today_secs
                close(cmd2)
                if (exp_secs >= today_secs) print $0
            }' "$DB" > temp.txt && mv temp.txt "$DB"
            echo "✅ Expired medicines removed."
            ;;
        10)
            echo "📴 Logging out..."
            login
            ;;
        *)
            echo "⚠️ Invalid option."
            ;;
        esac
        echo ""
    done
}

function seller_panel() {
    > "$CART"
    if [[ -s "$DB" ]] && ! validate_db "$DB"; then
        echo "⚠️ Please fix medicines.txt before continuing."
        return 1
    fi
    while true; do
        echo "===== SELLER PANEL ($seller_name) ====="
        echo "1. Search & Add to Cart"
        echo "2. View Cart"
        echo "3. Sell & Generate Receipt"
        echo "4. Logout"
        echo "======================================="
        read -p "Choose option [1-4]: " opt

        case $opt in
        1)
            read -p "Enter medicine name to search: " keyword
            [[ -z "$keyword" ]] && echo "⚠️ Input cannot be empty." && continue

            match=$(awk -F, -v key="$keyword" 'BEGIN{IGNORECASE=1}
            tolower($1) ~ tolower(key) { print; exit }' "$DB")

            if [[ -z "$match" ]]; then
                echo "❌ No medicine found matching '$keyword'."
                echo "📋 Available medicines:"
                cut -d',' -f1 "$DB"
                continue
            fi

            IFS=',' read -r name qty price exp <<< "$match"
            echo "📋 Match found: $name - Qty: $qty - Price: $price BDT - Exp: $exp"

            read -p "Qty to sell: " sellqty
            validate_number "$sellqty" || continue

            if (( sellqty > qty )); then
                echo "⚠️ Not enough stock!"
            else
                remain=$((qty - sellqty))
                escaped_name=$(printf '%s' "$name" | sed 's/[][\.*^$(){}?+|/\\]/\\&/g')
                sed -i "/^$escaped_name,/d" "$DB"
                echo "$name,$remain,$price,$exp" >> "$DB"
                echo "$name,$sellqty,$price" >> "$CART"
                echo "✅ Added $sellqty of '$name' to cart."
            fi
            ;;
        2)
            [[ ! -s "$CART" ]] && echo "❌ Cart is empty." || { echo "🛒 Cart:"; column -t -s, "$CART"; }
            ;;
        3)
            [[ ! -s "$CART" ]] && echo "⚠️ Cart is empty. Add items to sell." && continue
            today=$(date +%F)
            now=$(date)
            receipt_file="$RECEIPTS/receipt_${receipt_id}.txt"
            daily_file="$RECEIPTS/sales_${today}.txt"

            {
                echo "========= RECEIPT ========="
                echo "Seller: $seller_name"
                echo "Date: $now"
                echo "---------------------------"
                printf "%-15s %-10s %-10s %-10s\n" "Medicine" "Qty" "Price" "Subtotal"
            } > "$receipt_file"

            [[ ! -f "$daily_file" ]] && {
                echo "========= DAILY SALES ($today) ========="
                echo "Date: $now"
                echo "---------------------------"
                printf "%-15s %-10s %-10s %-10s\n" "Medicine" "Qty" "Price" "Subtotal"
            } > "$daily_file"

            total=0
            while IFS=',' read -r cname cqty cprice; do
                subtotal=$((cqty * cprice))
                printf "%-15s %-10s %-10s %-10s\n" "$cname" "$cqty" "$cprice" "$subtotal" >> "$receipt_file"
                printf "%-15s %-10s %-10s %-10s\n" "$cname" "$cqty" "$cprice" "$subtotal" >> "$daily_file"
                total=$((total + subtotal))
            done < "$CART"

            {
                echo "---------------------------"
                echo "Total: $total BDT"
                echo "🙏 Thank you!"
            } >> "$receipt_file"

            {
                echo "---------------------------"
                echo "Total: $total BDT"
            } >> "$daily_file"

            cat "$receipt_file"
            > "$CART"
            receipt_id=$((receipt_id + 1))
            ;;
        4)
            echo "📴 Logging out..."
            login
            ;;
        *)
            echo "⚠️ Invalid option."
            ;;
        esac
        echo ""
    done
}

# Start the script with login
login
