import sqlite3
import json

db_file = '/etc/x-ui/x-ui.db'
sites_file = '/root/speedtest_sites.dat'

def get_sites_from_file(file_path):
    try:
        with open(file_path, 'r') as file:
            sites = [line.strip() for line in file if line.strip()]
        return sites
    except IOError as e:
        print(f"Error reading file {file_path}: {e}")
        return []

def add_sites_to_blocklist():
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM settings WHERE key = 'xrayTemplateConfig';")
        row = cursor.fetchone()

        if row:
            xray_template_config_json = row[0]
            xray_template_config = json.loads(xray_template_config_json)

            if 'routing' not in xray_template_config:
                xray_template_config['routing'] = {}
            
            if 'rules' not in xray_template_config['routing']:
                xray_template_config['routing']['rules'] = []
            elif not isinstance(xray_template_config['routing']['rules'], list):
                xray_template_config['routing']['rules'] = []

            sites = get_sites_from_file(sites_file)

            block_rule = None
            for rule in xray_template_config['routing']['rules']:
                if rule.get("type") == "field" and rule.get("outboundTag") == "blocked":
                    block_rule = rule
                    break

            if block_rule:
                if 'domain' not in block_rule:
                    block_rule['domain'] = []
                block_rule['domain'].extend(sites)
                print("Added sites to the existing block rule.")
            else:
                new_rule = {
                    "type": "field",
                    "outboundTag": "blocked",
                    "domain": sites
                }
                xray_template_config['routing']['rules'].append(new_rule)
                print("Added sites to a new block rule.")

            updated_xray_template_config_json = json.dumps(xray_template_config, indent=2)
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
