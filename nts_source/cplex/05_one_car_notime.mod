/*********************************************
 * OPL 12.9.0.0 Model
 * Author: AV
 * Creation Date: Jan 21, 2021 at 10:09:01 AM
 *********************************************/


// Simple task (see Oil delivery from LpBook)
// Capacity more than demand in any city.
// Visit any city only once, come to beginning, use as many cars as needed

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
 
// ������� ���������

int Ncities = card(cities);

//range K = 1..card(cars); // �������� ��� �����
//car_param_t Car[K] = [i.ID:i.param | i in cars]; // ��������� ������

 
tuple edge_t {int i; int j;}

// ��� ��������� ��������. ��� ����� �������� � ���� ������ ������ �� d_id.

{edge_t} Edges = {<r.from_ID, r.to_ID> | r in routes};
int Dist[Edges] = [<r.from_ID, r.to_ID>: r.Distance |  r in routes]; // �����. ����� ������
 
order_param_t Order[2..Ncities] = [i.city_ID: i.param | i in orders];  // ��������� ������
 
 
 // ������������ ��������������� ������
  
 dvar boolean X[Edges];
 dvar float+ q[2..Ncities];
 
 
 int Price_per_km = 200;
 int Cap = 50000;
 
 // ������� ����� - ������ �������� ������� � ��������� �������� == ������
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
 	forall(<i, j> in Edges: i != 1 && j != 1){
 	 	//ctFlux:
 		q[j] >= q[i] + Order[j].Quantity - Cap + Cap * X[<i, j>] + (Cap - Order[i].Quantity - Order[j].Quantity) * X[<j, i>];  	
 	}
}

 execute PRINTSOL {
 	for(var e in Edges){
 		var ivol = 0;
 		var jvol = 0;  	
 		if( X[e] == 0) continue; 	
 		if( e.i != 1 ) ivol = q[e.i];
 		if( e.j != 1 ) jvol = q[e.j];
 		writeln(e.i, " ", e.j, ": -> ", X[e], " ", ivol, "  ", jvol); 	
 	} 
 }

 