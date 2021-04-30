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

tuple order_param_t {
	float Quantity;
	float Price_per_unit;
	int	Deliver_From; // period from
	int	Deliver_To; // period to
}

tuple order_t { 
	key int ID;
	string Customer;
	string City;
	int	city_ID;
	order_param_t param;
}

{order_t} orders = ...;
 
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

range K = 1..card(cars); // диапазон дл€ машин
car_param_t Car[K] = [i.ID:i.param | i in cars]; // параметры машины

 
tuple edge_t {int i; int j;}

// Ѕаза - это начало и конец. ƒл€ удобства введем конечный узел = база, с id = 7
int o_id = 1;
int d_id = Ncities+1;

{int} o = {o_id}; // база начало
{int} d = {d_id}; // база конец


// ¬се возможные маршруты. ƒл€ конца маршрута у базы мен€ем индекс на d_id.

{edge_t} Edges = {<r.from_ID, (r.to_ID == o_id ? d_id : r.to_ID)> | r in routes};
int Dist[Edges] = [<r.from_ID,(r.to_ID == o_id ? d_id : r.to_ID)>: r.Distance |  r in routes]; // расст. между узлами
int dt[Edges] = [<r.from_ID, (r.to_ID == o_id ? d_id : r.to_ID)>: r.Time | r in routes];       // врем€ движ. между узлами
 
{int} N = {i | i in 2..Ncities};  // здесь SET ипользуем, чтобы базу добавл€ть
 
range Norders = 1..card(orders);  // диапазон за€вок
 
order_param_t Order[Norders] = [i.city_ID: i.param | i in orders];  // параметры за€вки
 
 tuple list_t {
 	{int} requests; 
 }

// все за€вки дл€ данного узла -  нужно дл€ св€зи за€вок с узлами
list_t orderInCity[N] = [i:<{o.ID | o in orders: o.city_ID == i}> | i in N]; 
 

 // формулировка оптимизационной задачи
 
 // X[k, <i, j>] - k-€ машина на ребрах - едет или нет
 // T[k, r] - k-€ машина в интервале времени дл€ данной за€вки (request = order)
 // L[k, i] - загрузка (остаток) машины после посещени€ узла 
 // Vc[k, i] - объем доставленный в узел k-ой машиной
 // Vr[k, r] - объем доставленный по за€вке k-ой машиной (не об€з€тельно = “ребуемому объему)
 
 dvar boolean X[K][Edges];
 dvar int T[K][Norders] in minPeriod..maxPeriod;  
 dvar float+ L[K][1..Ncities+1];
 dvar float+ Vc[K][1..Ncities+1]; // !!!WARNING need to check or Ncities+1
 dvar float+ Vr[K][Norders]; 
 
 dexpr float sales_profit = sum(k in K, r in Norders)  Order[r].Price_per_unit * Vr[k][r];
 dexpr float delivery_cost = sum(k in K, e in Edges) Dist[e] * Car[k].Price_per_km  * X[k][e]; 
 
 maximize sales_profit - delivery_cost;
 subject to {

 	forall(k in K, i in N) {
 		//ctOneNode:  // посетить узел 1 раз 	
		sum(j in N union d: i != j ) X[k][<i, j>] == 1;
  	}
  	forall(k in K) {
 		
 		sum(j in N) X[k][<o_id, j>] == 1; // начинаем  на базе
 		sum(i in N) X[k][<i, d_id>] == 1; // заканчиваем на базе
 		
 		T[k][o_id] == minPeriod;
		T[k][d_id] == maxPeriod;
		
		L[k][o_id] == Car[k].Capacity_Max; // начальна€ загрузка
  	}
  	forall(k in K, j in N) {
  		ctFlux: // поток -- куда приехали, оттуда уехали
 		sum(i in N union o: i != j ) X[k][<i, j>] - sum(i in N union d: i !=j) X[k][<j, i>] == 0;	  	 	
  	}
  	/*
  	forall(k in K, <i, j> in Edges) {
  		forall(ri in orderInCity[i].requests, rj in orderInCity[j].requests){  	
  			ctTimeBetweenNodes:// врем€ выполнени€ за€вок между узлами
			T[k][ri] + dt[<i, j>] - T[k][rj] <= maxPeriod * (1 - X[k][<i, j>]); // bigM  = maxPeriod 
		}		 	
 	}
 	forall(k in K, r in Norders){
 		ctSchedule: // выполнение за€вок дл€ любой машины !!! учесть, что за€вка может и не выполн€тьс€
 	 	Order[r].Deliver_From <= T[k][r] <= Order[r].Deliver_To; 	
 	}*/
 	forall(k in K, <i, j> in Edges){
 		 ctLoadBetweenNodes: // загрузка между узлами
 		 L[k][i] + Vc[k][i] - L[k][j] <= Car[k].Capacity_Max * (1 - X[k][<i, j>]);	
 	}
 	forall(k in K, i in N union d){
 		ctLoad: // мин. и  макс. остаток на узле
		Vc[k][i] <= L[k][i];
		L[k][i] <= Car[k].Capacity_Max;
 	}
 	forall(r in Norders){
 	 	ctSeveralCars: // случай, когда нужно несколько машин на заказ
 		sum(k in K) Vr[k][r] <= Order[r].Quantity; 	
 	}
 	forall(k in K, r in Norders){
 		Vr[k][r] <= Car[k].Capacity_Max;
 		Vr[k][r] >= Order[r].Quantity - sum(kx in K: kx != k) Vr[kx][r]; 	
 	}
 	forall(k in K, i in N){
 		// 	объем доставленный на узел не превышает сумму всех за€вок на узле
 		//  Vc[k][i] <= sum(ri in orderInCity[i].requests) Order[ri].Quantity; -- лишнее
 		
 		// объем отгруженный в городе Vc = объему отгруженному по за€вкам дл€ данного города Vr
 		Vc[k][i] == sum(ri in orderInCity[i].requests) Vr[k][ri];   	
 	}
 	
 	//ctNumCars: // с базы не может уехать машин больше, чем есть
 	//sum(k in K, j in N) X[k][<o_id, j>] <= card(cars);
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
 	//for(var x in routes) writeln(x);
 	//for(var x in Edges) writeln(x, "  ", Dist[x]);
 }