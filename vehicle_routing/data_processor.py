from convert_dataframe import convert_dataframe_to_dict
from convert_dataframe import convert_dataframe_to_set


class DataProcessor:
    def __init__(self, reader):
        self.parameters = reader.read_parameters()
        self.cities = reader.read_cities()
        self.vehicles = reader.read_vehicles()
        self.routes = reader.read_routes()
        self.orders = reader.read_orders()

    def get_max_period(self) -> int:
        return self.parameters.loc["maxPeriod"].ParamValue

    def get_depot(self) -> str:
        return self.cities["City"][0]

    def get_final_trip(self) -> int:
        return self.get_trips()[-1]

    def get_trips(self) -> list:
        tot_demand = self.orders["Demand"].sum()
        tot_capacity = self.vehicles["Capacity"].sum()
        return list(range(1, tot_demand // tot_capacity + 2))

    def get_cities(self) -> set:
        return self.get_all_cities().difference(set([self.get_depot()]))

    def get_all_cities(self) -> set:
        return set(self.cities["City"].values)

    def get_routes(self) -> set:
        return convert_dataframe_to_set(self.routes, ["From", "To"], "Distance")

    def get_route_distance(self) -> dict:
        return convert_dataframe_to_dict(self.routes, ["From", "To"], "Distance")

    def get_route_time(self) -> dict:
        return convert_dataframe_to_dict(self.routes, ["From", "To"], "Time")

    def get_cars(self) -> dict():
        return convert_dataframe_to_set(self.vehicles, ["CarName"], "Price_per_km")

    def get_car_capacity(self) -> dict:
        return convert_dataframe_to_dict(self.vehicles, ["CarName"], "Capacity")

    def get_car_price(self) -> dict:
        return convert_dataframe_to_dict(self.vehicles, ["CarName"], "Price_per_km")

    def get_order_deliver_from(self) -> dict:
        return convert_dataframe_to_dict(self.orders, ["City"], "Deliver_from")

    def get_order_deliver_to(self) -> dict:
        return convert_dataframe_to_dict(self.orders, ["City"], "Deliver_to")

    def get_order_demand(self) -> dict:
        return convert_dataframe_to_dict(self.orders, ["City"], "Demand")

    def get_order_price(self) -> dict:
        return convert_dataframe_to_dict(self.orders, ["City"], "Price_per_unit")


if __name__ == "__main__":
    import sys
    from data_reader import DataReader

    in_file = sys.argv[1]
    print(in_file)
    reader = DataReader(in_file)
    processor = DataProcessor(reader)

    print(processor.get_all_cities())
    print(processor.get_cities())
    print(processor.get_order_deliver_from())
    print(processor.get_order_price())
