import os

folder_path = '/public/home/baoqi/mm10_new/raw_qu/fpkm'
output_file = 'merged_output.txt'



files = [os.path.join(folder_path, f) for f in os.listdir(folder_path) if f.endswith('.fpkm2')]


with open(os.path.join(folder_path, output_file), 'w') as output:

    output.write('ID\t' + '\t'.join([os.path.basename(file)[:-36] for file in files]) + '\n')


    id_dict = {}


    for file in files:
        with open(file, 'r') as f:
#            next(f)



            for line in f:
                parts = line.strip().split('\t')
                id_value = parts[0]
                expression = parts[1]

                if id_value in id_dict:
                    id_dict[id_value].append(expression)
                else:
                    id_dict[id_value] = [expression]


    for id_value, expressions in id_dict.items():
        output.write(id_value + '\t' + '\t'.join(expressions) + '\n')


print(f'Merged file saved as {output_file}')
