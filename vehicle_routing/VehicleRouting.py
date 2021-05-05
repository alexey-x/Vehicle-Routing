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
    DataWriter(task, out_file).save()


def main():
    in_file = sys.argv[1]
    in_path, in_file_name = path.split(in_file)
    out_file = path.join(in_path, "output_" + in_file_name)
    print(f"Input file -> {in_file}")
    print(f"Output file -> {out_file}")

    try:
        in_file = sys.argv[1]
        run(in_file, out_file)
    except IndexError:
        print("Nothing to read")


if __name__ == "__main__":
    main()
