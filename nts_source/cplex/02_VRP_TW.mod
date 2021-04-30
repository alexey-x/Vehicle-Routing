/*********************************************
 * OPL 12.9.0.0 Model
 * Author: VOEV
 * Creation Date: Jan 19, 2021 at 10:09:01 AM
 *********************************************/

// The Vehicle Routing Problem with Time Windows (VRP_TW)


// read raw data

int minPeriod = ...;
int maxPeriod = ...;


tuple city_t {
	key int ID;
	string name;
}
 
 {city_t} cities = ...;
 
 tuple car_param_t {
  	float Capacity_Max;
 	float Price_per_km;
 }
 
 tuple car_t {
 	key int ID;
 	car_param_t param;
}

{car_t} cars = ...;

range K_range = 1..card(cars);
car_param_t Car[K_range] = [i.ID:i.param | i in cars];


/*
tuple order_t { 
	key int ID;
	string Customer;
	string City;
	int	city_ID;
	float Quantity;
	float Price_per_unit;
	int	Deliver_From; // period from
	int	Deliver_To; // period to
}*/

// for tests
tuple order_param_t {
	float Quantity;
	float Price_per_unit;
	int	Deliver_From; // period from
	int	Deliver_To; // period to
}

tuple order_t { 
	key int	city_ID;
	order_param_t param;
}

 {order_t} orders = ...;
 
{int} order_cities = {i.city_ID | i in orders};
order_param_t Order[order_cities] = [i.city_ID: i.param | i in orders]; 
 
 tuple route_t {
 	key int ID;
 	string from_Name;
 	int from_ID;
 	string to_Name;	
 	int to_ID;
 	int	Time;
 	int Distance;
} 

{route_t} routes = ...;
 
 // удобные структуры
 
int Ncities = card(cities);

tuple edge_t {int i; int j;}


// База - это начало и конец. Для удобства введем кончный узел = база, но id = 7
int o_id = 1;
int d_id = Ncities+1;

{int} o = {o_id}; // база начало
{int} d = {d_id}; // база конец


// замена базы, для конца маршрута

{edge_t} Edges = {<r.from_ID, (r.to_ID == o_id ? d_id : r.to_ID)> | r in routes};
int Dist[Edges] = [<r.from_ID,(r.to_ID == o_id ? d_id : r.to_ID)>: r.Distance |  r in routes];
int dt[Edges] = [<r.from_ID, (r.to_ID == o_id ? d_id : r.to_ID)>: r.Time | r in routes];
 
 
{int} N = {i | i in 2..Ncities};
 
 
 // формулировка оптимизационной задачи
 
 // X - k-я машина на ребрах
 // T - k-я машина в интервале времени на узле
 // L - загрузка (остаток) машины после посещения узла 
 
 dvar boolean X[K_range][Edges];
 dvar int T[K_range][1..Ncities+1] in minPeriod..maxPeriod;  
 dvar float+ L[K_range][1..Ncities+1]; 
 
 dexpr float sales_profit = sum(k in K_range, i in N) (Car[k].Capacity_Max - L[k][i]) * Order[i].Price_per_unit;
 dexpr float delivery_cost = sum(k in K_range, e in Edges) Dist[e] * Car[k].Price_per_km  * X[k][e]; 
 
 maximize sales_profit - delivery_cost;
 subject to {

 	forall(k in K_range) {
 		//ctOneNode:  // посетить узел 1 раз 	
 		forall(i in N)
 	 	 	sum(j in N union d: i != j ) X[k][<i, j>] == 1;
 	 	
 	 	ctBaseStart: // начинаем  на базе
 		sum(j in N) X[k][<o_id, j>] == 1;
 		
 		ctBaseEnd: // заканчиваем на базе
 		sum(i in N) X[k][<i, d_id>] == 1;
 		
 		ctFlux: // поток -- куда приехали, оттуда уехали (ребра с базы и на базу исключены)
 		forall(j in N)
 			sum(i in N union o: i != j ) X[k][<i, j>] - sum(i in N union d: i !=j) X[k][<j, i>] == 0; 	
 		
 		ctTimeBetweenNodes:// время движения между узлами
		forall(<i, j> in Edges)
			T[k][i] + dt[<i, j>] - T[k][j] <= maxPeriod * (1 - X[k][<i, j>]); // bigM  = maxPeriod
	
		T[k][o_id] == minPeriod;
		T[k][d_id] == maxPeriod;
		
		ctSchedule: // в городах по расписанию
		forall(i in order_cities)
			Order[i].Deliver_From <= T[k][i] <= Order[i].Deliver_To;
			
		ctLoadBetweenNodes: // загрузка между узлами
		forall(<i, j> in Edges)
			L[k][i] + Order[i].Quantity - L[k][j] <= Car[k].Capacity_Max * (1 - X[k][<i, j>]);
		
		ctDemand: // 	
		forall(i in N union d)
			Order[i].Quantity <= L[k][i] <= Car[k].Capacity_Max;  // !!!! Currently it is wrong
		
		ctInitialLoad:
			L[k][o_id] == Car[k].Capacity_Max;
 	}
 	// ctNumCars: // с базы не може уехать машин больше, чем есть
 	sum(k in K_range, j in N) X[k][<o_id, j>] <= card(cars);
 	
 }
 
 /*
 execute PRINT_ROUTE
{
	for(var e in Edges)
	{
		if (X[e] == 1) writeln(e.i, "->", e.j);	
	}
}  
 */
 
 execute CHECK
 {
 	//writeln(minPeriod); 
 	//writeln(maxPeriod);
 	//writeln(N);
 	//for(var x in cities) writeln(x);
 	//for(var x in cars) writeln(x);
 	//for(var i in r) writeln(i, " ", (cars.get(i)).Capacity_Max );
 	//for(var x in orders) writeln(x);
 	for(var x in order_cities) writeln(x, "   ", Order[x]);
 	//for(var x in routes) writeln(x);
 	//for(var x in Edges) writeln(x, "  ", Dist[x]);
 }