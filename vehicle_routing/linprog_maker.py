import pulp as plp


class LinProgMaker:
    def __init__(self, processor):
        self.LACK_PUNISHMENT = 100
        self.init_const(processor)

        self.prob = plp.LpProblem("VRPTW", plp.LpMaximize)

        self.init_decision_variables()

    def solve(self) -> None:
        self.obective()

        # time constraints
        self.ct_start_at_time_zero()

        self.ct_next_start_after_finish()

        self.ct_end_all_trips()

        self.ct_time_along_edge()

        self.ct_time_windows()

        # demand - capacity constraints
        self.ct_visit_city_atleast_once()

        self.ct_demand()

        self.ct_capacity()

        self.prob.solve(plp.PULP_CBC_CMD(msg=True))

        self.status = plp.LpStatus[self.prob.status]
        self.objective_value = plp.value(self.prob.objective)

    def init_const(self, processor) -> None:
        self.MAX_PERIOD = processor.get_max_period()
        self.DEPOT = processor.get_depot()
        self.FINAL_TRIP = processor.get_final_trip()
        self.cities = processor.get_cities()
        self.all_cities = processor.get_all_cities()
        self.trips = processor.get_trips()
        self.routes = processor.get_routes()
        self.route_distance = processor.get_route_distance()
        self.route_time = processor.get_route_time()
        self.cars = processor.get_cars()
        self.car_capacity = processor.get_car_capacity()
        self.car_price = processor.get_car_price()
        self.order_deliver_from = processor.get_order_deliver_from()
        self.order_deliver_to = processor.get_order_deliver_to()
        self.order_demand = processor.get_order_demand()
        self.order_price = processor.get_order_price()

    def init_decision_variables(self) -> None:
        self.x = plp.LpVariable.dicts(
            "x",
            [(k, n, r) for k in self.cars for n in self.trips for r in self.routes],
            cat=plp.LpBinary,
        )
        self.y = plp.LpVariable.dicts(
            "y",
            [(k, n, i) for k in self.cars for n in self.trips for i in self.all_cities],
            cat=plp.LpBinary,
        )
        self.d = plp.LpVariable.dicts(
            "d",
            [(k, n, i) for k in self.cars for n in self.trips for i in self.cities],
            cat=plp.LpContinuous,
            lowBound=0,
        )

        self.lack = plp.LpVariable.dicts(
            "lack", [i for i in self.cities], cat=plp.LpContinuous, lowBound=0
        )
        self.t = plp.LpVariable.dicts(
            "t",
            [(k, n, i) for k in self.cars for n in self.trips for i in self.all_cities],
            cat=plp.LpContinuous,
            lowBound=0,
        )
        # final arrival time
        self.te = plp.LpVariable.dicts(
            "te",
            [(k, n) for k in self.cars for n in self.trips],
            cat=plp.LpContinuous,
            lowBound=0,
        )

    def obective(self) -> None:
        # maximize revenue = sales_profit - delivery_cost, minimize final arrival time, punish for lack
        #
        sales_profit = plp.lpSum(
            self.order_price[i] * self.d[k, n, i]
            for k in self.cars
            for n in self.trips
            for i in self.cities
        )
        delivery_cost = plp.lpSum(
            self.route_distance[r] * self.car_price[k] * self.x[k, n, r]
            for k in self.cars
            for n in self.trips
            for r in self.routes
        )
        final_arrival_time = plp.lpSum(
            self.te[k, n] for k in self.cars for n in self.trips
        )
        lack_panish = plp.lpSum(
            self.LACK_PUNISHMENT * self.order_price[i] * self.lack[i]
            for i in self.cities
        )

        self.prob += sales_profit - delivery_cost - final_arrival_time - lack_panish

    def ct_start_at_time_zero(self) -> None:
        for k in self.cars:
            self.prob += self.t[k, 1, self.DEPOT] == 0

    def ct_next_start_after_finish(self) -> None:
        for k in self.cars:
            for n in self.trips:
                if n != self.FINAL_TRIP:
                    self.prob += self.te[k, n] <= self.t[k, n + 1, self.DEPOT]
                    self.prob += (
                        self.t[k, n, self.DEPOT] <= self.t[k, n + 1, self.DEPOT]
                    )

    def ct_end_all_trips(self) -> None:
        for k in self.cars:
            for n in self.trips:
                self.prob += self.te[k, n] <= self.MAX_PERIOD

    def ct_time_along_edge(self) -> None:
        for k in self.cars:
            for n in self.trips:
                for i, j in self.routes:
                    if j == self.DEPOT:
                        continue
                    self.prob += self.t[k, n, i] + self.route_time[i, j] <= t[
                        k, n, j
                    ] + self.MAX_PERIOD * (1 - self.x[k, n, (i, j)])
                for i in cities:
                    self.prob += self.t[k, n, i] + self.route_time[
                        i, self.DEPOT
                    ] <= self.te[k, n] + self.MAX_PERIOD * (
                        1 - self.x[k, n, (i, self.DEPOT)]
                    )

    def ct_time_windows(self) -> None:
        for k in self.cars:
            for n in self.trips:
                for i in self.cities:
                    self.prob += (
                        self.t[k, n, i] >= self.order_deliver_from[i] * self.y[k, n, i]
                    )
                    self.prob += (
                        self.t[k, n, i] <= self.order_deliver_to[i] * self.y[k, n, i]
                    )

    def ct_visit_city_atleast_once(self):
        for i in self.cities:
            self.prob += (
                plp.lpSum(self.y[k, n, i] for k in self.cars for n in self.trips) >= 1
            )

    def ct_demand(self):
        for i in self.cities:
            self.prob += (
                plp.lpSum(self.d[k, n, i] for k in self.cars for n in self.trips)
                == self.order_demand[i]
            )  # - lack[i]

    def ct_flux(self) -> None:
        for k in self.cars:
            for i in self.all_cities:
                for n in self.trips:
                    self.prob += (
                        plp.lpSum(
                            self.x[k, n, (i, j)] for j in self.all_cities if i != j
                        )
                        == self.y[k, n, i]
                    )
                    self.prob += (
                        plp.lpSum(
                            self.x[k, n, (j, i)] for j in self.all_cities if i != j
                        )
                        == self.y[k, n, i]
                    )

    def ct_capacity(self) -> None:
        for k in self.cars:
            for n in self.trips:
                self.prob += (
                    plp.lpSum(self.d[k, n, i] for i in self.cities)
                    <= self.car_capacity[k]
                )
                for i in cities:
                    self.prob += (
                        self.d[k, n, i] <= self.car_capacity[k] * self.y[k, n, i]
                    )


if __name__ == "__main__":
    print("LinProgMaker")
