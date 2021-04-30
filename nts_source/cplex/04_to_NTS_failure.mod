/*********************************************
 * OPL 12.9.0.0 Model
 * Author: AV
 * Creation Date: Jan 21, 2021 at 10:09:01 AM
 *********************************************/

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
 
// ������� ���������

int Ncities = card(cities);

range K = 1..card(cars); // �������� ��� �����
car_param_t Car[K] = [i.ID:i.param | i in cars]; // ��������� ������

 
tuple edge_t {int i; int j;}

// ���� - ��� ������ � �����. ��� �������� ������ �������� ���� = ����, � id = 7
int o_id = 1;
int d_id = Ncities+1;

{int} o = {o_id}; // ���� ������
{int} d = {d_id}; // ���� �����


// ��� ��������� ��������. ��� ����� �������� � ���� ������ ������ �� d_id.

{edge_t} Edges = {<r.from_ID, (r.to_ID == o_id ? d_id : r.to_ID)> | r in routes};
int Dist[Edges] = [<r.from_ID,(r.to_ID == o_id ? d_id : r.to_ID)>: r.Distance |  r in routes]; // �����. ����� ������
int dt[Edges] = [<r.from_ID, (r.to_ID == o_id ? d_id : r.to_ID)>: r.Time | r in routes];       // ����� ����. ����� ������
 
{int} N = {i | i in 2..Ncities};  // ����� SET ���������, ����� ���� ���������
 
range Norders = 1..card(orders);  // �������� ������
 
order_param_t Order[Norders] = [i.city_ID: i.param | i in orders];  // ��������� ������
 
 tuple list_t {
 	{int} requests; 
 }

// ��� ������ ��� ������� ���� -  ����� ��� ����� ������ � ������
list_t orderInCity[1..Ncities+1] = [i:<{o.ID | o in orders: o.city_ID == (i == o_id ? i+1: (i==d_id ? i-1:i) )}> | i in N]; 
 

 // ������������ ��������������� ������
 
 // X[k, <i, j>] - k-� ������ �� ������ - ���� ��� ���
 // T[k, r] - k-� ������ � ��������� ������� ��� ������ ������ (request = order)
 // Z[k, r] - k-� ������ ��������� ����� r
 // L[k, i] - �������� (�������) ������ ����� ��������� ���� 
 // Vc[k, i] - ����� ������������ � ���� k-�� �������
 // Vr[k, r] - ����� ������������ �� ������ k-�� �������
 
 dvar boolean X[K][Edges];
 dvar int T[K][Norders] in minPeriod..maxPeriod;  
 dvar boolean Z[K][Norders];
 dvar float+ L[K][1..Ncities+1];
 dvar float+ Vc[K][1..Ncities+1]; // !!!WARNING need to check or Ncities+1
 dvar float+ Vr[K][Norders]; 
 
 
 dexpr float sales_profit = sum(k in K, r in Norders)  Order[r].Price_per_unit * Vr[k][r];
 dexpr float delivery_cost = sum(k in K, e in Edges) Dist[e] * Car[k].Price_per_km  * X[k][e]; 
 
 maximize sales_profit - delivery_cost;
 subject to {

 	forall(k in K, i in N) {
 		//ctOneNode:  // �������� ���� 1 ��� 	
		sum(j in N union d: i != j ) X[k][<i, j>] == 1;
  	}
  	forall(k in K) {
 		
 		sum(j in N) X[k][<o_id, j>] == 1; // ��������  �� ����
 		sum(i in N) X[k][<i, d_id>] == 1; // ����������� �� ����
 		
 		T[k][o_id] == minPeriod;
		T[k][d_id] == maxPeriod;
		
		L[k][o_id] == Car[k].Capacity_Max; // ��������� ��������
		Vc[k][o_id] == 0; // �� ���� ������ �� ���������
		Vc[k][d_id] == 0;
  	}
  	forall(k in K, j in N) {
  		ctFlux: // ����� -- ���� ��������, ������ ������
 		sum(i in N union o: i != j ) X[k][<i, j>] - sum(i in N union d: i !=j) X[k][<j, i>] == 0;	  	 	
  	}
  	// ������ �� ������ ���� - ����������� ���������
  	forall(k in K, i in N, ri in Norders, rj in Norders: ri !=rj) {  	
  		if( card(orderInCity[i].requests diff {ri}) == card(orderInCity[i].requests diff {rj}) &&
  			card(orderInCity[i].requests diff {ri}) == card(orderInCity[i].requests) )
  			{
  				T[k][ri] == T[k][rj];
   			}  			
  	}
  	forall(k in K, <i, j> in Edges) {  	
  		forall(ri in orderInCity[i].requests, rj in orderInCity[j].requests){  	
  			//ctTimeBetweenNodes:// ����� ���������� ������ ����� ������
			T[k][ri] + dt[<i, j>] - T[k][rj] <= maxPeriod * (1 - X[k][<i, j>]);
		}		 	
 	}
 	forall(k in K, r in Norders){
 		ctSchedule: // �������� � ������ ���������� 
 	 	Order[r].Deliver_From  <= T[k][r] <= Order[r].Deliver_To;
 	}
 	forall(k in K, <i, j> in Edges){
 		 ctLoadBetweenNodes: // �������� ����� ������
 		 L[k][i] + Vc[k][i] - L[k][j] <= Car[k].Capacity_Max * (1 - X[k][<i, j>]);	
 	}
 	forall(k in K, i in N union d){
 		ctLoad: // ���. �  ����. ������� �� ����
		Vc[k][i] <= L[k][i];
		L[k][i] <= Car[k].Capacity_Max;
 	}
 	forall(k in K, r in Norders){
 		Vr[k][r] <= Car[k].Capacity_Max;
 		Vr[k][r] == Order[r].Quantity * Z[k][r]; // ���� ������ ���������, �� �� 100%  ��� 0 	
 	}
 	forall(r in Norders){
 		 sum(k in K) Z[k][r] <= 1; // ������ ����� ���� �� ���������	
 	}
 	forall(k in K, i in N){
 		// ����� ����������� � ������ Vc = ������ ������������ �� ������� ��� ������� ������ Vr (���� �� ��������)
 		Vc[k][i] == sum(ri in orderInCity[i].requests) Vr[k][ri];   	
 	}
 }
 

 