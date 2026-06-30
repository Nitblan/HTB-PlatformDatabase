# Setup Guide

## Requirements

- MySQL 8.0+ (or MariaDB 10.6+)
- Git


### 1. Clone the repository
\`\`\`bash
git clone https://github.com/Nitblan/HTB-PlatformDatabase.git
cd HTB-PlatformDatabase
\`\`\`

### 2. Connect to MySQL
\`\`\`bash
mysql -u root -p
# Enter your password when prompted
\`\`\`

### 3. Load the schema
\`\`\`bash
mysql -u root -p < schema.sql
\`\`\`

### 4. Verify installation
\`\`\`bash
mysql -u root -p -e "USE htb_platform; SHOW TABLES;"
\`\`\`

important to verify correclty the installation testing the views

\`\`\`bash
mysql -u root -p htb_platform -e "SELECT * FROM v_ranking_usuario_global LIMIT 5;"
mysql -u root -p htb_platform -e "SELECT * FROM v_ranking_maquina_dificultad LIMIT 5;"
\`\`\`

## Troubleshooting

**Error: "Access denied"**
- Make sure you're using the correct password
- Default user is usually `root`

**Error: "Database already exists"**
- The script includes `CREATE DATABASE IF NOT EXISTS`
- Safe to run multiple times

**Error: "Foreign key constraint failed"**
- Make sure you're using InnoDB engine (we do)
- Try loading schema from clean MySQL instance
