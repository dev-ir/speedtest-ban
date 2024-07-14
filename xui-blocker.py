import sqlite3
import json
import os

db_file = '/etc/x-ui/x-ui.db'
sites_file = '/root/speedtest_sites.dat'
backup_dir = '/root/speedtest_ban_backup'
backup_file = os.path.join(backup_dir, 'xrayTemplateConfig_backup.txt')

def get_sites_from_file(file_path):
    try:
        with open(file_path, 'r') as file:
            sites = [line.strip() for line in file if line.strip()]
        return sites
    except IOError as e:
        print(f"Error reading file {file_path}: {e}")
        return []

def backup_xray_template_config(value):
    try:
        os.makedirs(backup_dir, exist_ok=True)
        # Convert value to JSON string
        json_value = json.dumps(value)
        with open(backup_file, 'w') as file:
            file.write(json_value)
        print(f"Backup of xrayTemplateConfig saved to {backup_file}.")
    except IOError as e:
        print(f"Error writing to backup file {backup_file}: {e}")

def add_sites_to_blocklist():
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()

        cursor.execute("SELECT value FROM settings WHERE key = 'xrayTemplateConfig';")
        row = cursor.fetchone()

        if row:
            xray_template_config_json = row[0]
            backup_xray_template_config(xray_template_config_json)

            xray_template_config = json.loads(xray_template_config_json)

            if 'routing' not in xray_template_config:
                xray_template_config['routing'] = {}

            if 'rules' not in xray_template_config['routing']:
                xray_template_config['routing']['rules'] = []
            else:
                xray_template_config['routing']['rules'] = [rule for rule in xray_template_config['routing']['rules'] if rule.get('type') != 'field' or 'domain' not in rule or 'fast.com' not in rule['domain']]

            sites = get_sites_from_file(sites_file)

            new_rule = {
                "type": "field",
                "outboundTag": "blocked",
                "domain": sites
            }
            xray_template_config['routing']['rules'].append(new_rule)
            print("Added new block rule for sites.")
            
            updated_xray_template_config_json = json.dumps(xray_template_config)
            cursor.execute("UPDATE settings SET value = ? WHERE key = 'xrayTemplateConfig';", (updated_xray_template_config_json,))
            conn.commit()

        else:
            print("No row found with key 'xrayTemplateConfig'.")

        cursor.close()
        conn.close()

    except sqlite3.Error as e:
        print(f"SQLite error: {e}")

if __name__ == "__main__":
    add_sites_to_blocklist()
