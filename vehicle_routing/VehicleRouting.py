import sys

from data_reader import DataReader
from data_processor import DataProcessor
from data_writer import DataWriter
from linprog_maker import LinProgMaker


def run(in_file: str) -> None:
    reader = DataReader(in_file)
    processor = DataProcessor(reader)
    task = LinProgMaker(processor)
    task.solve(plp.PULP_CBC_CMD(msg=True))


def main():
    in_file = sys.argv[1]
    print(in_file)
    try:
        in_file = sys.argv[1]
        run(in_file)
    except IndexError:
        print("Nothing to read")


if __name__ == "__main__":
    main()
