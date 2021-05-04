import pandas as pd


class DataReader:
    def __init__(self, in_file: str) -> None:
        self.in_file = in_file

    def read_parameters(self) -> pd.DataFrame:
        sheet_name = "Parameters"
        return pd.read_excel(self.in_file, sheet_name=sheet_name).set_index("ParamName")

    def read_cities(self) -> pd.DataFrame:
        sheet_name = "Cities"
        return pd.read_excel(self.in_file, sheet_name=sheet_name)

    def read_vehicles(self) -> pd.DataFrame:
        sheet_name = "Vehicles"
        return pd.read_excel(self.in_file, sheet_name=sheet_name)

    def read_orders(self) -> pd.DataFrame:
        sheet_name = "Orders"
        return pd.read_excel(self.in_file, sheet_name=sheet_name)

    def read_routes(self) -> pd.DataFrame:
        sheet_name = "Routes"
        return pd.read_excel(self.in_file, sheet_name=sheet_name)


if __name__ == "__main__":
    import sys

    in_file = sys.argv[1]
    print(in_file)
    reader = DataReader(in_file)
    print(reader.read_parameters())
