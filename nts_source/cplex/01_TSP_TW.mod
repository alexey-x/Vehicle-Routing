/*********************************************
 * OPL 12.9.0.0 Model
 * Author: VOEV
 * Creation Date: Jan 19, 2021 at 10:09:01 AM
 *********************************************/

// The Traveling Salesman Problem with Time Windows


// read raw data

int minPeriod = ...;
int maxPeriod = ...;


tuple city_t {
	key int ID;
	string name;
}
 
 {city_t} cities = ...;
 
 tuple car_t {
 	key int ID;
 	float Capacity_Max;
 	float Price_per_km;
}

{car_t} cars = ...;

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
tuple order_t { 
	key int	city_ID;
	float Quantity;
	float Price_per_unit;
	int	Deliver_From; // period from
	int	Deliver_To; // period to
}

 {order_t} orders = ...;
 
{int} order_cities = {i.city_ID | i in orders};

 int T_from[order_cities] = [i.city_ID: i.Deliver_From | i in orders, c in order_cities : i.city_ID == c];
 int T_to[order_cities]   = [i.city_ID: i.Deliver_To   | i in orders, c in order_cities : i.city_ID == c];
 
 
 
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
//int Ncars = card(cars);

tuple edge_t {int i; int j;}


// База - это начало и конец. Для удобства введем кончный узел = база, но id = 7
int o_id = 1;
int d_id = 7;

{int} o = {o_id}; // origing node
{int} d = {d_id}; // destination node


// замена базы, для конца маршрута

{edge_t} Edges = {<r.from_ID, (r.to_ID == o_id ? d_id : r.to_ID)> | r in routes};
int Dist[Edges] = [<r.from_ID,(r.to_ID == o_id ? d_id : r.to_ID)>: r.Distance |  r in routes];
int dt[Edges] = [<r.from_ID, (r.to_ID == o_id ? d_id : r.to_ID)>: r.Time | r in routes];
 
 
 {int} N = {i | i in 2..6};  
 //{int} V = N union o union d;
 
 // формулировка оптимизационной задачи
 
 dvar boolean X[Edges];  // i, j = 1..Ncities
 dvar int T[1..Ncities+1] in minPeriod..maxPeriod;  
  
 
 minimize sum (e in Edges) Dist[e] * X[e];
 subject to {
	//ctOneNode:  // посетить узел 1 раз
 	forall(i in N) {
 	 	sum(j in N union d: i != j ) X[<i,j>] == 1;
 	}
 	
 	ctBaseStart: // начинаем  на базе
 	sum(j in N) X[<o_id, j>] == 1;
 	
 	ctBaseEnd: // заканчиваем на базе
 	sum(i in N) X[<i, d_id>] == 1;
 	
 	ctFlux: // поток -- куда приехали, оттуда уехали
 	forall(j in N){
 		sum(i in N union o: i != j ) X[<i, j>] - sum(i in N union d: i !=j) X[<j, i>] == 0; 	
 	}
	
	ctTimeBetweenNodes:// время движения между узлами
	forall(<i, j> in Edges){
		T[i] + dt[<i, j>] - T[j] <= maxPeriod * (1 - X[<i, j>]); // bigM  = maxPeriod
	}
	
	T[o_id] == minPeriod;
	T[d_id] == maxPeriod;
	ctSchedule: // в городах по расписанию
	forall(i in order_cities){
		T_from[i] <= T[i] <= T_to[i];
	}
 }
 
 
 execute PRINT_ROUTE
{
	for(var e in Edges)
	{
		if (X[e] == 1) writeln(e.i, "->", e.j);	
	}
}  
 
 
 execute CHECK
 {
 	//writeln(minPeriod); 
 	//writeln(maxPeriod);
 	//writeln(N);
 	//for(var x in cities) writeln(x);
 	//for(var x in cars) writeln(x);
 	//for(var i in r) writeln(i, " ", (cars.get(i)).Capacity_Max );
 	//for(var x in orders) writeln(x);
 	//for(var x in order_cities) writeln(x, "   ", T_from[x], "   ", T_to[x]);
 	//for(var x in routes) writeln(x);
 	//for(var x in Edges) writeln(x, "  ", Dist[x]);
 }