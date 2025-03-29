# Fix Neko DLL Issue

If you encounter issues installing `haxelib` because Neko is not working, this guide will help you resolve the problem.

1. Visit the [Neko GitHub page](https://github.com/HaxeFoundation/neko):  
   ![Neko GitHub Page](image-3.png)

2. Navigate to the "Releases" tab:  
   ![Releases Tab](image-4.png)

3. Choose the version you want to download. It is highly recommended to use the latest version:  
   ![Version Selection](image-5.png)  
   - For 64-bit computers, download `neko-<version>-win64.zip`.  
   - For 32-bit computers, download `neko-<version>-win.zip`.

4. Extract the downloaded file to a directory of your choice. For example, you can extract it to:  
   ![Example Path](image-6.png)

5. Open the "View advanced system settings" window:  
   ![Advanced System Settings](image-7.png)

6. Click on "Environment Variables":  
   ![Environment Variables](image-8.png)

7. Under "User variables for Admin", select the `Path` variable and click "Edit":  
    ![Edit Path Variable](image-10.png)  
    - Add the path to the directory where you extracted Neko. For example: `C:\path\to\neko`.

8. Restart your terminal and try again. :D