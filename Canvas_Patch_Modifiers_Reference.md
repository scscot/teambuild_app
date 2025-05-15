# Canvas-Based Patch Prompt Modifiers

Examples:

Apply Patch 3 to edit_profile_screen.dart. Show the full patch first for review. Only insert after I confirm.

Open the canvas for user_model.dart now. Show me the full contents of the file. Then only apply Patch Fix inside the canvas using the agreed-upon canvas-based methodology, with full cross-file consistency checks.

Open the canvas for session_manager.dart now. Show me the full contents of the file. Then apply patch to fix the Xcode build error inside the canvas using the agreed-upon canvas-based methodology, with full cross-file consistency checks.

Open the canvas for profile_screen.dart now. Show me the full contents of the file. Then apply Patch 3B inside the canvas using the agreed-upon canvas-based methodology, with full cross-file consistency checks.

Use the following modifiers to customize how patches are handled inside the canvas-based workflow:

- Show the full patch first for review.
- Only insert after I confirm.
- Apply the patch immediately inside the canvas.
- Before applying, confirm whether the method <methodName>() is used in this file or others.
- Also list any other canvased files that rely on this one.
- Only apply the patch if no breaking changes are detected.
- Apply the patch and show the affected lines with // PATCH START and // PATCH END clearly marked.
- Before patching, check for missing imports or dependencies across canvased files.
- Run a cross-canvas check to confirm all method calls are synchronized.
- List all functions in the file before patching.
- Display the filename and patch summary before inserting anything.


Open the canvas for user_model.dart now.
Show me the full contents of the file.
Before patching, check for missing imports or dependencies across canvased files.
Run a cross-canvas check to confirm all method calls are synchronized.
Apply Patch 1 immediately inside the canvas.