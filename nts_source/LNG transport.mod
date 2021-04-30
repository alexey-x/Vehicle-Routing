/*********************************************
предполагаем последовательно рассчитывать движение для каждого тягача в списке
в базу данных записываем результаты расчета, в том числе: движение тягача, его наполнение, выполненные заявки и т.д.
при загрузке входящих данных мы корректируем сумму заявок для выполнения, на уже выполненные отгрузки

для того чтобы это работало - будет отдельный скрипт
пока скрипта нет - считаем отдельно для каждого тягача
для этого задаем значение переменной currentTruck
*********************************************/

//тягач, для которого идет расчет
 int currentTruck = 3;

//периоды
 int minPeriod = ...;
 int maxPeriod = ...;
 range periods=minPeriod..maxPeriod;

//районы, города (узлы) 
  tuple Tcities {
 	int city_ID;
 	string city_Name;
 }
 {Tcities} cities = ...;
 {int} citiesIDs = {c.city_ID | c in cities}; 
 int baseCityId = 1;

//газовозы (вагоны, машины и т.д.) 
 tuple Tcars {
 	int car_ID;
 	int capacity_Max;
 	float price_per_km;
 }
 {Tcars} cars = ...;
 {int} carsIDs = {c.car_ID | c in cars : c.car_ID==currentTruck};
 Tcars carsArr[carsIDs] = [c.car_ID:
 	<c.car_ID,
 	c.capacity_Max,
 	c.price_per_km>| c in cars: c.car_ID==currentTruck];
 
 //заказы
  tuple Torders {
 	int order_ID;
 	string customer;
 	string city_name;
 	int city_ID;
 	int quantity;
 	float price_per_unit;
 	int deliver_from;
 	int deliver_to;
 }
 {Torders} orders = ...;
 {int} ordersIDs = {o.order_ID | o in orders: o.quantity>0};
 Torders ordersArr[ordersIDs] = [o.order_ID:
 	<o.order_ID,
 	o.customer,
 	o.city_name,
 	o.city_ID,
 	o.quantity,
 	o.price_per_unit,
 	o.deliver_from,
 	o.deliver_to>| o in orders: o.quantity>0];	
 
 tuple TorderPeriods{
 	int order_ID;
 	int periods; 
 }
 {TorderPeriods} orderPeriods = {<o.order_ID, p> | o in orders, p in o.deliver_from..o.deliver_to: o.quantity>0};
 
 	
  //маршруты
  tuple Troutes {
 	int route_ID;
 	string from_Name;
 	int from_ID;
 	string to_Name;
 	int to_ID;
 	int time;
 	float distance;
 }
 {Troutes} routes = ...;
 {int} routesIDs = {r.route_ID | r in routes};
 Troutes routesArr[routesIDs] = [r.route_ID :
 	<r.route_ID,
 	r.from_Name,
 	r.from_ID,
 	r.to_Name,
 	r.to_ID,
 	r.time,
 	r.distance>| r in routes];
 
 {int} routesFrom[citiesIDs] = [c : { e.route_ID | e in routes : e.from_ID == c} | c in citiesIDs];
 {int} routesTo[citiesIDs] = [c : { e.route_ID | e in routes : e.to_ID == c} | c in citiesIDs];
 
 
 dvar int+ dUnload[o in orderPeriods][carsIDs] in 0..ordersArr[o.order_ID].quantity;
 dvar int+ dLoad[c in carsIDs][periods] in 0..carsArr[c].capacity_Max;
 dvar boolean dRoutes[carsIDs][routesIDs][periods];
 dvar int+ dCarCapacity[c in carsIDs][periods] in 0..carsArr[c].capacity_Max;
 dvar boolean dCarPosition[carsIDs][citiesIDs][periods];
 
 dexpr float revenue = 	
 	sum(<o,p> in orderPeriods, c in carsIDs) dUnload[<o,p>][c]*ordersArr[o].price_per_unit
 	- sum (c in carsIDs, r in routesIDs, p in periods) dRoutes[c][r][p]*routesArr[r].distance*carsArr[c].price_per_km
 	;
	 
 maximize revenue;
 
 subject to
 {
	 //в первом периоде все машины стоят на базе
 	 forall (c in carsIDs)  
 	 	minPeriodDislocation1: 	dCarPosition[c][baseCityId][minPeriod]==1;
 	 forall (c in carsIDs, d in citiesIDs: d!=baseCityId) 
 	 	minPeriodDislocation2:	dCarPosition[c][d][minPeriod]==0;
 	 //в крайнем периоде все машины стоят на базе
 	 forall (c in carsIDs)  
 	 	maxPeriodDislocation: 	dCarPosition[c][baseCityId][maxPeriod]==1;
 	 
 	 //в первый период в каждой машине - пусто
 	 forall (c in carsIDs) 
 	 	minPeriodCapacity:	dCarCapacity[c][minPeriod]==0;
 	 
 	 //остаток в машине
 	 forall (c in carsIDs, p in periods: p>minPeriod)
 	 	carCargoBalance: dCarCapacity[c][p]==
 	 		//то что было в предыдущем периоде
 	 		dCarCapacity[c][p-1]
 	 		//-отгрузка по заявке должна уменьшать остаток в машине
 	 		- sum (<o,p> in orderPeriods) dUnload[<o,p>][c]
 	 		//+загрузка на базе
 	 		+ dLoad[c][p]
 	 ;
 	 
 	 //загрузка машины возомжна только на базовой станции
 	 forall(c in carsIDs, p in periods)
 	 	LoadOnBase: dLoad[c][p]<=carsArr[c].capacity_Max*dCarPosition[c][baseCityId][p];
 	  	 
 	 //отгрузка по заявке возможна только когда машина находится в нужном регионе
 	 forall(<o,p> in orderPeriods, c in carsIDs)
 	    unloadInRegion:
 	 	dUnload[<o,p>][c]<=ordersArr[o].quantity * dCarPosition[c][ordersArr[o].city_ID][p];
	 ;

	 //предельный объем отгрузки по заявке	
	 forall(o in ordersIDs)
	 	unloadLessThenOrder: sum(<o,p> in orderPeriods, c in carsIDs) dUnload[<o,p>][c]<=ordersArr[o].quantity; 		 		
 	 ;
 	  	  
 	 //уравнение движения машин 
 	 forall(c in carsIDs, d in citiesIDs, p in periods: p>minPeriod)  
 		stationBalance:
 	 	dCarPosition[c][d][p]==
 	 		dCarPosition[c][d][p-1]
 	 		+ sum(r in routesTo[d]: p-routesArr[r].time>minPeriod) dRoutes[c][r][p-routesArr[r].time]
 	 		- sum(r in routesFrom[d]) dRoutes[c][r][p]
 	 	;	  
 }
 
//выполнение заявок
 tuple TordersMade{
 	int order_ID;
 	int car_ID;
 	int period;
 	float quantity; 
 }
 {TordersMade} ordersMade = {<o
 							,c
 							,p
 							,dUnload[<o,p>][c]> | <o,p> in orderPeriods, c in carsIDs: dUnload[<o,p>][c]!=0};

//выполнение перемещений
tuple TrunsMade{
 	int route_ID;
 	int car_ID;
 	int period;
 	int city_from;
 	int city_to; 
 }
 {TrunsMade} runsMade = {<r
 							,c
 							,p
 							,routesArr[r].from_ID
 							,routesArr[r].to_ID> | r in routesIDs, c in carsIDs, p in periods: dRoutes[c][r][p]!=0};
//динамика остатка в цистерне
tuple TcapacityMade{
 	int car_ID;
 	int periods;
 	int capacity;
 }
 {TcapacityMade} capacityMade = {<c
 							,p
 							,dCarCapacity[c][p]> | c in carsIDs, p in periods: dCarCapacity[c][p]!=0};


 execute {
  writeln(ordersMade);
  writeln(runsMade);
  writeln(capacityMade);    
 }