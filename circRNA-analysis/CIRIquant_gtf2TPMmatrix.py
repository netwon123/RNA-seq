import sys
import os

def extract_circ_ids(gtf_file):
    """
    从 GTF 文件中提取 circ_id、第六列的数据，并计算 circ_id 的长度和 TPM。
    """
    try:
        data = []
        total_rpm_over_l = 0  # 用于计算 F

        with open(gtf_file, "r") as file:
            for line in file:
                # 跳过注释行
                if line.startswith("#"):
                    continue
                
                # 分割行
                fields = line.strip().split("\t")
                if len(fields) < 9:
                    continue
                
                attributes = fields[8].split("; ")
                
                # 提取 circ_id
                circ_id = None
                for attr in attributes:
                    if attr.startswith("circ_id"):
                        circ_id = attr.split('"')[1]
                        break
                
                # 计算 circ_id 的长度
                length = None
                if circ_id and "|" in circ_id:
                    parts = circ_id.split(":")[1].split("|")
                    if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
                        length = int(parts[1]) - int(parts[0])
                
                # 计算 RPM
                rpm = None
                if length is not None:
                    rpm = float(fields[5]) * 1_000_000
                    total_rpm_over_l += rpm / length
                
                # 存储数据以便后续计算 TPM
                if circ_id and length is not None and rpm is not None:
                    data.append((circ_id, float(fields[5]), length, rpm))
        
        # 计算 F
        if total_rpm_over_l == 0:
            print(f"错误：计算 F 时发生除零错误 (文件: {gtf_file})。")
            return {}
        
        F = total_rpm_over_l
        
        # 计算 TPM
        results = {}
        for circ_id, sixth_col, length, rpm in data:
            tpm = (rpm / F) * 1_000_000
            results[circ_id] = tpm
        
        return results
    except FileNotFoundError:
        print(f"错误：文件 {gtf_file} 未找到。")
        return {}
    except Exception as e:
        print(f"发生错误（文件: {gtf_file}）：{e}")
        return {}

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("用法: python script.py <input_folder> <output.txt>")
    else:
        input_folder = sys.argv[1]
        output_file = sys.argv[2]
        
        all_results = {}
        sample_names = []
        
        for filename in os.listdir(input_folder):
            if filename.endswith(".gtf"):
                sample_name = filename.rsplit(".", 1)[0]  # 以文件名作为样本名
                sample_names.append(sample_name)
                file_path = os.path.join(input_folder, filename)
                
                sample_data = extract_circ_ids(file_path)
                for circ_id, tpm in sample_data.items():
                    if circ_id not in all_results:
                        all_results[circ_id] = {}
                    all_results[circ_id][sample_name] = tpm
        
        # 写入合并结果
        with open(output_file, "w") as out_file:
            header = ["circ_id"] + sample_names
            out_file.write("\t".join(header) + "\n")
            
            for circ_id in all_results:
                row = [circ_id]
                for sample in sample_names:
                    if sample in all_results[circ_id]:
                        row.append(str(all_results[circ_id][sample]))
                    else:
                        row.append("0")
                out_file.write("\t".join(row) + "\n")
        
        print(f"合并结果已保存到 {output_file}")
