/*********************************************
 * OPL 12.9.0.0 Model
 * Author: AV
 * Creation Date: Jan 21, 2021 at 10:09:01 AM
 *********************************************/

// The idea is the same as in 05_one_car_notime but here I try to implement time cosntraints.
// Failed to do that.  Bad approch.  The answer means two cars of the same capaicty are need and they travel
// simalateneously
// I falied to implement consectuive trips.


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
	//key int ID;
	//string Customer;
	//string City;
	key int	city_ID;
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

//range K = 1..card(cars); // диапазон для машин
//car_param_t Car[K] = [i.ID:i.param | i in cars]; // параметры машины

 
tuple edge_t {int i; int j;}

// Все возможные маршруты.

{edge_t} Edges = {<r.from_ID, r.to_ID> | r in routes};
int Dist[Edges] = [<r.from_ID, r.to_ID>: r.Distance |  r in routes]; // расст. между узлами
int dt[Edges] = [<r.from_ID, r.to_ID>: r.Time | r in routes];       // время движ. между узлами
 
{int} N = {i | i in 2..Ncities};  // здесь SET ипользуем, чтобы базу добавлять
 

 
order_param_t Order[2..Ncities] = [i.city_ID: i.param | i in orders];  // параметры заявки
 
 
 // формулировка оптимизационной задачи
  
 dvar boolean X[Edges];
 dvar float+ q[2..Ncities]; // остаток после посщения
 dvar int+ T[Edges] in minPeriod..maxPeriod; // время начала движ. из i в j
  
 int Price_per_km = 200;
 int Cap = 60000;
 
 // простой доход - заране известен маршрут и соотвенно загрузка == заказу
 dexpr float sales_profit = sum(i in 2..Ncities)  Order[i].Price_per_unit * Order[i].Quantity;
 dexpr float delivery_cost = sum(e in Edges) Dist[e] * Price_per_km  * X[e]; 
 
 maximize sales_profit - delivery_cost;
 //minimize delivery_cost;
 subject to {
 	forall(jx in 2..Ncities)
 	  	//ctTourX:
 		sum(<i, jx> in Edges) X[<i, jx>] == 1;
	forall(ix in 2..Ncities)
	  	//ctTourY:
 		sum(<ix, j> in Edges) X[<ix, j>] == 1;
 	
 	forall(i in 2..Ncities){
 		ctQty:
 		Order[i].Quantity <= q[i];
 		q[i] <= Cap;
 		q[i] <= Cap + (Order[i].Quantity - Cap) * X[<1, i>];	
 	}
 	forall(<i, j> in Edges: i != 1 && j != 1)
 	 	//ctFlux:
 		q[j] >= q[i] + Order[j].Quantity - Cap + Cap * X[<i, j>] + (Cap - Order[i].Quantity - Order[j].Quantity) * X[<j, i>];  	
 	
 	forall(e in Edges: e.j != 1){
 		// доствить в e.j не раньше, чем Deliver_From (убрать, если разрешить ожидание!!!) 
 		 Order[e.j].Deliver_From <= T[e] + dt[e] <= Order[e.j].Deliver_To;
 	}
 	// возврат на базу оказаться, не позже, чем 
 	forall(i in 2..Ncities)
 		ctBackToBase:
 		T[<i, 1>] <= maxPeriod - dt[<i, 1>];
 	forall(i in 2..Ncities, j in 2..Ncities: i != j)
 	  	T[<1, j>] <= T[<i, 1>];
}

 execute PRINTSOL {
 	for(var e in Edges){
 		var ivol = 0;
 		var jvol = 0;
 		var t1 = 0;
 		var t2 = 0;
 		if( X[e] == 0) continue; 	
 		if( e.i != 1 ) ivol = q[e.i];
 		if( e.j != 1 ) {
 			 jvol = q[e.j];
 			 t1 = Order[e.j].Deliver_From;
 			 t2 = Order[e.j].Deliver_To;
 		} else {
 			 t1 = Order[e.i].Deliver_From;
 			 t2 = Order[e.i].Deliver_To;
 		}
 		

 		writeln(e.i, " ", e.j, ": -> ", T[e] + dt[e], "  from: ",  t1, " to: ", t2);	
 	}
 	
 	//for(var tx in N) writeln(tx, " Tbegin  ", Tbegin[tx], "  ", T[tx],  "  ", Tend[tx]);
 }
