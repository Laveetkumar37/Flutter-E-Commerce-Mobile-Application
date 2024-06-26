import 'package:flutter/material.dart';
import 'package:pfe/api/cart_api.dart';
import 'package:pfe/constants.dart';
import 'package:pfe/custom_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfe/cart/cart.dart' as car;
import 'package:pfe/Screens/search_product.dart';
import 'package:url_launcher/url_launcher.dart';
int i = 0 ;

const appBarColor = Color(0xFF01B2C4);
class Cart extends StatefulWidget {

  dynamic total ;

  Cart(this.total);

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  CartApi cartApi = CartApi() ;
  bool isloading = false ;

  dynamic total ;

  void pay(String amount) async {

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String apiToken = sharedPreferences.getString('api_token');
    int userId = sharedPreferences.getInt('user_id');
    //car.Cart carr = await  cartApi.fetchCart();
    String url = 'http://10.0.2.2:8000/charge/'+amount+'/'+userId.toString();


    Map<String, String> _authHeaders = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ' + apiToken
    };

    if(await canLaunch(url))
    {
      await launch(url,headers: _authHeaders);
    }
    else{
      throw 'Could not launch $url';
    }
  }

  Widget appBarTitle = new Text("Shoping Cart",style: TextStyle(
      color: Colors.white,
      fontSize: 20.0
  ),);
  Icon actionIcon = new Icon(Icons.search);
  final searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    i = 0 ;
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Constant.appBarColor,
        title: appBarTitle,

        actions: <Widget>[
          IconButton(
              icon: actionIcon,
              onPressed: () {
                // this.actionIcon = new Icon(Icons.close);
                setState(() {
                  if (this.actionIcon.icon == Icons.search) {
                    this.actionIcon = new Icon(Icons.close);
                    this.appBarTitle = new TextField(
                      controller: searchController,
                      style: new TextStyle(
                        color: Colors.white,
                      ),
                      decoration: new InputDecoration(
                          prefixIcon: InkWell(
                              onTap: () async {
                                if (searchController.text.isEmpty) {
                                } else {
                                  ProductApi productApi = ProductApi();
                                  List<Product> product =
                                  await productApi.fetchProductByName(
                                      searchController.text.toString());
                                  Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                          new SearchProduct(product)
                                      ));
                                }
                              },
                              child: new Icon(Icons.search,
                                  color: Colors.white)),
                          hintText: "Search...",
                          hintStyle: new TextStyle(color: Colors.white)),
                    );
                  } else {
                    this.actionIcon = new Icon(Icons.search);
                    this.appBarTitle = new Text("Details");
                  }
                });
              })
        ],
      ),
      body:Container(
        child:(isloading == false) ? FutureBuilder(
            future: cartApi.fetchCart(),
            // future: helpersApi.fetchStates(1,1),
            // future: helpersApi.fetchCategories(1),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapShot) {
              switch (snapShot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                case ConnectionState.active:
              return Center(
                child: CircularProgressIndicator(),
              );
                  break;
                case ConnectionState.done:
                  if (snapShot.hasError) {
                    return _showError(snapShot.error.toString());
                  } else {
                    if(snapShot.hasData){
                      return ListView.builder(
                        itemCount:snapShot.data.cartItems.length ,
                          itemBuilder: (BuildContext context , int position){

                          if(snapShot.data.cartItems[position].quantity == 0.0   ){
                            return null ;
                          }else{
                            return _drawProduct(snapShot.data.cartItems[position]);
                          }
                          }
                          );
                    }else{
                      return Text("NO data");
                    }
                  }
                  break;
              }
              return Container();
            }): _showLoading() ,
      ) ,
      bottomNavigationBar: Container(
          color: Colors.white,
          child: Row(
            children: <Widget>[
              Expanded(child: ListTile(
                title: Text('Total :'),
                subtitle: (isloading == true)? CircularProgressIndicator(): Text("\$"+widget.total.toString()),
              )),
              Expanded(
                  child: MaterialButton(onPressed: () => pay(widget.total.toString()),
                    child: Text('check out',style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.white
                    ),),
                    color: Constant.appBarColor,
                  )
              ),
            ],
          )
      ),

    );
  }

  Widget _showLoading(){
    return Container(
      child:Center(
        child: CircularProgressIndicator(),
      ) ,
    );
  }
  Widget _showError(String error){
    return Container(
      child:Column(
        children: <Widget>[
          Center(
            child: Icon(Icons.error_outline,size: 80.0,),
          ),
          Text("Sorry Something Went Wrong"),
          Text(error.toString())
        ],
      ) ,
    );
  }

  Widget _drawProduct(car.CartItem cartItem){
    return Padding(
      padding: const EdgeInsets.only(left:8.0),
      child: Row(
        mainAxisAlignment:MainAxisAlignment.spaceBetween ,
        children: <Widget>[
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                      //  color: Colors.red,
                        image: DecorationImage(
                          fit: BoxFit.cover,
                         // image: NetworkImage(cartItem.product.featured_image()),
                        image: NetworkImage(
                          cartItem.product.featured_image()
                        ),
                        )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(cartItem.product.product_title.substring(0,20)),
                          SizedBox(height: 5.0,),
                          Text(
                              '\$ '+cartItem.product.product_price.toString()
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              Column(
                children: <Widget>[
                  IconButton(icon: Icon(Icons.add_circle_outline),
                      onPressed: () async{
                        setState(() {
                          isloading = true ;
                        });
                        await cartApi.addProductToCart(cartItem.product.product_id, 1);
                        car.Cart carr = await  cartApi.fetchCart();
                        setState(() {
                          widget.total =  carr.total.toString() ;
                          isloading = false ;
                        });


                      }),
                  Text(cartItem.quantity.toString()),
                  IconButton(icon: Icon(Icons.remove_circle_outline),
                      onPressed: () async{
                        setState(() {
                          isloading = true ;
                        });
                        await cartApi.removeProductFromCart(cartItem.product.product_id, 1);
                        car.Cart carr = await  cartApi.fetchCart();
                        setState(() {
                          widget.total =  carr.total.toString() ;
                          isloading = false ;
                        });
                      }),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

}
