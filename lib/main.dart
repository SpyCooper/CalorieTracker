import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';


void main() {
  // TODO - create the current date and time if it is not already set
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void ChangeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'Calorie Tracker',
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.light(
              primary: Color(0xFF4CAF50), // light green
              primaryContainer: Color.fromARGB(255, 221, 221, 221),
              secondary: Color(0xFF81C784), // mid green
              surface: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.black,
              onSurface: Colors.black,
            ),
            scaffoldBackgroundColor: Color(0xFFF5F5F5),
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            dividerColor: Color(0xFFA5D6A7),
            tabBarTheme: TabBarThemeData(
              labelColor: Colors.white, // selected tab text color
              unselectedLabelColor: Colors.white70, // unselected tab text color
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(
                color: Colors.black,
              ),
              bodyMedium: TextStyle(
                color: Colors.black,
              ),
              bodySmall: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF4CAF50),
              primaryContainer: Color.fromARGB(255, 71, 71, 71),
              secondary: Color(0xFF81C784),
              surface: Color(0xFF212121), // dark grey
              onPrimary: Color.fromARGB(255, 58, 58, 58), // white text on green for better contrast
              onSecondary: Colors.white,
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: Color.fromARGB(255, 44, 44, 44), // even darker background
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF212121),
              foregroundColor: Colors.white, // white text for better visibility
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
              actionsIconTheme: IconThemeData(color: Colors.white),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Color.fromARGB(255, 58, 58, 58),
              border: OutlineInputBorder(),
              hintStyle: TextStyle(color: Colors.white70),
            ),
            dropdownMenuTheme: DropdownMenuThemeData(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Color(0xFF388E3C),
                border: OutlineInputBorder(),
                hintStyle: TextStyle(color: Colors.white),
              ),
              textStyle: TextStyle(
                color: Colors.white, // text color for dropdown items
              ),
            ),
            dividerColor: Color(0xFF388E3C),
            tabBarTheme: TabBarThemeData(
              labelColor: Colors.white, // white selected tab text
              unselectedLabelColor: Colors.white70,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(
                color: Colors.white,
              ),
              bodyMedium: TextStyle(
                color: Colors.white,
              ),
              bodySmall: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          themeMode: _themeMode,
          home: Stack(
            children: [
              HomePage(),
              // Floating action button at the bottom right
                Positioned(
                top: 27,
                right: 15,
                child: FloatingActionButton(
                  mini: true,
                  tooltip: 'Toggle Light/Dark Mode',
                  backgroundColor: Colors.transparent, // Disable background color
                  elevation: 0, // Remove shadow
                  child: Icon(
                    _themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.white, // Change icon color based on theme
                  ),
                  onPressed: () {
                    setState(() {
                      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Current state of the app
class MyAppState extends ChangeNotifier {
  // List of all the days
  List<DayData> days = [];

  // contains all the foods in the database
  List<FoodData> foods = [];

  // default data
  DefaultData defaultData = DefaultData();

  // current day data
  late DayData currentDay;

  Food currentlySelectedFood = Food(foodData: FoodData(), serving: 1);
  Meal currentlySelectedMeal = Meal();

  // weight list
  List<WeightData> weightList= [];
  WeightData currentlySelectedWeight = WeightData();

  bool isAddFoodMenuOpen = false;

  List<UserMeal> userMeals = [];
  UserMeal currentlySelectedUserMeal = UserMeal();

  // constructor
  MyAppState() {
    currentDay = DayData(defaultData);
    days.add(currentDay);
  }

  // change the current day to a specific date
  void changeCurrentDay(DateTime newDate) {
    // check if the date already exists in the days list
    for (var day in days) {
      if (day.date.year == newDate.year && day.date.month == newDate.month && day.date.day == newDate.day) {
        currentDay = day;
        notifyListeners();
        return;
      }
    }

    // if the date does not exist, create a new day
    currentDay = DayData(defaultData, date: newDate);
    currentDay.date = newDate;
    days.add(currentDay);
    notifyListeners();
  }

  void addFoodToDatabase(FoodData food) {
    foods.add(food);
    // Sort the foods list by name
    foods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
  }

  void addNewFoodToMeal(Meal meal, Food food) {
    // Add the food to the currently selected meal
    meal.addNewFood(food);
    notifyListeners();
  }

  void removeFoodFromMeal(Meal meal, Food food) {
    // Remove the food from the currently selected meal
    meal.foods.remove(food);
    // Reset the currently selected food
    currentlySelectedFood = Food(foodData: FoodData(), serving: 1);
    // Reset the currently selected meal
    currentlySelectedMeal = Meal();

    notifyListeners();
  }

  void servingSizeChanged(double newServing) {
    // Update the serving size of the currently selected food
    currentlySelectedFood.serving = newServing;
    notifyListeners();
  }

  void setCurrentlySelectedMeal(Meal meal) {
    currentlySelectedMeal = meal;
    notifyListeners();
  }

  void setNewMealName(String newName) {
    // Update the meal name of the currently selected meal
    currentlySelectedMeal.mealName = newName;
    notifyListeners();
  }

  void removeMeal(Meal meal, {bool futureDays = false}) {
    // Remove the meal from the current day's meals
    currentDay.meals.remove(meal);
    if (futureDays) {
      // Remove the meal from default meals for future days
      defaultData.meals.removeWhere((m) => m == meal.mealName);
    }
    notifyListeners();
  }

  void addMeal(Meal meal, {bool toDefault = false}) {
    // Add the meal to the current day's meals
    Meal newMeal = Meal();
    newMeal.mealName = meal.mealName;
    newMeal.foods = meal.foods.map((food) => Food(foodData: food.foodData, serving: food.serving)).toList();
    // Add the new meal to the current day's meals
    currentDay.meals.add(newMeal);
    // Optionally add to default meals if not already present
    if (toDefault && !defaultData.meals.contains(meal.mealName)) {
      defaultData.meals.add(meal.mealName);
    }
    notifyListeners();
  }

  void addWeight(WeightData weight) {
    // Add a new weight entry to the weight list
    weightList.add(weight);
    // Sort the weight list by date
    weightList.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  void updatedCurrentWeight(double weight, DateTime date) {
    // Update the currently selected weight entry
    currentlySelectedWeight.weight = weight;
    currentlySelectedWeight.date = date;
    // sort the weight list by date
    weightList.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  void removeWeight(WeightData weight) {
    // Remove a weight entry from the weight list
    weightList.remove(weight);
    notifyListeners();
  }

  void setCalorieAndMacroGoals(int calories, int carbs, int fat, int protein) {
    // Set the daily calorie and macro goals in default data
    defaultData.dailyCalories = calories;
    defaultData.dailyCarbs = carbs;
    defaultData.dailyFat = fat;
    defaultData.dailyProtein = protein;

    // Update the current day's goals as well
    currentDay.maxCalories = calories;
    currentDay.maxCarbs = carbs;
    currentDay.maxFat = fat;
    currentDay.maxProtein = protein;

    // Notify listeners to update the UI
    notifyListeners();
  }

  void updateCurrentlySelectedFoodData(FoodData foodData) {
    // Update the currently selected food's data
    currentlySelectedFood.foodData = foodData;
    notifyListeners();
  }

  void changeDefaultMealName(String mealName, String defaultMeal) {
    // Change the name of the default meal
    if (defaultData.meals.contains(defaultMeal)) {
      int index = defaultData.meals.indexOf(defaultMeal);
      defaultData.meals[index] = mealName;
    } else {
      // If the default meal is not found, add it
      defaultData.meals.add(mealName);
    }
    notifyListeners();
  }

  void addNewUserMeal(UserMeal userMeal) {
    // Add a new user meal to the list
    userMeals.add(userMeal);
    notifyListeners();
  }

  void updateCurrentlySelectedUserMealData(UserMeal userMeal) {
    // Update the currently selected user meal
    currentlySelectedUserMeal.name = userMeal.name;
    currentlySelectedUserMeal.foodInMeal = userMeal.foodInMeal;
    notifyListeners();
  }

  void removeUserMeal(UserMeal userMeal) {
    // Remove a user meal from the list
    userMeals.remove(userMeal);
    notifyListeners();
  }

  void updateCurrentlySelectedUserMealName(String newName) {
    // Update the name of the currently selected user meal
    currentlySelectedUserMeal.name = newName;
    notifyListeners();
  }

  void addUserMealToCurrentMeal(UserMeal userMeal, double serving) {
    // Add the foods from the user meal to the currently selected meal
    for (var food in userMeal.foodInMeal) {
      // Create a new Food object with the specified serving size
      Food newFood = Food(foodData: food.foodData, serving: food.serving * serving);
      // Add the new food to the currently selected meal
      currentlySelectedMeal.addNewFood(newFood);
    }
    notifyListeners();
  }

  Future<FoodData?> getFoodDataFromBarcode(String barcode) async {
    // set a UserAgent to avoid issues with the Open Food Facts API
    OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'CalorieTrackerApp');
    final ProductQueryConfiguration configuration = ProductQueryConfiguration(
      barcode,
      fields: [ProductField.ALL],
      version: ProductQueryVersion.v3,
    );
    final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(configuration);
    if (result.status == ProductResultV3.statusSuccess) {
      String name = result.product?.productName ?? 'Unknown Product';
      String brand = result.product?.brands ?? 'Unknown Brand';
      String productName = '$brand $name';

      if (result.product?.nutriments != null) {
        Nutriments nutriments = result.product!.nutriments!;
        int calories = nutriments.getValue(Nutrient.energyKCal, PerSize.serving)?.round() ?? 0;
        int carbs = nutriments.getValue(Nutrient.carbohydrates, PerSize.serving)?.round() ?? 0;
        int fat = nutriments.getValue(Nutrient.fat, PerSize.serving)?.round() ?? 0;
        int protein = nutriments.getValue(Nutrient.proteins, PerSize.serving)?.round() ?? 0;
        FoodData foodData = FoodData(
          name: productName,
          calories: calories,
          carbs: carbs,
          fat: fat,
          protein: protein,
        );
        return foodData;
      } else {
        throw Exception('No nutritional information available for product with barcode: $barcode');
      }
    } else {
      throw Exception('product not found, please insert data for $barcode');
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var selectedPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    
    Widget page;
    switch (selectedPageIndex)
    {
      case 0:
        page = MealsPage();
        break;
      case 1:
        page = ProgressPage();
        break;
      case 2:
        page = SettingsPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedPageIndex');
    }

    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        // set the title to today's date
        title: SizedBox(
          width: 180,
          child: DropdownButton<DateTime>(
            isExpanded: true,
            value: DateTime(appState.currentDay.date.year, appState.currentDay.date.month, appState.currentDay.date.day),
            items: List.generate(365, (index) {
              final date = DateTime.now().subtract(Duration(days: 182)).add(Duration(days: index));
              return DropdownMenuItem<DateTime>(
                value: DateTime(date.year, date.month, date.day),
                child: Text(
                  DateFormat('MM/dd/yyyy').format(date),
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 15),
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                appState.changeCurrentDay(value);
                // update the page to reflect the new current day
                setState(() {});
              }
            },
            dropdownColor: theme.primaryColor, // set dropdown background color
          ),
        ),
        backgroundColor: theme.primaryColor
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem> [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.line_axis_rounded), label: 'Progress'),
          //  BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Food'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: selectedPageIndex,
        onTap: (value) {
          setState(() {
            selectedPageIndex = value;
          });
        },
        selectedItemColor: theme.colorScheme.primary,
      ),
    
      body: page,
      resizeToAvoidBottomInset: false,
    );
  }
}

// ================================= Meals Page =================================

class MealsPage extends StatelessWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // spacer
        SizedBox(height: 0,),
        // Calories Header
        InkWell(
          child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Max calories
            Column(
            children: [
              Text(
                'Max Calories',
                style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
              ),
              Text(
                '${appState.currentDay.maxCalories}',
                style: TextStyle(fontSize: 30, color: theme.textTheme.bodyLarge?.color),
              ),
            ]
            ),
            // minus
            Column(
            children: [
              Text(
              '',
              style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
              ),
              Text(
              '-',
              style: TextStyle(fontSize: 30, color: theme.textTheme.bodyLarge?.color),
              ),
            ]
            ),
            // Calories Used
            Column(
            children: [
              Text(
              'Calories Used',
              style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
              ),
              Text(
              '${appState.currentDay.getCalories()}',
              style: TextStyle(fontSize: 30, color: theme.textTheme.bodyLarge?.color),
              ),
            ]
            ),
            // equals
            Column(
            children: [
              Text(
                '',
                style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
              ),
              Text(
                '=',
                style: TextStyle(fontSize: 30, color: theme.textTheme.bodyLarge?.color),
              ),
            ]
            ),
            // Calories Left
            Column(
            children: [
              Text(
                'Calories Left',
                style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
              ),
              Text(
                '${appState.currentDay.maxCalories - appState.currentDay.getCalories()}',
                style: TextStyle(fontSize: 30, color: theme.textTheme.bodyLarge?.color),
              ),
            ]
            ),
          ],
          ),
          onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => DailyNutritionMenu()));
          }
        ),
        SizedBox(height: 25),
        // Dynamically create meal boxes based on the day's meals
        ...List.generate(
          appState.currentDay.meals.length,
          (index) => Column(
            children: [
              MealBox(meal: appState.currentDay.meals[index]),
              SizedBox(height: 25),
            ],
          ),
        ),
        // Add new meal button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
          child: Text('Add new meal', style: TextStyle(fontSize: 20, color: theme.colorScheme.primary)),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddNewMeal()));
          }
          ),
        ),
        SizedBox(height: 25),
      ]
    );
  }
}

class MealBox extends StatefulWidget {
  // Make meal accessible from the state class
  final Meal meal;
  Meal get mealData => meal;

  const MealBox({super.key, required this.meal});

  @override
  State<MealBox> createState() => _MealBoxState();
}

class _MealBoxState extends State<MealBox> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor)
      ),
      child: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 5,
                      children: [
                        // sets the meal name
                        Text(widget.meal.mealName, style: TextStyle(fontSize: 30, color:theme.textTheme.bodySmall?.color), textAlign: TextAlign.left),
                        Icon(Icons.edit, color:theme.textTheme.bodySmall?.color,),
                      ],
                    ),
                    // sets the calories for the meal
                    Text(
                      '${widget.meal.getCalories()}',
                      style: TextStyle(fontSize: 30, color:theme.textTheme.bodySmall?.color), textAlign: TextAlign.right
                    ),
                  ],
                ),
                onTap: () {
                  // Set the currently selected meal in app state
                  context.read<MyAppState>().currentlySelectedMeal = widget.meal;
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditMealMenu()));
                }
              )
            ),
            // Dynamically list foods in the meal with alternating background colors
            ...List.generate(
              widget.meal.foods.length,
              (foodIndex) {
              final food = widget.meal.foods[foodIndex];
              final isAlt = foodIndex % 2 == 0;
              return Container(
                decoration: BoxDecoration(
                color: isAlt ? null : theme.colorScheme.primaryContainer ,
                ),
                child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  Text(food.foodData.name, style: TextStyle(fontSize: 20), textAlign: TextAlign.left),
                  Text('${(food.foodData.calories * food.serving).ceil()}', style: TextStyle(fontSize: 20), textAlign: TextAlign.right),
                  ],
                ),
                onTap: () {
                  // Set the selected food in app state if needed
                  context.read<MyAppState>().currentlySelectedFood = food;
                  // Set the currently selected meal in app state
                  context.read<MyAppState>().currentlySelectedMeal = widget.meal;
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => FoodNutritionFacts()));
                }
                ),
              );
              }
            ),
            // Add button
            ElevatedButton(
              child: Icon(Icons.add_box, size:25, color: theme.colorScheme.primary,),
              onPressed: () {
                // Set the currently selected meal in app state
                context.read<MyAppState>().currentlySelectedMeal = widget.meal;
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddFoodMenu()));
              }
            ),
          ],
        )
      )
    );
  }
}

class AddFoodMenu extends StatefulWidget {
  const AddFoodMenu({super.key});

  @override
  State<AddFoodMenu> createState() => _AddFoodMenuState();
}

class _AddFoodMenuState extends State<AddFoodMenu>{
  // set isAddFoodMenuOpen to true while the menu is opened
  @override
  void initState() {
    super.initState();
    // Set isAddFoodMenuOpen to true when the menu is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyAppState>().isAddFoodMenuOpen = true;
    });
  }

  @override
  void deactivate() {
    // Set isAddFoodMenuOpen to false when the menu is closed
    // This is safe because deactivate is called before dispose and context is still valid
    context.read<MyAppState>().isAddFoodMenuOpen = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold
      (
        appBar: AppBar(
          title: Text('Add New Food to ${appState.currentlySelectedMeal.mealName.isEmpty ? 'Meal' : appState.currentlySelectedMeal.mealName}'),
          // search or scan tabs selection
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search)),
              Tab(icon: Icon(Icons.dining)),
              Tab(icon: Icon(Icons.barcode_reader)),
            ]
          ),
        ),

        
        body: TabBarView(
          children: [
            // Search Tab
            Column(
              spacing: 20,
              children: [
                SizedBox(height: 0,),
                // search bar
                SizedBox(
                  width: 350,
                  height: 50,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      // TODO - Finish search bar
                      hintText: 'Search',
                    ),
                  ),
                ),
                // list of foods
                SizedBox(
                  width: 370,
                  height: 570,
                    child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: appState.foods.length,
                    itemBuilder: (context, index) {
                      return Container(
                      height: 50,
                      color: theme.colorScheme.primaryContainer, // Changed from onPrimary to primaryContainer for better theming
                      child: InkWell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          SizedBox(
                            width: 330,
                            child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('   ${appState.foods[index].name}', style: TextStyle(fontSize: 17),),
                              Text('${appState.foods[index].calories}', style: TextStyle(fontSize: 17),),
                            ],
                            ),
                          ),
                          ],
                        ),
                        onTap: () {
                        // open Nutrition facts
                        appState.currentlySelectedFood = Food(foodData: appState.foods[index], serving: 1);
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => FoodNutritionFacts()));
                        },
                      ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                  ),
                ),
                // Create new food to database button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      fixedSize: const Size(350, 50),
                      foregroundColor: theme.colorScheme.primary, // text color
                      side: BorderSide(width: 3, color: theme.colorScheme.primary)
                    ),
                  child: Text('Create New Food', style: TextStyle(fontSize: 20)),
                  onPressed: () => {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateNewFoodMenu()))
                  },
                ),
              ],
            ),
            // User Meal Tab
            Column(
              spacing: 20,
              children: [
              SizedBox(height: 0,),
              // search bar
              SizedBox(
                width: 350,
                height: 50,
                child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Search Meals',
                ),
                ),
              ),
              // list of user meals
              SizedBox(
                width: 370,
                height: 570,
                child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: appState.userMeals.length,
                itemBuilder: (context, index) {
                  return Container(
                  height: 50,
                  color: theme.colorScheme.onPrimary,
                  child: InkWell(
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                      width: 330,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Text('   ${appState.userMeals[index].name}', style: TextStyle(fontSize: 17),),
                        Text('${appState.userMeals[index].getCalories()}', style: TextStyle(fontSize: 17),),
                        ],
                      ),
                      ),
                    ],
                    ),
                    onTap: () {
                    // open Nutrition facts
                    appState.currentlySelectedUserMeal = appState.userMeals[index];
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserMealNutritionFacts()));
                    },
                  ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
                ),
              ),
              // Create new user meal button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                fixedSize: const Size(350, 50),
                foregroundColor: theme.colorScheme.primary, // text color
                side: BorderSide(width: 3, color: theme.colorScheme.primary)
                ),
                child: Text('Create New User Meal', style: TextStyle(fontSize: 20)),
                onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateNewUserMeal()));
                },
              ),
              ],
            ),
            // Scan Tab
            Scanner(),
          ]
        )
      ),
    );
  }
}

class EditMealMenu extends StatelessWidget {
  const EditMealMenu({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // var theme = Theme.of(context);

    return Scaffold
    (
      appBar: AppBar(title: Text('Edit ${appState.currentlySelectedMeal.mealName}'),),
      body: Column(
        spacing: 15,
        children: [
          // Calories
          SizedBox(
            width: 350,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calories', style: TextStyle(fontSize: 25),),
                Text(appState.currentlySelectedMeal.getCalories().toString(), style: TextStyle(fontSize: 25),),
              ]
            ),
          ),
          // Macros
          Text('Macro Nutrients', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline,),),
          MacroBreakdown(
            carbs: (appState.currentlySelectedMeal.getCarbs()).ceil(),
            fat: (appState.currentlySelectedMeal.getFat()).ceil(),
            protein: (appState.currentlySelectedMeal.getProtein()).ceil(),
          ),
          // Options
          Text('Options', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          // Note that this changing the meal name will only change the name of the meal in the current day's meals
          SizedBox(
            width: 350,
            height: 50,
            child: Text(
              'Note: Changing the meal name will only change the name of the meal in the current day\'s meals.',
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Meal Name', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '${appState.currentlySelectedMeal.mealName.isEmpty ? 'Meal Name' : appState.currentlySelectedMeal.mealName}',
                      ),
                      onChanged: (value) {
                        // Update the meal name in the app state as the user types
                        appState.setNewMealName(value);
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
          // Spacer
          SizedBox(height: 75,),
          // // Save Button
          // ElevatedButton(
          //   style: ElevatedButton.styleFrom(
          //     fixedSize: const Size(250, 50),
          //     foregroundColor: theme.colorScheme.primary, // text color
          //     side: BorderSide(width: 3, color: theme.colorScheme.primary)
          //     ),
          //   child: Text('Save', style: TextStyle(fontSize: 20)),
          //   onPressed: () => {
          //     print('finish save button for edit meal')
          //   },
          // ),
          // Remove button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
              side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14))
              ),
            child: Text('Remove Meal', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              showDialog(
                context: context,
                builder: (BuildContext context) => RemoveMealPopUp()
              )
            },
          )
        ]
      )
    );
  }
}

class RemoveMealPopUp extends StatelessWidget {
  const RemoveMealPopUp({super.key});

  @override
  Widget build(BuildContext context) {
    // var theme = Theme.of(context);

    return SizedBox(
      width: 300,
      height: 200,
      child: AlertDialog(
        title: const Text('Are you sure you want to remove this meal?'),
        // content: const Text('Body text'),
        actions: [
          // Cancel button
          TextButton(
            child: Text('Cancel'),
            onPressed:() {
              Navigator.pop(context, 'Cancel');
            },
          ),
          // Confirm Deletion
          TextButton(
            child: Text('Confirm'),
            onPressed:() {
              // push additional popup
              Navigator.pop(context, 'Confirm');
              showDialog(
                  context: context,
                  builder: (BuildContext context) => TypeOfMealDeletion()
              );
            },
          ),
        ],
      ),
    );
  }
}

class TypeOfMealDeletion extends StatelessWidget {
  const TypeOfMealDeletion({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // var theme = Theme.of(context);

    return SizedBox(
      width: 300,
      height: 200,
      child: AlertDialog(
        title: const Text('How Should This Meal Be Removed?'),
        content: const Text('Selecting "Today Only" will only remove the meal from today.\nSelecting "Future Days" will remove this meal from appearing by default in future days.'),
        actions: [
          // Cancel button
          TextButton(
            child: Text('Cancel'),
            onPressed:() {
              Navigator.pop(context, 'Cancel');
            },
          ),
          // Remove just from the day's meals
          TextButton(
            child: Text('Today Only'),
            onPressed:() {
              appState.removeMeal(appState.currentlySelectedMeal);
              // pop all the way back to the home page
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // Remove from daily meals
          TextButton(
            child: Text('Future Days'),
            onPressed:() {
              appState.removeMeal(appState.currentlySelectedMeal, futureDays: true);
              // pop all the way back to the home page
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

class AddNewMeal extends StatefulWidget {
  const AddNewMeal({super.key});

  @override
  State<AddNewMeal> createState() => _AddNewMealState();
}

class _AddNewMealState extends State<AddNewMeal> {
  String mealTypeValue = 'Add for Today Only'; // default value for the dropdown

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    Meal newMeal = Meal(mealName: 'Meal ${appState.currentDay.meals.length + 1}'); // default meal name
    List<String> mealTypes = ['Add for Today Only', 'Add to Daily Meals'];
    bool isDefaultMeal = false; // flag to check if the meal is a default meal

    return Scaffold
    (
      appBar: AppBar(title: Text('Add New Meal'),),
      body: Column(
        spacing: 15,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Meal Name', style: TextStyle(fontSize: 17)),
                  Text('Type of Meal', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: newMeal.mealName, // default meal name
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: DropdownButton<String>(
                      value: mealTypeValue, // default value
                      hint: Text('Add Meal Type'),
                      items: mealTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged:(String? newValue) {
                        if (newValue == 'Add for Today Only') {
                          isDefaultMeal = false; // set the flag to false
                        } else if (newValue == 'Add to Daily Meals') {
                          isDefaultMeal = true; // set the flag to true
                        }
                        setState(() {
                          mealTypeValue = newValue!;
                        });
                      },
                    ),
                  )
                ],
              )
            ],
          ),
          // Spacer
          SizedBox(height: 75,),
          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
              ),
            child: Text('Add Meal', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // Add the new meal to the current day's meals
              appState.addMeal(newMeal, toDefault: isDefaultMeal),
              // Pop back to the home page
              Navigator.of(context).popUntil((route) => route.isFirst),
            },
          ),
        ]
      
      )
    );
  }
}

class FoodNutritionFacts extends StatefulWidget {
  const FoodNutritionFacts({super.key});

  @override
  State<FoodNutritionFacts> createState() => _FoodNutritionFactsState();
}

class _FoodNutritionFactsState extends State<FoodNutritionFacts> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return Scaffold
    (
      appBar: AppBar(
        title: Text('Nutrition Facts'),
        ),

      body: Column(
        spacing: 15,
        children: [
          Text(appState.currentlySelectedFood.foodData.name, style: TextStyle(fontSize: 25),),
          // Calories
          SizedBox(
            width: 350,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calories', style: TextStyle(fontSize: 25),),
                Text('${appState.currentlySelectedFood.foodData.calories * appState.currentlySelectedFood.serving}', style: TextStyle(fontSize: 25),),
              ]
            ),
          ),
          // Macros
          Text('Macro Nutrients', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline,),),
          MacroBreakdown(
            carbs: (appState.currentlySelectedFood.foodData.carbs * appState.currentlySelectedFood.serving).ceil(),
            fat: (appState.currentlySelectedFood.foodData.fat * appState.currentlySelectedFood.serving).ceil(),
            protein: (appState.currentlySelectedFood.foodData.protein * appState.currentlySelectedFood.serving).ceil(),
          ),
          // Options
          Text('Options', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          // Labels for inputs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Serving Size', style: TextStyle(fontSize: 17)),
                  Text('Selected Meal', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 75,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                    SizedBox(
                    width: 150,
                    height: 50,
                    child: TextField(
                      // restrict the input to numbers only
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: appState.currentlySelectedFood.serving.toString().replaceAll('.0', ''), // show the current serving size
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),],
                        onChanged: (value) {
                          // Update the serving size in the app state as the user types
                          appState.servingSizeChanged(double.tryParse(value) ?? 1);
                        }
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: DropdownButton<String>(
                        hint: appState.currentlySelectedMeal.mealName.isEmpty ? Text('Select Meal') : Text(appState.currentlySelectedMeal.mealName),
                        items: appState.currentDay.meals.map((meal) {
                          return DropdownMenuItem<String>(
                            value: meal.mealName,
                            child: Text(meal.mealName),
                          );
                        }).toList(),
                        onChanged:(String? newValue) {
                          // set the currently selected meal in app state
                          appState.setCurrentlySelectedMeal(
                            appState.currentDay.meals.firstWhere((meal) => meal.mealName == newValue, orElse: () => Meal())
                          );
                        },
                      ),
                  )
                ],
              )
            ],
          ),
          // Spacer
          SizedBox(height: 75,),
          // Save Button
          if (context.read<MyAppState>().isAddFoodMenuOpen)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
              ),
            child: Text(
              'Add Food to Meal',
              style: TextStyle(fontSize: 20),
            ),
            onPressed: () {
              // if the user is coming from the AddFoodMenu, add the food to the meal
              if (context.read<MyAppState>().isAddFoodMenuOpen) {
                appState.addNewFoodToMeal(appState.currentlySelectedMeal, appState.currentlySelectedFood);
                Navigator.of(context).pop(); // Close the nutrition facts page
              } 
            },
          ),
          // Remove button
          // Only show if not coming from AddFoodMenu (i.e., currentlySelectedMeal is not empty)
          if (!context.read<MyAppState>().isAddFoodMenuOpen)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
              side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14))
              ),
              child: Text('Remove Food', style: TextStyle(fontSize: 20)),
              onPressed: () {
                // remove the food from the meal
                appState.removeFoodFromMeal(appState.currentlySelectedMeal, appState.currentlySelectedFood);
                Navigator.of(context).pop(); // Close the nutrition facts page
              },
            ),
        ],
      ),
    );
  }
}

class UserMealNutritionFacts extends StatefulWidget {
  const UserMealNutritionFacts({super.key});

  @override
  State<UserMealNutritionFacts> createState() => _UserMealNutritionFactsState();
}

class _UserMealNutritionFactsState extends State<UserMealNutritionFacts> {
  double servingSize = 1; // Default serving size

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${appState.currentlySelectedUserMeal.name} Nutrition Facts')),
      body: Column(
        spacing: 15,
        children: [
          // Meal name
          Text(appState.currentlySelectedUserMeal.name, style: TextStyle(fontSize: 25)),
          // Calories
          SizedBox(
            width: 350,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Text('Calories', style: TextStyle(fontSize: 25)),
                // Update calories when serving size changes
                StatefulBuilder(
                  builder: (context, setState) {
                  return Text(
                    '${(appState.currentlySelectedUserMeal.getCalories() * servingSize).ceil()}',
                    style: TextStyle(fontSize: 25),
                  );
                  },
                ),
              ],
            ),
          ),
          // Macros
          Text('Macro Nutrients', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline)),
            // Macro breakdown that updates when serving size changes
            StatefulBuilder(
            builder: (context, setState) {
              return MacroBreakdown(
              carbs: (appState.currentlySelectedUserMeal.getCarbs() * servingSize).ceil(),
              fat: (appState.currentlySelectedUserMeal.getFat() * servingSize).ceil(),
              protein: (appState.currentlySelectedUserMeal.getProtein() * servingSize).ceil(),
              );
            },
            ),
          // Options
          Text('Options', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline)),
          // Labels for inputs
            Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
              spacing: 33,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Serving Size', style: TextStyle(fontSize: 17)),
              ],
              ),
              SizedBox(width: 75),
              Column(
              spacing: 7,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                width: 150,
                height: 50,
                child: TextField(
                  decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: servingSize.toString().replaceAll('.0', ''),
                  ),
                  keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        servingSize = double.tryParse(value) ?? 1;
                      });
                  },
                ),
                ),
              ],
              ),
            ],
            ),
          // Foods in meal
          Text('Foods in Meal', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline)),
          SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...List.generate(
                  appState.currentlySelectedUserMeal.foodInMeal.length,
                  (foodIndex) {
                    final food = appState.currentlySelectedUserMeal.foodInMeal[foodIndex];
                    final isAlt = foodIndex % 2 == 0;
                    return Container(
                      decoration: BoxDecoration(
                      color: isAlt ? null : theme.colorScheme.primaryContainer ,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(food.foodData.name, style: TextStyle(fontSize: 20)),
                          Text('${(food.foodData.calories * food.serving).ceil()}', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          SizedBox(height: 25),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(width: 3, color: theme.colorScheme.primary),
            ),
            child: Text('Add to Meal', style: TextStyle(fontSize: 20)),
            onPressed: () {
              // Add this user meal to the currently selected meal in the current day
              appState.addUserMealToCurrentMeal(appState.currentlySelectedUserMeal, servingSize);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class MacroBreakdown extends StatefulWidget {
  final int? carbs;
  final int? fat;
  final int? protein;

  const MacroBreakdown({
    super.key,
    this.carbs,
    this.fat,
    this.protein,
  });

  @override
  State<MacroBreakdown> createState() => _MacroBreakdownState();
}

class _MacroBreakdownState extends State<MacroBreakdown> {

  int get carbs => widget.carbs ?? 0;
  int get fat => widget.fat ?? 0;
  int get protein => widget.protein ?? 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // var theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // spacer
        SizedBox(width: 7),
        // Text column
        Column(
          spacing: 7,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Carbs
            Text('Carbs', style: TextStyle(fontSize: 17)),
            // Fat
            Text('Fat', style: TextStyle(fontSize: 17)),
            // Protein
            Text('Protein', style: TextStyle(fontSize: 17)),
          ]
        ),
        // spacer
        SizedBox(width: 5),
        // Bar column
        Column(
          spacing: 22,
          children: [
            SizedBox(
              height: 7,
              width: 240,
              child: LinearProgressIndicator(
                // current / max
                value: carbs / appState.currentDay.maxCarbs,
                backgroundColor: const Color.fromARGB(88, 0, 197, 99),
                color: Color.fromARGB(255, 0, 197, 99),
              ),
            ),
            SizedBox(
              height: 7,
              width: 240,
              child: LinearProgressIndicator(
                // current / max
                value: fat / appState.currentDay.maxFat,
                backgroundColor: const Color.fromARGB(88, 255, 172, 64),
                color: Colors.orangeAccent,
              ),
            ),
            SizedBox(
              height: 7,
              width: 240,
              child: LinearProgressIndicator(
                // current / max
                value: protein / appState.currentDay.maxProtein,
                backgroundColor: const Color.fromARGB(88, 255, 82, 82),
                color: Colors.redAccent,
              ),
            ),
          ]
        ),
        // spacer
        SizedBox(width: 5),
        // Value column
        Column(
          spacing: 7,
          children: [
            // Carbs
            Text('${carbs} / ${appState.currentDay.maxCarbs}', style: TextStyle(fontSize: 17)),
            // Fat
            Text('${fat} / ${appState.currentDay.maxFat}', style: TextStyle(fontSize: 17)),
            // Protein
            Text('${protein } / ${appState.currentDay.maxProtein}', style: TextStyle(fontSize: 17)),
          ],
    
        ),
      ]
    );
  }
}

// ================================= Progress Page =================================

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    // var theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
            'Progress',
            style: TextStyle(fontSize: 30),
            ),
          ],
        ),
        // spacer
        SizedBox(height: 10,),
        // Today's info
        Column(
          spacing: 10,
          children: [
            Text('Today\'s Nutrition Facts', style: TextStyle(fontSize: 20, decoration: TextDecoration.underline,)),
            DailyNutritionFacts(),
          ]
        ),
        // spacer
        SizedBox(height: 10,),
        // Weight Tracking
        Column(
          spacing: 10,
          children: [
            // title
            Text('Weight Tracking', style: TextStyle(fontSize: 20, decoration: TextDecoration.underline,)),
            // warning text
            WeightWarning(),
            // graph
            WeightGraph(),
            // weight log button
            Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide())),
              child: InkWell(
                child: SizedBox(
                  width: 350,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Weight Log', style: TextStyle(fontSize: 20)),
                      Icon(Icons.arrow_right_sharp, size: 30,),
                    ],
                  )
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => WeightLogMenu()));
                }
              )
            )
          ]
        )
      ]
    );
  }
}

class WeightWarning extends StatelessWidget {
  const WeightWarning({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // var theme = Theme.of(context);
    
    return SizedBox(
      width: 330,
      height: 50,
      child: Text(
        'Note: Weight can flucuate by every day and throughout each day. Look at progress over time.',
        style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class DailyNutritionMenu extends StatelessWidget {
  const DailyNutritionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // var theme = Theme.of(context);
    
    return Scaffold
    (
      appBar: AppBar(title: Text('Today\'s Nutrition Facts'),),
      body: DailyNutritionFacts()
    );
  }
}

class DailyNutritionFacts extends StatelessWidget {
  const DailyNutritionFacts({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // var theme = Theme.of(context);

    return Column(
      spacing: 15,
      children: [
        // Calories
        Column(
          spacing: 5,
          children: [
            SizedBox(
              width: 350,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Max Calories', style: TextStyle(fontSize: 25),),
                  Text(appState.currentDay.maxCalories.toString(), style: TextStyle(fontSize: 25),),
                ]
              ),
            ),
            SizedBox(
              width: 350,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calories Used', style: TextStyle(fontSize: 25),),
                  Text(appState.currentDay.getCalories().toString(), style: TextStyle(fontSize: 25),),
                ]
              ),
            ),
            SizedBox(
              width: 350,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calories Left', style: TextStyle(fontSize: 25),),
                  Text((appState.currentDay.maxCalories - appState.currentDay.getCalories()).toString(), style: TextStyle(fontSize: 25),),
                ]
              ),
            ),
          ],
        ),
        // Macros
        Text('Macro Nutrients', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline,),),
        MacroBreakdown(
          carbs: appState.currentDay.getCarbs(),
          fat: appState.currentDay.getFat(),
          protein: appState.currentDay.getProtein(),
        ),
        // TODO - do a possible mean breakdown that shows what percentage each meal contributes to goals
        // Meal Breakdowns
        // Text('Meal Breakdowns', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline,),),
        // GridView.builder(gridDelegate: gridDelegate, itemBuilder: itemBuilder),
      ]
    );
  }
}

class WeightGraph extends StatefulWidget {
  const WeightGraph({super.key});

  @override
  State<WeightGraph> createState() => _WeightGraphState();
}

// TODO - the graph won't update the connections between the points until the page is refreshed but the dots will change
class _WeightGraphState extends State<WeightGraph> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    var gridColor = theme.inputDecorationTheme.fillColor ?? Colors.black; // grid color

    return SizedBox(
      width: 400,
      height: 400,
      child: SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        intervalType: DateTimeIntervalType.days,
        dateFormat: DateFormat('MM/dd'),
        edgeLabelPlacement: EdgeLabelPlacement.shift,
        title: AxisTitle(text: 'Date'),
        majorGridLines: MajorGridLines(color: gridColor),
      ),
      primaryYAxis: NumericAxis(
        interval: 5,
        labelFormat: '{value}',
        title: AxisTitle(text: 'Weight (lbs)'),
        minimum: appState.weightList.isNotEmpty ? appState.weightList.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 5 : 0, // minimum weight
        majorGridLines: MajorGridLines(color: gridColor),
      ),
      tooltipBehavior: TooltipBehavior(enable: false),
      series: <CartesianSeries>[
        LineSeries<WeightData, DateTime>(
        dataSource: appState.weightList,
        xValueMapper: (WeightData data, _) => data.date,
        yValueMapper: (WeightData data, _) => data.weight,
        markerSettings: MarkerSettings(isVisible: true),
        color: Colors.blue,
        ),
      ],
      ),
    );
  }
}

class WeightLogMenu extends StatefulWidget {
  const WeightLogMenu({super.key});

  @override
  State<WeightLogMenu> createState() => _WeightLogMenuState();
}

class _WeightLogMenuState extends State<WeightLogMenu> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return Scaffold
    (
      appBar: AppBar(title: Text('Weight Log'),),
      body: SizedBox(
        width: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 15,
          children: [
            SizedBox(height: 0,),
            // weight warning
            WeightWarning(),
            // list of dates
            SizedBox(
              width: 370,
              height: 630,
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: appState.weightList.length,
                itemBuilder: (context, index) {
                  return Container(
                        height: 50,
                        color: theme.colorScheme.onPrimary,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 300,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Text('   ${dates[index]}', style: TextStyle(fontSize: 17),),
                                  Text('   ${appState.weightList[index].date.month}/${appState.weightList[index].date.day}/${appState.weightList[index].date.year}', style: TextStyle(fontSize: 17),),
                                    // Text('198', style: TextStyle(fontSize: 17),),
                                    Text(
                                      appState.weightList[index].weight.toString().replaceAll(RegExp(r'\.0$'), ''),
                                      style: TextStyle(fontSize: 17),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.more_horiz),
                              onPressed: () {
                                appState.currentlySelectedWeight = appState.weightList[index]; // set the currently selected weight
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditWeightMenu())); // pass the weight data to the edit menu
                              },
                            )
                          ],
                        ),
                      );
                },
                separatorBuilder: (context, index) => const Divider(),
              ),
            ),
            // Log new weight to database button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(350, 50),
                foregroundColor: theme.colorScheme.primary, // text color
                side: BorderSide(width: 3, color: theme.colorScheme.primary)
                ),
              child: Text('Log New Weight', style: TextStyle(fontSize: 20)),
              onPressed: () => {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => LogNewWeightMenu()))
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LogNewWeightMenu extends StatefulWidget {
  const LogNewWeightMenu({super.key});

  @override
  State<LogNewWeightMenu> createState() => _LogNewWeightMenuState();
}

class _LogNewWeightMenuState extends State<LogNewWeightMenu> {
  WeightData newWeightData = WeightData(); // default weight data

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    
    return Scaffold
    (
      appBar: AppBar(title: Text('Log New Weight'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          SizedBox(height: 0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // spacer
              SizedBox(width: 20,),
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Date', style: TextStyle(fontSize: 17)),
                  Text('Weight', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Name
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}', // default to today's date
                      ),
                      onChanged: (value) {
                        // Convert the input to a date format
                        try {
                          final parts = value.split('/');
                          if (parts.length == 3) {
                            final month = int.tryParse(parts[0]) ?? DateTime.now().month;
                            final day = int.tryParse(parts[1]) ?? DateTime.now().day;
                            final year = int.tryParse(parts[2]) ?? DateTime.now().year;
                            newWeightData.date = DateTime(year, month, day, 1);
                          }
                        } catch (e) {
                          // If parsing fails, keep the default date
                        }
                      }
                    ),
                  ),
                  // Weight
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Weight',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),],
                      onChanged: (value) {
                        // Update the weight in the newWeightData as the user types
                        newWeightData.weight = double.tryParse(value) ?? 0.0;
                      },
                    )
                  ),
                ]
              )
            ],
          ),
          // Spacer
          SizedBox(height: 150,),
          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // Add the new weight data to the weight list in app state
              appState.addWeight(newWeightData),
              // Pop back to the weight log menu
              Navigator.of(context).pop(),
            },
          ),
        ]
      
      )
    );
  }
}

class EditWeightMenu extends StatefulWidget {
  const EditWeightMenu({super.key});

  @override
  State<EditWeightMenu> createState() => _EditWeightMenuState();
}

class _EditWeightMenuState extends State<EditWeightMenu> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // TODO - Initialize editedWeightData with the currently selected weight data
    // var theme = Theme.of(context);

    return Scaffold
    (
      appBar: AppBar(title: Text('Edit Weight'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          SizedBox(height: 0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // spacer
              SizedBox(width: 20,),
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Date', style: TextStyle(fontSize: 17)),
                  Text('Weight', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Name
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '${appState.currentlySelectedWeight.date.month}/${appState.currentlySelectedWeight.date.day}/${appState.currentlySelectedWeight.date.year}', // default to the date of the weight data
                      ),
                      onChanged: (value) {
                        // Convert the input to a date format
                        try {
                          final parts = value.split('/');
                          if (parts.length == 3) {
                            final month = int.tryParse(parts[0]) ?? appState.currentlySelectedWeight.date.month;
                            final day = int.tryParse(parts[1]) ?? appState.currentlySelectedWeight.date.day;
                            final year = int.tryParse(parts[2]) ?? appState.currentlySelectedWeight.date.year;
                            appState.updatedCurrentWeight(appState.currentlySelectedWeight.weight, DateTime(year, month, day, 1));
                          }
                        } catch (e) {
                          // If parsing fails, keep the default date
                        }
                      }
                    ),
                  ),
                  // Weight
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: appState.currentlySelectedWeight.weight.toString().replaceAll(RegExp(r'\.0$'), ''), // default to the weight of the weight data
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),],
                      onChanged: (value) {
                        // Update the weight in the widget.weightData as the user types
                        appState.updatedCurrentWeight(double.tryParse(value) ?? 0.0, appState.currentlySelectedWeight.date);
                      },
                    ),
                  ),
                ]
              )
            ],
          ),
          // Spacer
          SizedBox(height: 150,),
          // // Save Button
          // ElevatedButton(
          //   style: ElevatedButton.styleFrom(
          //     fixedSize: const Size(250, 50),
          //     foregroundColor: theme.colorScheme.primary, // text color
          //     side: BorderSide(width: 3, color: theme.colorScheme.primary)
          //     ),
          //   child: Text('Save', style: TextStyle(fontSize: 20)),
          //   onPressed: () => {
          //     print('finish save button for edit weight')
          //   },
          // ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
              side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14))
              ),
            child: Text('Delete', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // Remove the weight data from the weight list in app state
              appState.removeWeight(appState.currentlySelectedWeight),
              // Pop back to the weight log menu
              Navigator.of(context).pop(),
            },
          ),
        ]
      
      )
    );
  }
}

// ================================= Settings =================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // var theme = Theme.of(context);
    
    return Column(
      spacing: 10,
      children: [
        // spacer
        SizedBox(height: 0,),
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Settings',
              style: TextStyle(fontSize: 30),
            ),
          ],
        ),
        // Spacer
        SizedBox(height: 10,),
        // Calories and Macros Goals
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: InkWell(
            child: SizedBox(
              width: 350,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calories and Macro Goals', style: TextStyle(fontSize: 20)),
                  Icon(Icons.arrow_right_sharp, size: 30,),
                ],
              )
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => CaloriesAndMacrosGoalsMenu()));
            }
          )
        ),
        // Default Meals
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: InkWell(
            child: SizedBox(
              width: 350,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Default Meals', style: TextStyle(fontSize: 20)),
                  Icon(Icons.arrow_right_sharp, size: 30,),
                ],
              )
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => DefaultMealsMenu()));
            }
          )
        ),
        // Saved Foods & Meals
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: InkWell(
            child: SizedBox(
              width: 350,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved Foods & Meals', style: TextStyle(fontSize: 20)),
                  Icon(Icons.arrow_right_sharp, size: 30,),
                ],
              )
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SavedFoodsMenu()));
            }
          ),
        ),
        // weight log
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: InkWell(
            child: SizedBox(
              width: 350,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weight Log', style: TextStyle(fontSize: 20)),
                  Icon(Icons.arrow_right_sharp, size: 30,),
                ],
              )
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => WeightLogMenu()));
            }
          )
        ),
        // // Other Options
        // Container(
        //   decoration: BoxDecoration(border: Border(bottom: BorderSide())),
        //   child: InkWell(
        //     child: SizedBox(
        //       width: 350,
        //       child: Row(
        //         mainAxisSize: MainAxisSize.max,
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           Text('Other Options', style: TextStyle(fontSize: 20)),
        //           Icon(Icons.arrow_right_sharp, size: 30,),
        //         ],
        //       )
        //     ),
        //     onTap: () {
        //       // TODO - implement other options menu
        //       print('Other Options tapped');
        //     }
        //   )
        // ),
      ]
    );
  }
}

class CaloriesAndMacrosGoalsMenu extends StatefulWidget {
  const CaloriesAndMacrosGoalsMenu({super.key});

  @override
  State<CaloriesAndMacrosGoalsMenu> createState() => _CaloriesAndMacrosGoalsMenuState();
}

class _CaloriesAndMacrosGoalsMenuState extends State<CaloriesAndMacrosGoalsMenu> {

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    
    int maxCalories = appState.defaultData.dailyCalories;
    int maxCarbs = appState.defaultData.dailyCarbs;
    int maxFat = appState.defaultData.dailyFat;
    int maxProtein = appState.defaultData.dailyProtein;

    return Scaffold
    (
      appBar: AppBar(title: Text('Calories and Macro Goals'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          SizedBox(height: 0,),
          Text('Goal Info', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Max Calories', style: TextStyle(fontSize: 17)),
                  Text('Max Carbs', style: TextStyle(fontSize: 17)),
                  Text('Max Fat', style: TextStyle(fontSize: 17)),
                  Text('Max Protein', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Calories
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: maxCalories.toString(),
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        // If the value is not empty, parse it to an int
                        int temp = 0;
                        if (value.isNotEmpty) {
                          temp = int.tryParse(value) ?? 0;
                        }

                        if (temp != 0)
                        {
                          maxCalories = temp; // Update the max calories
                        }
                        else
                        {
                          maxCalories = 0; // Reset to 0 if empty
                        }
                      },
                    ),
                  ),
                  // Carbs
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: maxCarbs.toString(),
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        // If the value is not empty, parse it to an int
                        int temp = 0;
                        if (value.isNotEmpty) {
                          temp = int.tryParse(value) ?? 0;
                        }

                        if (temp != 0)
                        {
                          maxCarbs = temp; // Update the max calories
                        }
                        else
                        {
                          maxCarbs = 0; // Reset to 0 if empty
                        }
                      },
                    ),
                  ),
                  // Fat
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: maxFat.toString(),
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        // If the value is not empty, parse it to an int
                        int temp = 0;
                        if (value.isNotEmpty) {
                          temp = int.tryParse(value) ?? 0;
                        }

                        if (temp != 0)
                        {
                          maxFat = temp; // Update the max calories
                        }
                        else
                        {
                          maxFat = 0; // Reset to 0 if empty
                        }
                      },
                    ),
                  ),
                  // Protein
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: maxProtein.toString(),
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        // If the value is not empty, parse it to an int
                        int temp = 0;
                        if (value.isNotEmpty) {
                          temp = int.tryParse(value) ?? 0;
                        }

                        if (temp != 0)
                        {
                          maxProtein = temp; // Update the max calories
                        }
                        else
                        {
                          maxProtein = 0; // Reset to 0 if empty
                        }
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 200,),
          SizedBox(
            width: 320,
            child: Text(
              'Note: This will only change the goals for today and future days, but not past days.',
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // Update the default data with the new goals
              appState.setCalorieAndMacroGoals(maxCalories, maxCarbs, maxFat, maxProtein),
              // Pop back to the settings menu
              Navigator.of(context).pop(),
            },
          ),
        ]
      )
    );
  }
}

// TODO - finish implentation of the DefaultMealsMenu with creating new days on start up
class DefaultMealsMenu extends StatelessWidget {
  const DefaultMealsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // var theme = Theme.of(context);

    return Scaffold
    (
      appBar: AppBar(title: Text('Default Meals'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          // A note that this will only change the default meals for future days
          SizedBox(
            width: 320,
            child: Text(
              'Note: Changing the default meals will only change the meals for future days, not today or past days.',
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // spacer
              SizedBox(width: 20,),
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Default Daily Meals', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 15,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Daily Meals
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: appState.defaultData.meals.isEmpty ? '3' : appState.defaultData.meals.length.toString(),
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        // If the value is not empty, parse it to an int
                        int temp = 0;
                        if (value.isNotEmpty) {
                          temp = int.tryParse(value) ?? 0;
                        }

                        if (temp != 0)
                        {
                          if (temp > appState.defaultData.meals.length)
                          {
                            for (int i = appState.defaultData.meals.length; i < temp; i++)
                            {
                              // Add a new meal to the list
                              appState.defaultData.meals.add('Meal ${i + 1}');
                            }
                          }
                          else if (temp < appState.defaultData.meals.length)
                          {
                            // Remove meals from the list
                            appState.defaultData.meals.removeRange(temp, appState.defaultData.meals.length);
                          }
                          else
                          {
                            // Do nothing if the value is the same
                            return;
                          }
                        }
                        else
                        {
                          // If the value is 0, clear the list
                          appState.defaultData.meals.clear();
                        }
                      },
                    ),
                  ),
                ]
              )
            ]
          ),
          Text('Meal Data', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // spacer
              SizedBox(width: 20,),
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < appState.defaultData.meals.length; i++)
                    Text('Meal Name', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 30,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Daily Meals
                  for (var mealName in appState.defaultData.meals)
                    SizedBox(
                      width: 175,
                      height: 50,
                      child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: mealName,
                        ),
                        onChanged: (value) {
                          // Update the meal name in the list
                          appState.changeDefaultMealName(value, mealName);
                        },
                      ),
                    ),
                ]
              )
            ]
          ),
          // spacer
          SizedBox(height: 150,),
          // // Save button
          // ElevatedButton(
          //   style: ElevatedButton.styleFrom(
          //     fixedSize: const Size(250, 50),
          //     foregroundColor: theme.colorScheme.primary, // text color
          //     side: BorderSide(width: 3, color: theme.colorScheme.primary)
          //     ),
          //   child: Text('Save', style: TextStyle(fontSize: 20)),
          //   onPressed: () => {
          //     print('finish save button for default meals')
          //   },
          // ),
        ]
      )
    );
  }
}

class SavedFoodsMenu extends StatefulWidget {
  const SavedFoodsMenu({super.key});

  @override
  State<SavedFoodsMenu> createState() => _SavedFoodsMenuState();
}

class _SavedFoodsMenuState extends State<SavedFoodsMenu> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold
      (
        appBar: AppBar(
          title: Text('Saved Foods & Meals'),
          // search or scan tabs selection
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search)),
              Tab(icon: Icon(Icons.dining)),
              Tab(icon: Icon(Icons.barcode_reader)),
            ]
          ),
        ),

        body: TabBarView(
          children: [
            // Search Tab
            Column(
              spacing: 20,
              children: [
                SizedBox(height: 0,),
                // search bar
                SizedBox(
                  width: 350,
                  height: 50,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      // TODO - finish the search bar
                      hintText: 'Search Foods',
                    ),
                  ),
                ),
                // list of foods
                SizedBox(
                  width: 370,
                  height: 570,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: appState.foods.length,
                    itemBuilder: (context, index) {
                      return Container(
                        height: 50,
                        color: theme.colorScheme.onPrimary,
                        child: InkWell(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 330,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('   ${appState.foods[index].name}', style: TextStyle(fontSize: 17),),
                                      Text('${appState.foods[index].calories}', style: TextStyle(fontSize: 17),),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          onTap: () {
                            // open Nutrition facts
                            appState.currentlySelectedFood = Food(foodData: appState.foods[index]);
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditFoodMenu()));
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                  ),
                ),
                // Create new food to database button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(350, 50),
                    foregroundColor: theme.colorScheme.primary, // text color
                    side: BorderSide(width: 3, color: theme.colorScheme.primary)
                    ),
                  child: Text('Create New Food', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateNewFoodMenu()));
                  },
                ),
              ],
            ),
            // TODO - Meal Tab
            Column(
              spacing: 20,
              children: [
                SizedBox(height: 0,),
                // search bar
                SizedBox(
                  width: 350,
                  height: 50,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      // TODO - finish the search bar
                      hintText: 'Search Meals',
                    ),
                  ),
                ),
                // list of foods
                SizedBox(
                  width: 370,
                  height: 570,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: appState.userMeals.length,
                    itemBuilder: (context, index) {
                      return Container(
                        height: 50,
                        color: theme.colorScheme.onPrimary,
                        child: InkWell(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 330,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('   ${appState.userMeals[index].name}', style: TextStyle(fontSize: 17),),
                                      Text('${appState.userMeals[index].getCalories()}', style: TextStyle(fontSize: 17),),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          onTap: () {
                            // Open the meal details
                            appState.currentlySelectedUserMeal = appState.userMeals[index];
                            Navigator.of(context).push(MaterialPageRoute( builder: (context) => EditUserMeal()));
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                  ),
                ),
                // Create new food to database button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(350, 50),
                    foregroundColor: theme.colorScheme.primary, // text color
                    side: BorderSide(width: 3, color: theme.colorScheme.primary)
                    ),
                  child: Text('Create Saved Meal', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    // Navigate to the create new user meal menu
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateNewUserMeal()));
                  },
                ),
              ],
            ),
            // Scan Tab
            Scanner(),
          ]
        )
      ),
    );
  }
}

class CreateNewFoodMenu extends StatefulWidget {
  const CreateNewFoodMenu({super.key});

  @override
  State<CreateNewFoodMenu> createState() => _CreateNewFoodMenuState();
}

class _CreateNewFoodMenuState extends State<CreateNewFoodMenu> {
  FoodData tempData = new FoodData();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Create a New Food'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          SizedBox(height: 0,),
          Text('Food Info', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Food Name', style: TextStyle(fontSize: 17)),
                  Text('Calories', style: TextStyle(fontSize: 17)),
                  Text('Carbs', style: TextStyle(fontSize: 17)),
                  Text('Fat', style: TextStyle(fontSize: 17)),
                  Text('Protein', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Name
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Name',
                      ),
                      onChanged: (value) => tempData.name = value
                    ),
                  ),
                  // Calories
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Calories',
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      // parse the string to convert it to an int
                      onChanged: (value) => tempData.calories = int.tryParse(value) ?? 0
                    ),
                  ),
                  // Carbs
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Carbs',
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      // parse the string to convert it to an int
                      onChanged: (value) => tempData.carbs = int.tryParse(value) ?? 0
                    ),
                  ),
                  // Fat
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Fat',
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      // parse the string to convert it to an int
                      onChanged: (value) => tempData.fat = int.tryParse(value) ?? 0
                    ),
                  ),
                  // Protein
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Protein',
                      ),
                      // Restricts the input to number only
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      // parse the string to convert it to an int
                      onChanged: (value) => tempData.protein = int.tryParse(value) ?? 0
                    ),
                  ),
                ],
              )
            ],
          ),
          // Text('Options', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Column(
          //       spacing: 33,
          //       mainAxisAlignment: MainAxisAlignment.start,
          //       crossAxisAlignment: CrossAxisAlignment.end,
          //       children: [
          //         Text('Add to Meal?', style: TextStyle(fontSize: 17)),
          //       ],
          //     ),
          //     // spacer
          //     SizedBox(width: 50,),
          //     // Input fields
          //     Column(
          //       spacing: 7,
          //       mainAxisAlignment: MainAxisAlignment.start,
          //       crossAxisAlignment: CrossAxisAlignment.end,
          //       children: [
          //       SizedBox(
          //         width: 175,
          //         height: 50,
          //         child: DropdownButton<String>(
          //           hint: Text('Select a Meal'),
          //           items: <String>['No', 'Meal 1', 'Meal 2', 'Meal 3'].map((String value) {
          //             return DropdownMenuItem<String>(
          //               value: value,
          //               child: Text(value),
          //             );
          //           }).toList(),
          //           onChanged:(String? newValue) {
          //             // selectedValue = newValue
          //           },
          //         ),
          //       ),
          //       ],
          //     ),
          //   ],
          // ),
          // Spacer
          SizedBox(height: 75,),
          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () {
              // DEBUG - print the food data to the console
              // print('Food Name: ${tempData.name}');
              // print('Calories: ${tempData.calories}');
              // print('Carbs: ${tempData.carbs}');
              // print('Fat: ${tempData.fat}');
              // print('Protein: ${tempData.protein}');

              // Add the food to the foods list
              appState.addFoodToDatabase(tempData);
              // Navigate back to the saved foods menu and reset the tempData
              Navigator.of(context).pop();
              tempData = new FoodData();
            },
          ),
        ]
      
      )
    );
  }
}

class EditFoodMenu extends StatefulWidget {
  const EditFoodMenu({super.key});

  @override
  State<EditFoodMenu> createState() => _EditFoodMenuState();
}

class _EditFoodMenuState extends State<EditFoodMenu> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    
    FoodData tempFoodData = appState.currentlySelectedFood.foodData;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${appState.currentlySelectedFood.foodData.name}'),
        ),

      body: Column(
        spacing: 15,
        children: [
          Text(appState.currentlySelectedFood.foodData.name, style: TextStyle(fontSize: 25),),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 15,
            children: [
              SizedBox(height: 0,),
              Text('Calories and Macros', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Labels for the inputs
                  Column(
                    spacing: 33,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Calories', style: TextStyle(fontSize: 17)),
                      Text('Carbs', style: TextStyle(fontSize: 17)),
                      Text('Fat', style: TextStyle(fontSize: 17)),
                      Text('Protein', style: TextStyle(fontSize: 17)),
                    ],
                  ),
                  // spacer
                  SizedBox(width: 50,),
                  // Input fields
                  Column(
                    spacing: 7,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Calories
                      SizedBox(
                        width: 175,
                        height: 50,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: tempFoodData.calories.toString(),
                          ),
                          // Restricts the input to number only
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            tempFoodData.calories = int.tryParse(value) ?? 0; // Update the calories value
                          },
                        ),
                      ),
                      // Carbs
                      SizedBox(
                        width: 175,
                        height: 50,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: tempFoodData.carbs.toString(),
                          ),
                          // Restricts the input to number only
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            tempFoodData.carbs = int.tryParse(value) ?? 0; // Update the carbs value
                          },
                        ),
                      ),
                      // Fat
                      SizedBox(
                        width: 175,
                        height: 50,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: tempFoodData.fat.toString(),
                          ),
                          // Restricts the input to number only
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            tempFoodData.fat = int.tryParse(value) ?? 0; // Update the fat value
                          },
                        ),
                      ),
                      // Protein
                      SizedBox(
                        width: 175,
                        height: 50,
                        child: TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: tempFoodData.protein.toString(),
                          ),
                          // Restricts the input to number only
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            tempFoodData.protein = int.tryParse(value) ?? 0; // Update the protein value
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
              SizedBox(height: 200,),
              SizedBox(
                width: 320,
                child: Text(
                  'Note: This will change any instance of this food in the database, including any meals that have this food.',
                  style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(250, 50),
                  foregroundColor: theme.colorScheme.primary, // text color
                  side: BorderSide(width: 3, color: theme.colorScheme.primary)
                  ),
                child: Text('Save', style: TextStyle(fontSize: 20)),
                onPressed: () => {
                  // Update the default data with the new goals
                  appState.updateCurrentlySelectedFoodData(tempFoodData),
                  Navigator.of(context).pop(),
                },
              ),
            ]
          )
        ],
      ),
    );
  }
}

class CreateNewUserMeal extends StatefulWidget {
  const CreateNewUserMeal({super.key});

  @override
  State<CreateNewUserMeal> createState() => _CreateNewUserMealState();
}

class _CreateNewUserMealState extends State<CreateNewUserMeal> {
  UserMeal tempUserMeal = UserMeal();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Create Saved Meal'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          SizedBox(height: 0,),
          Text('Meal Info', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Meal Name', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Name
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: tempUserMeal.name.isEmpty ? 'Enter Name' : tempUserMeal.name,
                      ),
                      onChanged: (value) => setState(() {
                        tempUserMeal.name = value;
                      }),
                    ),
                  ),
                ],
              )
            ],
          ),
          // calories for the meal
          SizedBox(
            width: 350,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calories', style: TextStyle(fontSize: 20)),
                // Display the total calories for the meal
                Text('${tempUserMeal.getCalories()}', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
          // macro breakdown for the user meal
          Text('Macro Nutrients', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          MacroBreakdown(carbs: tempUserMeal.getCarbs(), fat: tempUserMeal.getFat(), protein: tempUserMeal.getProtein(),),
          // list of foods in the meal
          Text('Foods in Meal', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dynamically list foods in the meal with alternating background colors
                ...List.generate(
                  tempUserMeal.foodInMeal.length,
                  (foodIndex) {
                  final food = tempUserMeal.foodInMeal[foodIndex];
                  final isAlt = foodIndex % 2 == 0;
                  return Container(
                    decoration: BoxDecoration(
                    color: isAlt ? null : theme.colorScheme.primaryContainer ,
                    ),
                    child: InkWell(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Text(food.foodData.name, style: TextStyle(fontSize: 20), textAlign: TextAlign.left),
                      Text('${(food.foodData.calories * food.serving).ceil()}', style: TextStyle(fontSize: 20), textAlign: TextAlign.right),
                      ],
                    ),
                    onTap: () async {
                      // Set the selected food in app state if needed
                      var appState = context.read<MyAppState>();
                      appState.currentlySelectedFood = food;
                      // Navigate to FoodFactsForUserMeals for this user meal
                      await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FoodFactsForUserMeals(userMeal: tempUserMeal, foodInMeal: true,),
                      ),
                      );
                      // Refresh the UI after returning (in case food was removed)
                      setState(() {});
                    },
                    ),
                  );
                  }
                ),
                // Add button
                ElevatedButton(
                  child: Icon(Icons.add_box),
                  onPressed: () async {
                    // Navigate to the add food to meal menu and refresh after return
                    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddFoodToUserMeal(userMeal: tempUserMeal)));
                    setState(() {});
                  }
                ),
              ],
            )
          ),
          // Spacer
          SizedBox(height: 75,),
          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () {
              // Add the food to the foods list
              appState.addNewUserMeal(tempUserMeal);
              // Navigate back to the saved foods menu and reset the tempData
              Navigator.of(context).pop();
            },
          ),
        ]
      
      )
    );
  }
}

class EditUserMeal extends StatefulWidget {
  const EditUserMeal({super.key});

  @override
  State<EditUserMeal> createState() => _EditUserMealState();
}

class _EditUserMealState extends State<EditUserMeal> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Edit Meal'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 15,
        children: [
          SizedBox(height: 0,),
          Text('Meal Info', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Meal Name', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Name
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: appState.currentlySelectedUserMeal.name.isEmpty ? 'Enter Name' : appState.currentlySelectedUserMeal.name,
                      ),
                      onChanged: (value) => appState.updateCurrentlySelectedUserMealName(value),
                    ),
                  ),
                ],
              )
            ],
          ),
          // calories for the meal
          SizedBox(
            width: 350,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calories', style: TextStyle(fontSize: 20)),
                // Display the total calories for the meal
                Text('${appState.currentlySelectedUserMeal.getCalories()}', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
          // macro breakdown for the user meal
          Text('Macro Nutrients', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          MacroBreakdown(
            carbs: appState.currentlySelectedUserMeal.getCarbs(),
            fat: appState.currentlySelectedUserMeal.getFat(),
            protein: appState.currentlySelectedUserMeal.getProtein(),
          ),
          // list of foods in the meal
          Text('Foods in Meal', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dynamically list foods in the meal with alternating background colors
                ...List.generate(
                  appState.currentlySelectedUserMeal.foodInMeal.length,
                  (foodIndex) {
                  final food = appState.currentlySelectedUserMeal.foodInMeal[foodIndex];
                  final isAlt = foodIndex % 2 == 0;
                  return Container(
                    decoration: BoxDecoration(
                    color: isAlt ? null : theme.colorScheme.primaryContainer ,
                    ),
                    child: InkWell(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                      Text(food.foodData.name, style: TextStyle(fontSize: 20), textAlign: TextAlign.left),
                      Text('${(food.foodData.calories * food.serving).ceil()}', style: TextStyle(fontSize: 20), textAlign: TextAlign.right),
                      ],
                    ),
                    onTap: () async {
                      // Set the selected food in app state if needed
                      var appState = context.read<MyAppState>();
                      appState.currentlySelectedFood = food;
                      // Navigate to FoodFactsForUserMeals for this user meal
                      await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FoodFactsForUserMeals(
                        userMeal: appState.currentlySelectedUserMeal,
                        foodInMeal: true,
                        ),
                      ),
                      );
                      // Refresh the UI after returning (in case food was removed)
                      setState(() {});
                    },
                    ),
                  );
                  }
                ),
                // Add button
                ElevatedButton(
                  child: Icon(Icons.add_box),
                  onPressed: () async {
                    // Navigate to the add food to meal menu and refresh after return
                    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddFoodToUserMeal(userMeal: appState.currentlySelectedUserMeal)));
                    setState(() {});
                  }
                ),
              ],
            )
          ),
          // Spacer
          SizedBox(height: 25,),
          // Delete Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
              side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14))
              ),
            child: Text('Delete Meal', style: TextStyle(fontSize: 20)),
            onPressed: () {
              // Delete the user meal from the list
              appState.removeUserMeal(appState.currentlySelectedUserMeal);
              // Navigate back to the saved foods menu and reset the tempData
              Navigator.of(context).pop();
            },
          ),
        ]
      
      )
    );
  }
}

class AddFoodToUserMeal extends StatefulWidget {
  final UserMeal userMeal;

  const AddFoodToUserMeal({super.key, required this.userMeal});

  @override
  State<AddFoodToUserMeal> createState() => _AddFoodToUserMealState();
}

class _AddFoodToUserMealState extends State<AddFoodToUserMeal> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Food to ${widget.userMeal.name}'),
          bottom: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.search)),
            Tab(icon: Icon(Icons.barcode_reader)),
          ],
          ),
        ),
        body: TabBarView(
          children: [
          // Search Tab
          Column(
            spacing: 20,
            children: [
            SizedBox(height: 0),
            // search bar
            SizedBox(
              width: 350,
              height: 50,
              child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search',
              ),
              ),
            ),
            // list of foods
            // Use StatefulBuilder to rebuild this part when tempUserMeal changes
            StatefulBuilder(
              builder: (context, setState) {
              return SizedBox(
                width: 370,
                height: 570,
                child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: appState.foods.length,
                itemBuilder: (context, index) {
                  return Container(
                  height: 50,
                  color: theme.colorScheme.onPrimary,
                  child: InkWell(
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                      width: 330,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        Text('   ${appState.foods[index].name}', style: TextStyle(fontSize: 17)),
                        Text('${appState.foods[index].calories}', style: TextStyle(fontSize: 17)),
                        ],
                      ),
                      ),
                    ],
                    ),
                    onTap: () async {
                      // open Nutrition facts and wait for result
                      appState.currentlySelectedFood = Food(foodData: appState.foods[index]);
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => FoodFactsForUserMeals(userMeal: widget.userMeal, foodInMeal: false,),),
                      );
                      // After returning, rebuild to reflect changes in userMeal
                      setState(() {});
                    },
                  ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
                ),
              );
              },
            ),
            // Create new food to database button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(350, 50),
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(width: 3, color: theme.colorScheme.primary),
              ),
              child: Text('Create New Food', style: TextStyle(fontSize: 20)),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateNewFoodMenu()));
              },
            ),
            ],
          ),
          // Scan Tab
          Placeholder(),
          ],
        ),
      )
    );
  }
}

class FoodFactsForUserMeals extends StatefulWidget {
  final UserMeal userMeal;
  final bool foodInMeal;

  const FoodFactsForUserMeals({super.key, required this.userMeal, required this.foodInMeal});

  @override
  State<FoodFactsForUserMeals> createState() => _FoodFactsForUserMealsState();
}

class _FoodFactsForUserMealsState extends State<FoodFactsForUserMeals> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    
    // save a duplicate of the currently selected food
    Food currentlySelectedFood = appState.currentlySelectedFood;

    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrition Facts'),
      ),
      body: Column(
        spacing: 15,
        children: [
          Text(appState.currentlySelectedFood.foodData.name, style: TextStyle(fontSize: 25)),
          // Calories
          SizedBox(
            width: 350,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calories', style: TextStyle(fontSize: 25)),
                Text('${appState.currentlySelectedFood.foodData.calories * appState.currentlySelectedFood.serving}', style: TextStyle(fontSize: 25)),
              ],
            ),
          ),
          // Macros
          Text('Macro Nutrients', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline)),
          MacroBreakdown(
            carbs: (appState.currentlySelectedFood.foodData.carbs * appState.currentlySelectedFood.serving).ceil(),
            fat: (appState.currentlySelectedFood.foodData.fat * appState.currentlySelectedFood.serving).ceil(),
            protein: (appState.currentlySelectedFood.foodData.protein * appState.currentlySelectedFood.serving).ceil(),
          ),
          // Options
          Text('Options', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline)),
          // Labels for inputs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Serving Size', style: TextStyle(fontSize: 17)),
                ],
              ),
              SizedBox(width: 75),
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: appState.currentlySelectedFood.serving.toString().replaceAll('.0', ''),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      onChanged: (value) {
                        appState.servingSizeChanged(double.tryParse(value) ?? 1);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 75),
            ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(width: 3, color: theme.colorScheme.primary),
            ),
            child: Text(
                widget.foodInMeal ? 'Save' : 'Add to ${widget.userMeal.name}',
              style: TextStyle(fontSize: 20),
            ),
            onPressed: () {
              if (widget.foodInMeal) {
                // find the instance of food that was selected in the meal
                int foodIndex = widget.userMeal.foodInMeal.indexWhere((food) => food.foodData == currentlySelectedFood.foodData);
                // If the food is already in the meal, update it
                if (foodIndex != -1) {
                  // Update the serving size of the food in the meal
                  widget.userMeal.foodInMeal[foodIndex].serving = appState.currentlySelectedFood.serving;
                }
                else {
                  // If the food is not in the meal, add it
                  widget.userMeal.addFood(appState.currentlySelectedFood);
                }
              }
              else {
                // If the food is not in the meal, add it
                widget.userMeal.addFood(appState.currentlySelectedFood);
              }
              
              Navigator.of(context).pop();
            },
          ),
          // If the food is in a meal, show the remove from meal button
          if (widget.foodInMeal)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(350, 50),
                foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
                side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14))
              ),
              child: Text('Remove from Meal', style: TextStyle(fontSize: 20)),
              onPressed: () {
                // Remove the food from the meal
                widget.userMeal.removeFood(appState.currentlySelectedFood);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // var theme = Theme.of(context);

    return MobileScanner(
      controller: MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      ),
      onDetect: (scanResult) {
        String? scannedBarcode = scanResult.barcodes.first.rawValue;
        if (scannedBarcode == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to scan barcode')),
          );
          return;
        }
        else {
          appState.getFoodDataFromBarcode(scannedBarcode).then((foodData) {
          if (foodData != null) {
            Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddScannedFoodUI(scannedFoodData: foodData),
            ),
            );
          }
          }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
          });
        }
      },
    );
  }
}

class AddScannedFoodUI extends StatefulWidget {
  final FoodData scannedFoodData;

  const AddScannedFoodUI({super.key, required this.scannedFoodData});

  @override
  State<AddScannedFoodUI> createState() => _AddScannedFoodUIState();
}

class _AddScannedFoodUIState extends State<AddScannedFoodUI> {
  late FoodData tempData;

  @override
  void initState() {
    super.initState();
    // Initialize tempData with the scanned food data
    tempData = FoodData(
      name: widget.scannedFoodData.name,
      calories: widget.scannedFoodData.calories,
      carbs: widget.scannedFoodData.carbs,
      fat: widget.scannedFoodData.fat,
      protein: widget.scannedFoodData.protein,
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Add Scanned Food'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          SizedBox(height: 0,),
          Text('Food Info', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Labels for the inputs
              Column(
                spacing: 33,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Food Name', style: TextStyle(fontSize: 17)),
                  Text('Calories', style: TextStyle(fontSize: 17)),
                  Text('Carbs', style: TextStyle(fontSize: 17)),
                  Text('Fat', style: TextStyle(fontSize: 17)),
                  Text('Protein', style: TextStyle(fontSize: 17)),
                ],
              ),
              // spacer
              SizedBox(width: 50,),
              // Input fields
              Column(
                spacing: 7,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Name
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: tempData.name,
                      ),
                      controller: TextEditingController(text: tempData.name),
                      onChanged: (value) => tempData.name = value,
                    ),
                  ),
                  // Calories
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: tempData.calories.toString(),
                      ),
                      controller: TextEditingController(text: tempData.calories.toString()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => tempData.calories = int.tryParse(value) ?? 0,
                    ),
                  ),
                  // Carbs
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: tempData.carbs.toString(),
                      ),
                      controller: TextEditingController(text: tempData.carbs.toString()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => tempData.carbs = int.tryParse(value) ?? 0,
                    ),
                  ),
                  // Fat
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: tempData.fat.toString(),
                      ),
                      controller: TextEditingController(text: tempData.fat.toString()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => tempData.fat = int.tryParse(value) ?? 0,
                    ),
                  ),
                  // Protein
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: tempData.protein.toString(),
                      ),
                      controller: TextEditingController(text: tempData.protein.toString()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => tempData.protein = int.tryParse(value) ?? 0,
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 75,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
            ),
            child: Text('Save Food', style: TextStyle(fontSize: 20)),
            onPressed: () {
              appState.addFoodToDatabase(tempData);
              Navigator.of(context).pop();
            },
          ),
        ]
      )
    );
  }
}

// ================================= DATA =================================

class DayData {
  DateTime date = DateTime.now();
  int maxCalories = 2600;
  int maxProtein = 146;
  int maxFat = 67;
  int maxCarbs = 316;

  List<Meal> meals = [];

  DayData(DefaultData defaultData, {DateTime? date}) {
    // Initialize meals with default meal names
    for (var mealName in defaultData.meals) {
      meals.add(Meal()..mealName = mealName);
    }

    // Set default max values
    maxCalories = defaultData.dailyCalories;
    maxProtein = defaultData.dailyProtein;
    maxFat = defaultData.dailyFat;
    maxCarbs = defaultData.dailyCarbs;
  }

  int getCalories () {
    int calories = 0;
    for (var meal in meals) {
      calories += meal.getCalories();
    }
    return calories;
  }

  int getProtein () {
    int protein = 0;
    for (var meal in meals) {
      protein += meal.getProtein();
    }
    return protein;
  }

  int getFat () {
    int fat = 0;
    for (var meal in meals) {
      fat += meal.getFat();
    }
    return fat;
  }

  int getCarbs () {
    int carbs = 0;
    for (var meal in meals) {
      carbs += meal.getCarbs();
    }
    return carbs;
  }

  void addNewMeal(Meal meal) {
    Meal newMeal = Meal();
    newMeal.mealName = meal.mealName;
    // Copy foods from the provided meal
    for (var food in meal.foods) {
      newMeal.addNewFood(Food(
        foodData: food.foodData,
        serving: food.serving
      ));
    }
    // Add the new meal to the meals list
    meals.add(newMeal);
  }
}

class Meal {
  String mealName = "Meal";
  List<Food> foods = []; 

  Meal({this.mealName = "Meal"});

  int getCalories () {
    int calories = 0;
    for (var food in foods) {
      calories += (food.foodData.calories * food.serving).ceil();
    }
    return calories;
  }

  int getProtein () {
    int protein = 0;
    for (var food in foods) {
      protein += (food.foodData.protein * food.serving).ceil();
    }
    return protein;
  }

  int getFat () {
    int fat = 0;
    for (var food in foods) {
      fat += (food.foodData.fat * food.serving).ceil();
    }
    return fat;
  }

  int getCarbs () {
    int carbs = 0;
    for (var food in foods) {
      carbs += (food.foodData.carbs * food.serving).ceil();
    }
    return carbs;
  }

  void addNewFood(Food food) {
    Food newFood = Food(
      foodData: food.foodData,
      serving: food.serving
    );

    foods.add(newFood);
  }
}

class UserMeal {
  List<Food> foodInMeal = [];
  String name = "User Meal";

  UserMeal({this.name = "User Meal"});

  void addFood(Food food) {
    // Check if the food already exists in the meal
    foodInMeal.add(food);
  }

  int getCalories() {
    int calories = 0;
    for (var food in foodInMeal) {
      calories += food.getCalories();
    }
    return calories;
  }

  int getProtein() {
    int protein = 0;
    for (var food in foodInMeal) {
      protein += food.getProtein();
    }
    return protein;
  }

  int getFat() {
    int fat = 0;
    for (var food in foodInMeal) {
      fat += food.getFat();
    }
    return fat;
  }
  int getCarbs() {
    int carbs = 0;
    for (var food in foodInMeal) {
      carbs += food.getCarbs();
    }
    return carbs;
  }

  void removeFood(Food food) {
    for (int i = 0; i < foodInMeal.length; i++) {
      if (foodInMeal[i] == food) {
        foodInMeal.removeAt(i);
        break; // Exit loop after removing the first instance
      }
    }
  }
}

class Food {
  FoodData foodData;
  double serving;

  Food({required this.foodData, this.serving = 1.0});

  // Method to get the total calories for the food based on the serving size
  int getCalories() {
    return (foodData.calories * serving).ceil();
  }

  // Method to get the total protein for the food based on the serving size
  int getProtein() {
    return (foodData.protein * serving).ceil();
  }

  // Method to get the total fat for the food based on the serving size
  int getFat() {
    return (foodData.fat * serving).ceil();
  }

  // Method to get the total carbs for the food based on the serving size
  int getCarbs() {
    return (foodData.carbs * serving).ceil();
  }

  // Method to get the total serving size
  double getServing() {
    return serving;
  }
}

class FoodData {
  String name;
  int calories;
  int protein;
  int fat;
  int carbs;

  FoodData({
    this.name = "Unnamed Food",
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0
  });
}

class WeightData {
  DateTime date = DateTime.now();
  double weight = 160; // Default weight
}

class DefaultData {
  int dailyCalories = 2600;
  int dailyProtein = 146;
  int dailyFat = 67;
  int dailyCarbs = 316;

  List<String> meals = ['Breakfast', 'Lunch', 'Dinner'];
}
