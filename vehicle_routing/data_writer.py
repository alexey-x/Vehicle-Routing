import pandas as pd


class DataWriter:
    def __init__(self, task, out_file):
        self.writer = pd.ExcelWriter(out_file, engine="xlsxwriter")
        self.task = task

    def make_vehicle_routing(self) -> pd.DataFrame:
        cols = [
            "CarName",
            "TripNumber",
            "City_From",
            "City_To",
            "Delivered",
            "Lack",
            "DepatureTime",
            "ArrivalTime",
            "Deliver_From",
            "Deliver_To",
        ]
        result = pd.DataFrame(columns=cols)
        row_number = 0
        for k in self.task.cars:
            for n in self.task.trips:
                for i, j in self.task.routes:
                    if self.task.x[k, n, (i, j)].value() == 0:
                        continue
                    result.loc[row_number, cols] = (
                        k,
                        n,
                        i,
                        j,
                        self.task.d[k, n, j].value() if j != self.task.DEPOT else None,
                        None,
                        self.task.t[k, n, i].value(),
                        self.task.t[k, n, j].value()
                        if j != self.task.DEPOT
                        else self.task.te[k, n].value(),
                        self.task.order_deliver_from[j]
                        if j in self.task.cities
                        else None,
                        self.task.order_deliver_to[j]
                        if j in self.task.cities
                        else None,
                    )
                    row_number += 1

        result = result.sort_values(by=["CarName", "TripNumber", "ArrivalTime"])
        for i in self.task.cities:
            curr_lack = self.task.order_demand[i]
            for line in result[result["City_To"] == i].itertuples():
                curr_lack -= line.Delivered
                result.loc[line.Index, "Lack"] = curr_lack
        return result

    def make_delivery(self) -> pd.DataFrame:
        cols = ["City", "Delivered", "Demand", "Lack"]
        delivery = pd.DataFrame(columns=cols)
        row_number = 0
        for i in self.task.cities:
            delivered = sum(
                (
                    self.task.d[k, n, i].value()
                    for k in self.task.cars
                    for n in self.task.trips
                )
            )
            delivery.loc[row_number, cols] = (
                i,
                delivered,
                self.task.order_demand[i],
                self.task.lack[i].value(),
            )
            row_number += 1
        return delivery

    def save(self) -> None:

        self.make_vehicle_routing().to_excel(
            self.writer, sheet_name="VehicleRouting", index=False
        )
        self.make_delivery().to_excel(
            self.writer, sheet_name="DeliveriesLack", index=False
        )

        self.writer.save()
        self.writer.close()

    def write_lp_model(self, file_name="model.lp") -> None:
        self.task.write(file_name)


if __name__ == "__main__":
    print("data_writer")
