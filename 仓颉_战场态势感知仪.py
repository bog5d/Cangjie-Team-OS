# -*- coding: utf-8 -*-
"""
【文件名】：仓颉_战场态势感知仪.py
【功  能】：
    1. 深度扫描当前目录结构。
    2. 读取索引文件和发送单的核心内容。
    3. 生成 JSON 格式的情报，用于同步给 AI 助手。
【适用方】：王总 & 协作 AI
"""
import os
import json
import time

# 扫描目标（当前目录）
TARGET_ROOT = os.getcwd()
IGNORE_DIRS = {'logs', 'dist', 'build', '.git', '__pycache__', 'venv', '.idea', '交付给团队_最终版', '交付_新人标准开荒包_v1.0'}

def get_file_info(filepath):
    """获取文件基本信息"""
    stats = os.stat(filepath)
    # 修改时间
    mtime = time.strftime('%Y-%m-%d', time.localtime(stats.st_mtime))
    return mtime

def read_content_head(filepath):
    """读取文本文件头部（前20行）"""
    preview = []
    encodings = ['utf-8', 'gbk', 'gb18030']
    for enc in encodings:
        try:
            with open(filepath, 'r', encoding=enc, errors='ignore') as f:
                lines = f.readlines()
            for line in lines:
                line = line.strip()
                if set(line) <= {'=', '-', ' '} and len(line) > 5:
                    preview.append(f"[分割线]: {line}")
                    break
                if line:
                    preview.append(line)
                if len(preview) >= 20:
                    preview.append("[...已截断...]")
                    break
            return preview
        except: continue
    return ["(读取失败)"]

def run_scan():
    data = {
        "meta": {"root": TARGET_ROOT, "scan_time": time.strftime('%Y-%m-%d %H:%M:%S')},
        "files": []
    }
    
    print(f" 正在进行战场态势感知: {TARGET_ROOT} ...")
    
    for root, dirs, files in os.walk(TARGET_ROOT):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        for file in files:
            # 排除自己和生成的exe
            if "态势感知仪" in file or file.endswith(".exe"): continue
            
            full_path = os.path.join(root, file)
            rel_path = full_path.replace(TARGET_ROOT, "")
            
            file_item = {
                "path": rel_path,
                "name": file,
                "last_modified": get_file_info(full_path)
            }
            
            # 重点识别索引和发送单
            if file.startswith("00_") and file.endswith(".txt"):
                file_item["type"] = "核心档案"
                file_item["content"] = read_content_head(full_path)
            elif file.endswith(".py"):
                file_item["type"] = "代码脚本"
            elif file.endswith(".ps1"):
                file_item["type"] = "工具脚本"
            else:
                file_item["type"] = "普通文件"
                
            data["files"].append(file_item)
            
    return data

if __name__ == "__main__":
    result = run_scan()
    print("\n" + "="*20 + " 态势感知完成，请复制下方内容 " + "="*20)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    print("="*20 + " 复制结束 " + "="*20 + "\n")
    
    # 只有在双击运行时才暂停
    if os.name == 'nt' and 'PROMPT' not in os.environ:
        input("按回车键退出...")