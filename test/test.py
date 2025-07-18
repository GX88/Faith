import json
import sys
import argparse

# 读取json文件
def process_json(file_path):
    # 打开并加载JSON文件
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

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
    parser = argparse.ArgumentParser(description="处理 JSON 文件，去除 ind=12345679 的图层")
    parser.add_argument('input', help='输入的 JSON 文件路径')
    parser.add_argument('output', help='输出的 JSON 文件路径')
    parser.add_argument('--compress', action='store_true', default=True, help='是否压缩输出（默认压缩）')
    parser.add_argument('--pretty', action='store_true', help='格式化输出（不压缩）')
    args = parser.parse_args()

    input_file_path = args.input
    output_file_path = args.output
    compress = not args.pretty  # --pretty 优先级高于 --compress

    print(f"正在处理文件: {input_file_path}")
    # 处理json文件
    processed_data = process_json(input_file_path)

    # 输出处理后的数据到文件
    write_json(output_file_path, processed_data, compress)
    print(f"处理后的json文件已保存到 {output_file_path}")

# 启动程序
if __name__ == "__main__":
    main()