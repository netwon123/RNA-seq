def extract_gene_transcript_ids(gtf_file, output_file):
    """
    从 GTF 文件中提取 gene_id 和 transcript_id，并保存到输出文件中。

    参数:
        gtf_file (str): 输入的 GTF 文件路径。
        output_file (str): 输出的文件路径。
    """
    with open(gtf_file, 'r') as gtf, open(output_file, 'w') as out:
        # 写入输出文件的表头
        out.write("gene_id\ttranscript_id\n")

        for line in gtf:
            # 跳过注释行
            if line.startswith('#'):
                continue

            # 分割每一行
            fields = line.strip().split('\t')
            if len(fields) < 9:  # 确保行格式正确
                continue

            # 提取 attributes 字段
            attributes = fields[8]

            # 解析 attributes 字段
            attr_dict = {}
            for attr in attributes.split(';'):
                attr = attr.strip()
                if not attr:
                    continue
                # 分割键值对
                if ' ' in attr:
                    key, value = attr.split(' ', 1)
                    attr_dict[key] = value.strip('"')

            # 提取 gene_id 和 transcript_id
            gene_id = attr_dict.get('gene_id', 'NA')
            transcript_id = attr_dict.get('transcript_id', 'NA')

            # 如果 transcript_id 存在，则写入输出文件
            if transcript_id != 'NA':
                out.write(f"{gene_id}\t{transcript_id}\n")

# 使用示例
gtf_file = "Ovis_aries_rambouillet.ARS-UI_Ramb_v2.0.113.chr.gtf"  # 输入的 GTF 文件路径
output_file = "gene_transcript_ids.txt"  # 输出的文件路径
extract_gene_transcript_ids(gtf_file, output_file)
print(f"提取完成，结果已保存到 {output_file}")
