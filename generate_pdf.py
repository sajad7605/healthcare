import subprocess
import os
import sys

def main():
    print("شروع تولید فایل PDF از مستند پروژه...")
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    html_path = os.path.join(current_dir, "doc.html")
    pdf_path = os.path.join(current_dir, "ToothBuddy_Documentation.pdf")
    
    if not os.path.exists(html_path):
        print(f"خطا: فایل {html_path} پیدا نشد!")
        sys.exit(1)
        
    chromium_path = "/usr/bin/chromium"
    if not os.path.exists(chromium_path):
        print(f"خطا: کرومیوم در مسیر {chromium_path} یافت نشد!")
        sys.exit(1)
        
    cmd = [
        chromium_path,
        "--headless",
        "--disable-gpu",
        "--no-sandbox",
        f"--print-to-pdf={pdf_path}",
        html_path
    ]
    
    print(f"در حال اجرای دستور: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        print("دستور با موفقیت اجرا شد.")
        if os.path.exists(pdf_path):
            print(f"فایل PDF با موفقیت در مسیر زیر ساخته شد:\n{pdf_path}")
            size_mb = os.path.getsize(pdf_path) / (1024 * 1024)
            print(f"حجم فایل: {size_mb:.2f} مگابایت")
        else:
            print("خطا: دستور اجرا شد اما فایل PDF ساخته نشد!")
            sys.exit(1)
    except subprocess.CalledProcessError as e:
        print("خطا در اجرای کرومیوم:")
        print(e.stdout)
        print(e.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
