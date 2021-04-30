/*********************************************
 * OPL 12.9.0.0 Model
 * Author: VOEV
 * Creation Date: Jan 22, 2021 at 8:25:52 PM
 *********************************************/

tuple city_t {
	key int ID;
	string name;
}
{city_t} cities = ...;

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
 

 order_param_t Order[1..card(orders)] = [i.ID: i.param | i in orders];
 
 tuple mix_t {
 	int from_ID;
 	int to_ID;
 	int old_from;
 	int old_to;
 	//int	Time;
 	//int Distance; 
 }
 
 
 
 {mix_t} city_to_order = { <c.ID == 1 ? 0 : c.ID,  o.ID,  c.ID, o.city_ID> | c in cities, o in orders};
 //{mix_t} order_to_city = { <r.to_ID, r.from_ID,  r.old_to, r.old_from> | r  in city_to_order};
 
 {mix_t} order_to_order = {<o1.ID, o2.ID, o1.city_ID, o2.city_ID> | o1 in orders, o2 in orders : o1.ID != o2.ID};
 
 {mix_t} new_routes = 
 	city_to_order 
 	union 
 	{<r.to_ID, r.from_ID,  r.old_to, r.old_from> | r  in city_to_order}; 
 	//union 
 	//order_to_order 
 	//union 
 	//{<r.to_ID, r.from_ID,  r.old_to, r.old_from> | r  in order_to_order}; 
 
 
 int Ncities = 6;
 
 {int} N = {i | i in 2..Ncities};
   

  execute CHECK
 {
 
 	//for(var x in orders) writeln(x);
 	//for(var x in routes) writeln(x);
 	//for(var i in X) writeln(i, "  ", X[i]);
 	writeln(new_routes);
 }