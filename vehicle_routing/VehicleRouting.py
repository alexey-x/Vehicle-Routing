import sys
from os import path

from data_reader import DataReader
from data_processor import DataProcessor
from data_writer import DataWriter
from linprog_maker import LinProgMaker


def run(in_file: str, out_file: str) -> None:
    reader = DataReader(in_file)
    processor = DataProcessor(reader)
    task = LinProgMaker(processor)
    task.solve()
    writer = DataWriter(task, out_file)
    writer.save()

    print(f"Sales profit = {writer.calc_sales_profit()}")
    print(f"Delivery cost = {writer.calc_delivery_cost()}")


def get_out_file_name(in_file: str) -> str:
    in_path, in_file_name = path.split(in_file)
    return path.join(in_path, "output_" + in_file_name)

def main():
    in_file = sys.argv[1]
    out_file = get_out_file_name(in_file)

    print(f"Input file -> {in_file}")
    print(f"Output file -> {out_file}")

    try:
        in_file = sys.argv[1]
        run(in_file, out_file)
    except IndexError:
        print("Nothing to read")


if __name__ == "__main__":
    main()
