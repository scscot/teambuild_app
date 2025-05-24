# FINAL PATCHED — cleanup_auth_users.py (Delete All Auth Users Except Admin UID)

import firebase_admin
from firebase_admin import credentials, auth

# Initialize Firebase Admin SDK
cred = credentials.Certificate("/Users/sscott/Desktop/tbp/secrets/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

# Reserved admin UID to preserve
ADMIN_UID = "KJ8uFnlhKhWgBa4NVcwT"

print("\n🧹 Starting Firebase Auth user cleanup (excluding admin)...\n")
count = 0

# List all users in batches
page = auth.list_users()
while page:
    for user in page.users:
        if user.uid != ADMIN_UID:
            try:
                auth.delete_user(user.uid)
                print(f"🧹 Deleted Auth user: {user.uid}")
                count += 1
            except Exception as e:
                print(f"❌ Error deleting Auth user {user.uid}: {e}")
    page = page.get_next_page()

print(f"\n✅ Auth cleanup complete. Total users deleted: {count}\n")
