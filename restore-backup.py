import sqlite3
import json
import os

db_file = '/etc/x-ui/x-ui.db'
backup_dir = '/root/speedtest_ban_backup'
backup_file = os.path.join(backup_dir, 'xrayTemplateConfig_backup.json')

def restore_xray_template_config_from_backup():
    try:
        # Read the content of the backup file
        with open(backup_file, 'r') as file:
            backup_content = file.read()

        # Connect to the SQLite database
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()

        # Update the 'xrayTemplateConfig' value in the database
        cursor.execute("UPDATE settings SET value = ? WHERE key = 'xrayTemplateConfig';", (backup_content,))
        conn.commit()

        cursor.close()
        conn.close()

        print(f"Restored xrayTemplateConfig from {backup_file}.")

    except IOError as e:
        print(f"Error reading backup file {backup_file}: {e}")
    except sqlite3.Error as e:
        print(f"SQLite error: {e}")

if __name__ == "__main__":
    restore_xray_template_config_from_backup()
