import json
import sys
import argparse
import requests
import os
from urllib.parse import urlparse

# 从URL下载JSON文件
def download_json(url):
    try:
        print(f"正在从URL下载: {url}")
        response = requests.get(url, timeout=30)
        response.raise_for_status()  # 检查HTTP错误
        
        # 尝试解析JSON确保文件有效
        data = response.json()
        print(f"成功下载JSON文件，大小: {len(response.content)} 字节")
        return data
    except requests.exceptions.RequestException as e:
        print(f"下载失败: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"JSON格式错误: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"下载错误: {e}")
        sys.exit(1)

# 从本地文件读取JSON
def read_json_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data
    except FileNotFoundError:
        print(f"文件未找到: {file_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"JSON格式错误: {e}")
        sys.exit(1)

# 判断输入是URL还是本地文件路径
def is_url(string):
    try:
        result = urlparse(string)
        return all([result.scheme, result.netloc])
    except ValueError:
        return False

# 读取json文件
def process_json(input_source):
    # 判断输入是URL还是文件路径
    if is_url(input_source):
        data = download_json(input_source)
    else:
        data = read_json_file(input_source)

    found_watermark = False
    if 'layers' in data:
        original_length = len(data['layers'])
        data['layers'] = [layer for layer in data['layers'] if layer.get('ind') != 12345679]
        new_length = len(data['layers'])
        
        if original_length != new_length:
            found_watermark = True
            print(f"找到并删除了 {original_length - new_length} 个水印图层 (ind=12345679)")
        else:
            print("未找到水印图层 (ind=12345679)")

    # 返回处理后的数据
    return data

# 写入新的json文件
def write_json(output_file_path, data, compress=True):
    with open(output_file_path, 'w', encoding='utf-8') as f:
        if compress:
            # 压缩模式：无缩进，无空格
            json.dump(data, f, ensure_ascii=False, separators=(',', ':'))
            print("文件已压缩保存")
        else:
            # 格式化模式：带缩进
            json.dump(data, f, indent=4, ensure_ascii=False)
            print("文件已格式化保存")

# 主程序
def main():
    parser = argparse.ArgumentParser(description="处理 JSON 文件，去除 ind=12345679 的图层。支持本地文件或URL下载")
    parser.add_argument('input', help='输入的 JSON 文件路径或URL')
    parser.add_argument('output', help='输出的 JSON 文件路径')
    parser.add_argument('--compress', action='store_true', default=True, help='是否压缩输出（默认压缩）')
    parser.add_argument('--pretty', action='store_true', help='格式化输出（不压缩）')
    args = parser.parse_args()

    input_source = args.input
    output_file_path = args.output
    compress = not args.pretty  # --pretty 优先级高于 --compress

    print(f"正在处理: {input_source}")
    # 处理json文件（支持URL下载或本地文件）
    processed_data = process_json(input_source)

    # 输出处理后的数据到文件
    write_json(output_file_path, processed_data, compress)
    print(f"处理后的json文件已保存到 {output_file_path}")

# 启动程序
if __name__ == "__main__":
    main()