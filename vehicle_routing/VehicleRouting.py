
import sys

def main():
    in_file = sys.argv[1]
    print(in_file)
    try:
        in_file = sys.argv[1]
    except IndexError:
        print("Nothing to read")

if __name__ == "__main__":
    main()