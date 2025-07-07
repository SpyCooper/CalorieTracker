import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

void main() async{
  runApp(const Start());
}

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  State<Start> createState() => _StartState();
}

class _StartState extends State<Start> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CurrentAppState(),
      child: App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<CurrentAppState>();
    bool isDarkMode = appState.defaultData.themeMode == ThemeMode.dark;
    // wait until the app state is initialized
    if (appState.loaded == false) {
      return const Center(child: CircularProgressIndicator());
    }

    return Builder(
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
            dividerColor: Colors.transparent, // divider color for tabs
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
            dividerColor: Colors.transparent, // divider color for tabs
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
        themeMode: appState.defaultData.themeMode, // Use the theme mode from app state
        home: Stack(
          children: [
            HomePage(),
            // Floating action button to toggle light/dark mode
            Positioned(
              top: 27,
              right: 15,
              child: FloatingActionButton(
                mini: true,
                tooltip: 'Toggle Light/Dark Mode',
                backgroundColor: Colors.transparent, // Disable background color
                elevation: 0, // Remove shadow
                child: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode, // Change icon based on theme
                    color: Colors.white, // Change icon color based on theme
                ),
                onPressed: () {
                  // Toggle the theme mode
                  appState.changeTheme(!isDarkMode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Current state of the app
class CurrentAppState extends ChangeNotifier {
  // NOTE - these are updated with the database for slightly better performance
  // List of all the days
  List<DayData> days = [];
  // contains all the foods in the database
  List<FoodData> foods = [];
  // contains all the user meals
  List<UserMeal> userMeals = [];
  // weight list
  List<WeightData> weightList= [];
  WeightData currentlySelectedWeight = WeightData();

  // Database instance and IDs
  var database;
  bool loaded = false; // Flag to check if the database is loaded
  int nextFoodID = 0; // ID for the next food to be added
  int nextUserMealID = 0; // ID for the next user meal to be added
  int nextDayID = 0; // ID for the next day to be added
  int nextWeightID = 0; // ID for the next weight entry to be added
  int defaultDataID = 0; // ID for the default data row in the database

  // default data
  DefaultData defaultData = DefaultData();

  // current day data
  late DayData currentDay;
  // currently selected things
  Food currentlySelectedFood = Food(foodData: FoodData(), serving: 1);
  Meal currentlySelectedMeal = Meal();
  UserMeal currentlySelectedUserMeal = UserMeal();
  // flag to check if the add food menu is open
  bool isAddFoodMenuOpen = false;

  // constructor
  CurrentAppState() {
    // Initialize the database
    initializeDatabase();
  }

  // ----------------------------------------------------------- Database Management -----------------------------------------------------------

  //Initialize the database
  Future<void> initializeDatabase() async {
    // Get the path to the database
    database = await openDatabase(
      path.join(await getDatabasesPath(), 'calorie_tracker.db'),
      onCreate: (database, version) async {
        // Create the foodData table
        await database.execute(
          'CREATE TABLE IF NOT EXISTS foodData(id INTEGER PRIMARY KEY, name TEXT, calories INTEGER, carbs INTEGER, fat INTEGER, protein INTEGER)'
        );
        // Create the userMeals table
        await database.execute(
          'CREATE TABLE IF NOT EXISTS userMeals(id INTEGER PRIMARY KEY, name TEXT, foodInMeal TEXT)'
        );
        // Create the DayData table
        await database.execute(
          'CREATE TABLE IF NOT EXISTS dayData(id INTEGER PRIMARY KEY, date TEXT, maxCalories INTEGER, maxCarbs INTEGER, maxFat INTEGER, maxProtein INTEGER, meals TEXT)'
        );
        // Create the weightData table
        await database.execute(
          'CREATE TABLE IF NOT EXISTS weightData(id INTEGER PRIMARY KEY, weight TEXT, date TEXT)'
        );
        // Create the defaultData table
        await database.execute(
          'CREATE TABLE IF NOT EXISTS defaultData(id INTEGER PRIMARY KEY, dailyCalories INTEGER, dailyCarbs INTEGER, dailyFat INTEGER, dailyProtein INTEGER, themeMode TEXT, mealNames TEXT)'
        );
      },
      version: 1,
    );

    // DEBUG - clear the database
    // await clearDatabase();

    // Load the default data from the database
    await loadDefaultData();

    // load in the foods from the database
    matchFoodsToDatabase();

    // load in the user meals from the database
    userMeals = await getUserMealsFromDatabase();
    // set the next user meal ID based on the last user meal in the database
    if (userMeals.isNotEmpty) {
      nextUserMealID = userMeals.last.id + 1; // Increment the last user meal ID
    } else {
      nextUserMealID = 0; // Start from 0 if no user meals exist
    }

    // load in the weights from the database
    matchWeightsToDatabase();

    // load in the days from the database
    days = await getDaysFromDatabase();
    // set the next day ID based on the last day in the database
    if (days.isNotEmpty) {
      nextDayID = days.last.id + 1; // Increment the last day ID
      // Set the current day to the last day in the database
      currentDay = days.last;
    } else {
      nextDayID = 0; // Start from 0 if no days exist
      // Create a new current day with default data
      currentDay = DayData(
        id: nextDayID,
        date: DateTime.now(),
        maxCalories: defaultData.dailyCalories,
        maxCarbs: defaultData.dailyCarbs,
        maxFat: defaultData.dailyFat,
        maxProtein: defaultData.dailyProtein,
        meals: [],
      );
      changeCurrentDay(DateTime.now(), onLoad: true);
    }
    // printDaysFromDatabase(); // Print the days for debugging

    loaded = true; // Set the loaded flag to true

    notifyListeners();
  }

  // Clears all data in the database
  Future<void> clearDatabase() async {
    // Clear the foodData table
    await database.delete('foodData');
    // Reset the foods list
    foods.clear();
    nextFoodID = 0; // Reset the nextFoodID
    
    // Clear the userMeals table
    await database.delete('userMeals');
    // Reset the userMeals list
    userMeals.clear();
    nextUserMealID = 0; // Reset the nextUserMealID

    // Clear the dayData table
    await database.delete('dayData');
    // Reset the days list
    days.clear();
    nextDayID = 0; // Reset the nextDayID
    // Reset the currentDay
    changeCurrentDay(DateTime.now());

    // Clear the weightData table
    await database.delete('weightData');
    // Reset the weightList
    weightList.clear();
    nextWeightID = 0; // Reset the nextWeightID

    // Clear the defaultData table
    await database.delete('defaultData');
    // Reset the defaultData
    defaultData = DefaultData();

    notifyListeners();
  }


  // ----------------------------------------------------------- Food Management -----------------------------------------------------------

  // Add a new food to the database
  Future<void> addFoodToDatabase(FoodData food) async {
    // Set the food's id to the nextFoodID before inserting
    food.id = nextFoodID;
    
    // Insert the food into the database
    await database.insert(
      'foodData',
      food.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Match the foods list to the database
    matchFoodsToDatabase();
  }

  // Fetch all foods from the database
  Future<List<FoodData>> getFoodsFromDatabase() async {
    // Query the database for all foods
    final List<Map<String, dynamic>> maps = await database.query('foodData');

    // If the database is empty, return an empty list
    if (maps.isEmpty) {
      return [];
    }

    // Convert the maps to FoodData objects and add them to the foods list
    return [
      for (final {'id': id, 'name': name, 'calories': calories, 'carbs': carbs, 'fat': fat, 'protein': protein} in maps)
        FoodData(
          id: id,
          name: name,
          calories: calories,
          carbs: carbs,
          fat: fat,
          protein: protein,
        ),
    ];
  }

  // Delete a food from the database
  Future<void> deleteFoodFromDatabase(FoodData food) async {
    // Delete the food from the database
    await database.delete(
      'foodData',
      where: 'id = ?',
      whereArgs: [food.id],
    );

    // Match the foods list to the database
    matchFoodsToDatabase();
  }

  // Update the currently selected food's data
  Future<void> updateCurrentlySelectedFoodData(FoodData foodData) async {
    // currentlySelectedFood.foodData = foodData;
    await database.update(
      'foodData',
      foodData.toMap(),
      where: 'id = ?',
      whereArgs: [currentlySelectedFood.foodData.id],
    );

    // Match the foods list to the database
    matchFoodsToDatabase();

    notifyListeners();
  }

  void matchFoodsToDatabase() async{
    // reset the foods list
    foods = await getFoodsFromDatabase();
    // sort the foods list by name
    foods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    // reset the nextFoodID
    if (foods.isNotEmpty) {
      // find the highest ID in the foods list and increment it for the next food
      for (var food in foods) {
        if (food.id >= nextFoodID) {
          nextFoodID = food.id + 1; // Increment the last food ID
        }
      }
    } else {
      nextFoodID = 0; // Start from 0 if no foods exist
    }
    notifyListeners();
  }

  // Get food data from a barcode using Open Food Facts API
  Future<FoodData?> getFoodDataFromBarcode(String barcode) async {
    // set a UserAgent to avoid issues with the Open Food Facts API
    OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'CalorieTrackerApp');
    final ProductQueryConfiguration configuration = ProductQueryConfiguration(
      barcode,
      fields: [ProductField.ALL],
      version: ProductQueryVersion.v3,
    );
    // Fetch the product data from Open Food Facts API
    final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(configuration);
    // Check if the product was found
    if (result.status == ProductResultV3.statusSuccess) {
      // Create the food name
      String name = result.product?.productName ?? 'Unknown Product';
      String brand = result.product?.brands ?? 'Unknown Brand';
      String productName = '$brand $name';

      // Check if the product has nutritional information
      if (result.product?.nutriments != null) {
        Nutriments nutriments = result.product!.nutriments!;
        int calories = nutriments.getValue(Nutrient.energyKCal, PerSize.serving)?.round() ?? 0;
        int carbs = nutriments.getValue(Nutrient.carbohydrates, PerSize.serving)?.round() ?? 0;
        int fat = nutriments.getValue(Nutrient.fat, PerSize.serving)?.round() ?? 0;
        int protein = nutriments.getValue(Nutrient.proteins, PerSize.serving)?.round() ?? 0;
        // Create a FoodData object with the nutritional information
        FoodData foodData = FoodData(
          name: productName,
          calories: calories,
          carbs: carbs,
          fat: fat,
          protein: protein,
        );
        // return the food data
        return foodData;
      }
      else {
        throw Exception('No nutritional information available for product with barcode: $barcode');
      }
    }
    else {
      throw Exception('product not found, please insert data for $barcode');
    }
  }

  // print all foods in the database for debugging
  void printAllFoodsFromDatabase() async {
    // Query the database for all foods
    final List<Map<String, dynamic>> maps = await database.query('foodData');

    // If the database is empty, print a message
    if (maps.isEmpty) {
      print('No foods found in the database.');
      return;
    }

    // Print the foods
    for (final map in maps) {
      print('Name: ${map['name']}');
      print('ID: ${map['id']}');
    }
  }

  // ----------------------------------------------------------- Meal Management -----------------------------------------------------------

  // Add a new food to the currently selected meal
  void addNewFoodToMeal(Meal meal, Food food) {
    // Add the food to the currently selected meal
    meal.addNewFood(food);
    
    // Update the current day data (this will notify listeners)
    updateCurrentDay();
  }

  // Remove a food from the currently selected meal
  void removeFoodFromMeal(Meal meal, Food food) {
    // Remove the food from the currently selected meal
    meal.foods.remove(food);
    // Reset the currently selected food
    currentlySelectedFood = Food(foodData: FoodData(), serving: 1);
    // Reset the currently selected meal
    currentlySelectedMeal = Meal();
    
    // Update the current day data (this will notify listeners)
    updateCurrentDay();
  }

  // Change the serving size of the currently selected food
  void servingSizeChanged(double newServing) {
    // Update the serving size of the currently selected food
    currentlySelectedFood.serving = newServing;
    
    // Update the current day data (this will notify listeners)
    updateCurrentDay();
  }

  // Set the currently selected meal
  void setCurrentlySelectedMeal(Meal meal) {
    currentlySelectedMeal = meal;
    notifyListeners();
  }

  // Set the currently selected food
  void setNewMealName(String newName) {
    // Update the meal name of the currently selected meal
    currentlySelectedMeal.mealName = newName;

    // Update the current day data (this will notify listeners)
    updateCurrentDay();
  }

  // Remove a meal from the current day's meals
  void removeMeal(Meal meal, {bool futureDays = false}) {
    // Remove the meal from the current day's meals
    currentDay.meals.remove(meal);
    if (futureDays) {
      // Remove the meal from default meals for future days
      defaultData.mealNames.removeWhere((m) => m == meal.mealName);
    }
    
    // Update the current day data (this will notify listeners)
    updateCurrentDay();
  }

  // Add a meal to the current day's meals
  void addMeal(Meal meal, {bool toDefault = false}) {
    // Add the meal to the current day's meals
    Meal newMeal = Meal();
    newMeal.mealName = meal.mealName;
    newMeal.foods = meal.foods.map((food) => Food(foodData: food.foodData, serving: food.serving)).toList();
    // Add the new meal to the current day's meals
    currentDay.meals.add(newMeal);
    // Add to default meals
    if (toDefault && !defaultData.mealNames.contains(meal.mealName)) {
      defaultData.mealNames.add(meal.mealName);
    }
    
    // Update the current day data (this will notify listeners)
    updateCurrentDay();
  }

  
  // ----------------------------------------------------------- User Meals -----------------------------------------------------------

  // Add a new user meal to the list of user meals
  Future<void> addNewUserMeal(UserMeal userMeal) async{
    // Set the ID for the new user meal
    userMeal.id = nextUserMealID;

    // Add the user meal to database
    database.insert(
      'userMeals',
      userMeal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    nextUserMealID++;
    matchUserMealsToDatabase();
  }

  // Fetch all user meals from the database
  Future<List<UserMeal>> getUserMealsFromDatabase() async {
    // Query the database for all user meals
    final List<Map<String, dynamic>> maps = await database.query('userMeals');

    // If the database is empty, return an empty list
    if (maps.isEmpty) {
      return [];
    }

    // Convert the maps to UserMeal objects and add them to the userMeals list
    return [
      for (final {'id': id, 'name': name, 'foodInMeal': foodInMeal} in maps)
        UserMeal(
          id: id,
          name: name,
          foodInMeal: (foodInMeal as String).split(',').map((foodEntry) {
            final parts = foodEntry.split(':');
            if (parts.length == 2) {
              final foodId = int.tryParse(parts[0]) ?? -1;
              final serving = double.tryParse(parts[1]) ?? 1.0;

              // Find the matching FoodData in the database by id
              final dbFood = foods.firstWhere(
                (f) => f.id == foodId,
                orElse: () => FoodData(
                  id: nextFoodID++,
                  name: 'Unknown Food',
                  calories: 0,
                  carbs: 0,
                  fat: 0,
                  protein: 0,
                ),
              );

              return Food(foodData: dbFood, serving: serving);
            }
            return Food(foodData: FoodData(), serving: 1.0);
          }).toList(),
        ),
    ];
  }

  // Match the user meals list to the database
  void matchUserMealsToDatabase() async {
    // reset the user meals list
    userMeals = await getUserMealsFromDatabase();
    // sort the user meals list by name
    userMeals.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    // reset the nextUserMealID
    if (userMeals.isNotEmpty) {
      // find the highest ID in the user meals list and increment it for the next user meal
      for (var userMeal in userMeals) {
        if (userMeal.id >= nextUserMealID) {
          nextUserMealID = userMeal.id + 1; // Increment the last user meal ID
        }
      }
    } else {
      nextUserMealID = 0; // Start from 0 if no user meals exist
    }
    notifyListeners();
  }

  // Update the currently selected user meal
  Future<void> updateCurrentlySelectedUserMealData(UserMeal userMeal) async {
    // Update the user meal in the database
    await database.update(
      'userMeals',
      userMeal.toMap(),
      where: 'id = ?',
      whereArgs: [userMeal.id],
    );
    // Match the user meals list to the database
    matchUserMealsToDatabase();
  }

  // Update the name of the currently selected user meal
  Future<void> updateCurrentlySelectedUserMealName(String newName) async {
    // Update the user meal in the database
    await database.update(
      'userMeals',
      currentlySelectedUserMeal.toMap(),
      where: 'id = ?',
      whereArgs: [currentlySelectedUserMeal.id],
    );

    // Match the user meals list to the database
    matchUserMealsToDatabase();
  }

  // Remove a user meal from the database
  Future<void> deleteUserMeal(UserMeal userMeal) async {
    // Remove the user meal from the database
    await database.delete(
      'userMeals',
      where: 'id = ?',
      whereArgs: [userMeal.id],
    );

    // Match the user meals list to the database
    matchUserMealsToDatabase();
  }

  // Add a user meal to the currently selected meal with a specified serving size
  void addUserMealToCurrentMeal(UserMeal userMeal, double serving) {
    for (var food in userMeal.foodInMeal) {
      // Create a new Food object with the specified serving size
      Food newFood = Food(foodData: food.foodData, serving: food.serving * serving);
      // Add the new food to the currently selected meal
      currentlySelectedMeal.addNewFood(newFood);
    }
    
    // Update the current day data (this will notify listeners)
    updateCurrentDay();
  }

  // ----------------------------------------------------------- Weight Management -----------------------------------------------------------

  // Add a new weight to the list of weights
  Future<void> addNewWeight(WeightData weight) async {
    // Set the ID for the new weight
    weight.id = nextWeightID;

    // Add the weight to the database
    await database.insert(
      'weightData',
      weight.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Increment the next weight ID
    nextWeightID++;
    
    matchWeightsToDatabase();
  }

  // Fetch all weights from the database
  Future<List<WeightData>> getWeightsFromDatabase() async {
    // Query the database for all weights
    final List<Map<String, dynamic>> maps = await database.query('weightData');

    // If the database is empty, return an empty list
    if (maps.isEmpty) {
      return [];
    }

    // Convert the maps to WeightData objects and add them to the weightList
    return [
      for (final {'id': id, 'weight': weight, 'date': date} in maps)
        WeightData(
            id: id,
            weight: double.tryParse(weight as String) ?? 0.0, // Ensure weight is parsed correctly
            date: DateTime.parse(date as String) // Ensure date is parsed correctly
        ),
    ];
  }

  // Match the weight list to the database
  void matchWeightsToDatabase() async {
    // reset the weight list
    weightList = await getWeightsFromDatabase();
    // sort the weight list by the actual date
    await sortWeightListByDate();
    // sort the weight list by date
    // reset the last selected weight
    if (weightList.isNotEmpty) {
      // find the highest ID in the weight list and increment it for the next weight
      for (var weight in weightList) {
        if (weight.id >= nextWeightID) {
          nextWeightID = weight.id + 1; // Increment the last weight ID
        }
      }
    } else {
      currentlySelectedWeight = WeightData(); // Reset to a default empty weight
    }
    notifyListeners();
  }

  // Sort the weight list by date
  Future<void> sortWeightListByDate() async {
    weightList.sort((a,b) {
      var adate = a.date;
      var bdate = b.date;
      return adate.compareTo(bdate);
    });

    // print the sorted weight list for debugging
    // for (var weight in weightList) {
    //   print('Weight: ${weight.weight}, Date: ${weight.date}, ID: ${weight.id}');
    // }

    // put the weights in reverse order so the most recent weight is first
    weightList = weightList.reversed.toList();
  }

  // Update the currently selected weight
  Future<void> updatedCurrentWeight(double weight, DateTime date) async{
    // Update the currently selected weight's data
    currentlySelectedWeight.weight = weight;
    currentlySelectedWeight.date = date;

    // Update the weight in the database
    database.update(
      'weightData',
      currentlySelectedWeight.toMap(),
      where: 'id = ?',
      whereArgs: [currentlySelectedWeight.id],
    );

    // Match the weights list to the database
    matchWeightsToDatabase();
    
    notifyListeners();
  }

  // Remove a weight entry from the list of weights
  Future<void> removeWeight(WeightData weight) async {
    // Remove the weight from the database
    database.delete(
      'weightData',
      where: 'id = ?',
      whereArgs: [weight.id],
    );

    // Remove the weight from the weight list
    weightList.remove(weight);

    // Match the weights list to the database
    matchWeightsToDatabase();

    notifyListeners();
  }

  // ----------------------------------------------------------- Default Data Management -----------------------------------------------------------

  // Load the default data from the database
  Future<void> loadDefaultData() async {
    // Query the database for the default data
    final List<Map<String, dynamic>> maps = await database.query('defaultData');

    // If the database is empty, return an empty DefaultData object
    if (maps.isEmpty) {
      // Save the default data to the database
      defaultData = DefaultData(
        id: defaultDataID, // Use a fixed ID to ensure only one row exists
        dailyCalories: 2000,
        dailyCarbs: 275,
        dailyFat: 78,
        dailyProtein: 67,
        themeMode: ThemeMode.light,
        mealNames: ['Breakfast', 'Lunch', 'Dinner'],
      );
    }
    else {
      // Convert the map to a DefaultData object
      final Map<String, dynamic> dataMap = maps.firstWhere((map) => map['id'] == 0, orElse: () => {});
      defaultData = DefaultData(
        dailyCalories: dataMap['dailyCalories'] ?? 2000,
        dailyCarbs: dataMap['dailyCarbs'] ?? 275,
        dailyFat: dataMap['dailyFat'] ?? 78,
        dailyProtein: dataMap['dailyProtein'] ?? 67,
        themeMode: dataMap['themeMode'] == 'dark' ? ThemeMode.dark : ThemeMode.light,
        mealNames: (dataMap['mealNames'] as String?)?.split(',') ?? ['Breakfast', 'Lunch', 'Dinner'],
      );
    }

    // // Print the default data for debugging
    // printDefaultDataFromDatabase();
  }

  // Save the default data to the database
  Future<void> saveDefaultData() async {
    // check if the default data already exists in the database
    final List<Map<String, dynamic>> maps = await database.query('defaultData', where: 'id = ?', whereArgs: [defaultDataID]);
    if (maps.isNotEmpty) {
      // Update the existing default data
      await database.update(
        'defaultData',
        defaultData.toMap(),
        where: 'id = ?',
        whereArgs: [defaultDataID],
      );
    } else {
      // Insert the default data into the database
      await database.insert(
        'defaultData',
        defaultData.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // printDefaultDataFromDatabase(); // Print the default data for debugging

    // Notify listeners to update the UI
    notifyListeners();
  }

  // print all the default data from the database
  Future<void> printDefaultDataFromDatabase() async {
    // Query the database for the default data
    final List<Map<String, dynamic>> maps = await database.query('defaultData');

    // If the database is empty, print a message
    if (maps.isEmpty) {
      print('No default data found in the database.');
      return;
    }

    // Print the default data
    for (final map in maps) {
      print('Default Data:');
      print('Daily Calories: ${map['dailyCalories']}');
      print('Daily Carbs: ${map['dailyCarbs']}');
      print('Daily Fat: ${map['dailyFat']}');
      print('Daily Protein: ${map['dailyProtein']}');
      print('Theme Mode: ${map['themeMode']}');
      print('Meal Names: ${map['mealNames']}');
    }
  }

  // Set the calorie and macro goals for current and future days
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

    // Save the updated default data to the database
    saveDefaultData();
  }
  
  // Change the name of the default meal
  void changeDefaultMealName(String mealName, String defaultMeal) {
    if (defaultData.mealNames.contains(defaultMeal)) {
      int index = defaultData.mealNames.indexOf(defaultMeal);
      defaultData.mealNames[index] = mealName;
    }
    else {
      // If the default meal is not found, add it
      defaultData.mealNames.add(mealName);
    }

    // Save the updated default data to the database
    saveDefaultData();
  }

  void changeTheme(bool isDarkMode) {
    // Change the theme mode based on the isDarkMode flag
    defaultData.themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    // Save the updated default data to the database
    saveDefaultData();
  }

  // ----------------------------------------------------------- Day Management -----------------------------------------------------------

  Future<void> addDayToDatabase(DayData day) async {
    // Set the day ID to the nextDayID before inserting
    day.id = nextDayID;

    // Insert the day into the database
    await database.insert(
      'dayData',
      day.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Add the day to the days list
    days.add(day);
    nextDayID++;

    notifyListeners();
  }

  // Fetch all days from the database
  Future<List<DayData>> getDaysFromDatabase() async {
    // Query the database for all days
    final List<Map<String, dynamic>> maps = await database.query('dayData');

    // If the database is empty, return an empty list
    if (maps.isEmpty) {
      return [];
    }

    // Convert the maps to DayData objects and add them to the days list
    return [
      for (final {'id': id, 'date': date, 'maxCalories': maxCalories, 'maxCarbs': maxCarbs, 'maxFat': maxFat, 'maxProtein': maxProtein, 'meals': meals} in maps)
        DayData(
          id: id,
          date: DateTime.parse(date as String),
          maxCalories: maxCalories ?? 2000,
          maxCarbs: maxCarbs ?? 275,
          maxFat: maxFat ?? 78,
          maxProtein: maxProtein ?? 67,
          meals: (meals as String?)?.split('|').where((mealString) => mealString.isNotEmpty).map((mealString) {
            final parts = mealString.split(',').map((part) => part.trim()).toList();
            if (parts.isNotEmpty) {
              final mealName = parts[0];
              final meal = Meal(mealName: mealName);
              // check if there are any foods in the meal after the meal name
              String foodEntries = parts.sublist(1).join(','); // Join the remaining parts as food entries
              if (foodEntries.isEmpty) {
                return meal; // Return the meal with no foods
              }
              meal.foods = parts.sublist(1).map((foodEntry) {
                final foodParts = foodEntry.split(':');
                if (foodParts.length == 2) {
                  final foodId = int.tryParse(foodParts[0]) ?? -1;
                  final serving = double.tryParse(foodParts[1]) ?? 1.0;

                  final foodData = foods.firstWhere(
                    (food) => food.id == foodId,
                    orElse: () => FoodData(name: 'Deleted Food', calories: 0, carbs: 0, fat: 0, protein: 0, id: nextFoodID++),
                  );
                  return Food(foodData: foodData, serving: serving);
                }
                return Food(foodData: FoodData(), serving: 1.0);
              }).toList();
              return meal;
            }
            return Meal();
          }).toList() ?? [],
        ),
    ];
  }

  // Match the days list to the database
  void matchDaysToDatabase() async {
    // reset the days list
    days = await getDaysFromDatabase();
    // sort the days list by date
    days.sort((a, b) => a.date.compareTo(b.date));
    // reset the nextDayID
    if (days.isNotEmpty) {
      // find the highest ID in the days list and increment it for the next day
      for (var day in days) {
        if (day.id >= nextDayID) {
          nextDayID = day.id + 1; // Increment the last day ID
        }
      }
    } else {
      nextDayID = 0; // Start from 0 if no days exist
    }
    notifyListeners();
  }
  
  // Update a day in the database
  Future<void> updateDayInDatabase(DayData day) async {
    // Update the day in the database
    await database.update(
      'dayData',
      day.toMap(),
      where: 'date = ?',
      whereArgs: [day.date.toIso8601String()],
    );

    // Match the days list to the database
    matchDaysToDatabase();
  }

  Future<void> updateCurrentDay() async {
    // Update the current day's data in the database
    await updateDayInDatabase(currentDay);
    notifyListeners();
  }

  // delete a day from the database
  Future<void> deleteDayFromDatabase(DayData day) async {
    // Delete the day from the database
    await database.delete(
      'dayData',
      where: 'date = ?',
      whereArgs: [day.date.toIso8601String()],
    );

    // Remove the day from the days list
    days.remove(day);

    // Match the days list to the database
    matchDaysToDatabase();

    notifyListeners();
  }
  
  // change the current day to a specific date
  Future<void> changeCurrentDay(DateTime newDate, {bool onLoad = false}) async {
    if (onLoad)
    {
      updateCurrentDay(); // Update the current day data before changing
    }

    // Load the days from the database if not already loaded
    days = await getDaysFromDatabase();

    // check if the date already exists in the days list
    for (var day in days) {
      if (day.date.year == newDate.year && day.date.month == newDate.month && day.date.day == newDate.day) {
        // load the existing day
        currentDay = day;
        notifyListeners();
        return;
      }
    }

    // if the date does not exist, create a new day and add it to the database
    var tempDay = DayData(
      date: DateTime(newDate.year, newDate.month, newDate.day),
      maxCalories: defaultData.dailyCalories,
      maxCarbs: defaultData.dailyCarbs,
      maxFat: defaultData.dailyFat,
      maxProtein: defaultData.dailyProtein,
      meals: defaultData.mealNames.map((mealName) => Meal(mealName: mealName)).toList(),
    );
    addDayToDatabase(tempDay);
    // Add the new day to the days list
    days.add(tempDay);
    // Set the current day to the new day
    currentDay = tempDay;

    // Match the days list to the database
    matchDaysToDatabase();
  }

  Future<void> printDaysFromDatabase() async {
    // Query the database for all days
    final List<Map<String, dynamic>> maps = await database.query('dayData');

    // If the database is empty, print a message
    if (maps.isEmpty) {
      print('No days found in the database.');
      return;
    }

    // Print the days
    for (final map in maps) {
      print('Day ID: ${map['id']}');
      print('Date: ${map['date']}');
      print('Max Calories: ${map['maxCalories']}');
      print('Max Carbs: ${map['maxCarbs']}');
      print('Max Fat: ${map['maxFat']}');
      print('Max Protein: ${map['maxProtein']}');
      print('Meals: ${map['meals']}');
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
    
    // Sets the page based on the current selected page index
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

    // Get the current app state
    var appState = context.watch<CurrentAppState>();

    return Scaffold(
      appBar: AppBar(
        // Dropdown to change the current day
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
              }
            },
            dropdownColor: theme.primaryColor, // set dropdown background color
          ),
        ),
        backgroundColor: theme.primaryColor
      ),
      // Bottom navigation bar with the main pages
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem> [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.line_axis_rounded), label: 'Progress'),
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
    var appState = context.watch<CurrentAppState>();
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
              // spacer
              SizedBox(width: 5),
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
              // spacer
              SizedBox(width: 5),
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
              // spacer
              SizedBox(width: 5),
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
              // spacer
              SizedBox(width: 5),
              // Calories Left
              Column(
                children: [
                  Text(
                    'Calories Left',
                    style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
                  ),
                  Text(
                    '${appState.currentDay.maxCalories - appState.currentDay.getCalories()}',
                    style: TextStyle(
                      fontSize: 30,
                      color: (appState.currentDay.maxCalories - appState.currentDay.getCalories()) < 0
                        ? Colors.red
                        : theme.textTheme.bodyLarge?.color,
                    ),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 5,
                        children: [
                          // Sets the meal name
                          Text(widget.meal.mealName, style: TextStyle(fontSize: 30, color:theme.textTheme.bodySmall?.color), textAlign: TextAlign.left),
                          Icon(Icons.edit, color:theme.textTheme.bodySmall?.color,),
                        ],
                      ),
                      // Sets the calories for the meal
                      Text(
                        '${widget.meal.getCalories()}',
                        style: TextStyle(fontSize: 30, color:theme.textTheme.bodySmall?.color), textAlign: TextAlign.right
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  // Set the currently selected meal in app state
                  context.read<CurrentAppState>().currentlySelectedMeal = widget.meal;
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(food.foodData.name, style: TextStyle(fontSize: 20), textAlign: TextAlign.left),
                          Text('${(food.foodData.calories * food.serving).ceil()}', style: TextStyle(fontSize: 20), textAlign: TextAlign.right),
                        ],
                      ),
                    ),
                    onTap: () {
                      // Set the selected food in app state if needed
                      context.read<CurrentAppState>().currentlySelectedFood = food;
                      // Set the currently selected meal in app state
                      context.read<CurrentAppState>().currentlySelectedMeal = widget.meal;
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
                context.read<CurrentAppState>().currentlySelectedMeal = widget.meal;
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
  List<Food> foodSearchResults = []; // List to hold search results
  List<UserMeal> userMealSearchResults = []; // List to hold user meal search results
  bool isSearchActive = false; // Track if search is active
  
  @override
  void initState() {
    super.initState();
    // Set isAddFoodMenuOpen to true when the menu is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrentAppState>().isAddFoodMenuOpen = true;
    });
  }

  @override
  void deactivate() {
    // Set isAddFoodMenuOpen to false when the menu is closed
    context.read<CurrentAppState>().isAddFoodMenuOpen = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<CurrentAppState>();
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
            ],
            // when a tab is selected, it will reset the search results
            onTap: (index) {
              // Reset search results when switching tabs
              foodSearchResults.clear();
              userMealSearchResults.clear();
              isSearchActive = false; // Reset search active state
              setState(() {});
            }
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
                  child: SearchBar(
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    hintText: 'Search Foods',
                    onChanged: (query) {
                      // Perform search and update foodSearchResults
                      if (query.isNotEmpty) {
                        foodSearchResults = appState.foods
                          .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
                          .map((food) => Food(foodData: food, serving: 1))
                          .toList();
                        isSearchActive = true; // Set search active when query is not empty
                        setState(() {});
                      }
                      if (query.isEmpty) {
                        foodSearchResults.clear(); // Clear search results if query is empty
                        isSearchActive = false; // Set search inactive when query is empty
                        setState(() {});
                      }
                    },
                  ),
                ),
                // list of foods
                SizedBox(
                  width: 370,
                  height: 570,
                    child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: isSearchActive
                      ? (foodSearchResults.isEmpty ? 1 : foodSearchResults.length)
                      : appState.foods.length,
                    itemBuilder: (context, index) {
                      // If there are search results, display them instead of all foods
                      if (isSearchActive) {
                        if (foodSearchResults.length == 0) {
                          return Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'No results found',
                              style: TextStyle(fontSize: 17, color: theme.textTheme.bodyMedium?.color),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        else {
                          // Use the search result instead of the original food
                          return Container(
                            height: 50,
                            color: theme.colorScheme.primaryContainer,
                            child: InkWell(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 330,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('   ${foodSearchResults[index].foodData.name}', style: TextStyle(fontSize: 17),),
                                        Text('${foodSearchResults[index].foodData.calories}', style: TextStyle(fontSize: 17),),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // open Nutrition facts
                                appState.currentlySelectedFood = foodSearchResults[index];
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => FoodNutritionFacts()));
                              },
                            ),
                          );
                        }
                      }
                      // If no search results, display all foods
                      return Container(
                        height: 50,
                        color: theme.colorScheme.primaryContainer,
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
                    separatorBuilder: (context, index) => Divider(color: theme.colorScheme.onSurface,),
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
                  child: SearchBar(
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    hintText: 'Search Foods',
                    onChanged: (query) {
                      // Perform search and update userMealSearchResults
                      if (query.isNotEmpty) {
                        userMealSearchResults = appState.userMeals
                          .where((userMeal) => userMeal.name.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                        isSearchActive = true; // Set search active when query is not empty
                        setState(() {});
                      }
                      if (query.isEmpty) {
                        userMealSearchResults.clear(); // Clear search results if query is empty
                        isSearchActive = false; // Set search inactive when query is empty
                        setState(() {});
                      }
                    },
                  ),
                ),
                // list of user meals
                SizedBox(
                  width: 370,
                  height: 570,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: isSearchActive
                      ? (userMealSearchResults.isEmpty ? 1 : userMealSearchResults.length)
                      : appState.userMeals.length,
                    itemBuilder: (context, index) {
                      // If there are search results, display them instead of all user meals
                      if (isSearchActive) {
                        if (userMealSearchResults.length == 0) {
                          return Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'No results found',
                              style: TextStyle(fontSize: 17, color: theme.textTheme.bodyMedium?.color),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        else {
                          // Use the search result instead of the original user meals
                          return Container(
                            height: 50,
                            color: theme.colorScheme.primaryContainer,
                            child: InkWell(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 330,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('   ${userMealSearchResults[index].name}', style: TextStyle(fontSize: 17),),
                                        Text('${userMealSearchResults[index].getCalories()}', style: TextStyle(fontSize: 17),),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // open Nutrition facts
                                appState.currentlySelectedUserMeal = userMealSearchResults[index];
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => UserMealNutritionFacts()));
                              },
                            ),
                          );
                        }
                      }
                      // If no search results, display all user meals
                      return Container(
                        height: 50,
                        color: theme.colorScheme.primaryContainer,
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
          ],
        )
      ),
    );
  }
}

class EditMealMenu extends StatelessWidget {
  const EditMealMenu({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<CurrentAppState>();
    
    return Scaffold
    (
      appBar: AppBar(title: Text('Edit ${appState.currentlySelectedMeal.mealName}'),),
      body: Column(
        spacing: 15,
        children: [
          // Meal Name
          SizedBox(height: 0,),
          Text ('${appState.currentlySelectedMeal.mealName}', style: TextStyle(fontSize: 25),),
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
          SizedBox(height: 25,),
          // Remove button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
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

    return SizedBox(
      width: 300,
      height: 200,
      child: AlertDialog(
        title: const Text('Are you sure you want to remove this meal?'),
        content: const Text('This will remove the meal from today\'s meals. You can choose to remove it from future days as well.'),
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
    var appState = context.watch<CurrentAppState>();

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
    var appState = context.watch<CurrentAppState>();
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
          // Meal info header
          SizedBox(height: 0,),
          Text('Meal Info', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
          // SizedBox(height: 0,),
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
                      value: mealTypeValue,
                      hint: Text('Add Meal Type'),
                      items: mealTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged:(String? newValue) {
                        if (newValue == 'Add for Today Only') {
                          isDefaultMeal = false;
                        }
                        else if (newValue == 'Add to Daily Meals') {
                          isDefaultMeal = true;
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
          SizedBox(height: 25,),
          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
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
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);

    return Scaffold
    (
      appBar: AppBar(
        title: Text('Nutrition Facts'),
        ),

      body: Column(
        spacing: 15,
        children: [
          SizedBox(height: 0,),
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
          SizedBox(height: 25,),
          // Save Button
          if (context.read<CurrentAppState>().isAddFoodMenuOpen)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
              ),
            child: Text(
              'Add Food to Meal',
              style: TextStyle(fontSize: 20),
            ),
            onPressed: () {
              // if the user is coming from the AddFoodMenu, add the food to the meal
              if (context.read<CurrentAppState>().isAddFoodMenuOpen) {
                appState.addNewFoodToMeal(appState.currentlySelectedMeal, appState.currentlySelectedFood);
                Navigator.of(context).pop(); // Close the nutrition facts page
              } 
            },
          ),
          // Remove button
          // Only show if not coming from AddFoodMenu (i.e., currentlySelectedMeal is not empty)
          if (!context.read<CurrentAppState>().isAddFoodMenuOpen)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
              foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
              side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14)),
              ),
              child: Text('Remove Food', style: TextStyle(fontSize: 20)),
              onPressed: () {
              // Show a confirmation dialog before removing the food
              showDialog(
                context: context,
                builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Confirm Removal'),
                  content: Text('Are you sure you want to remove this food from the meal?'),
                  actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                  TextButton(
                    child: Text('Remove', style: TextStyle(color: Color.fromARGB(255, 179, 14, 14))),
                    onPressed: () {
                    // Remove the food from the meal
                    appState.removeFoodFromMeal(appState.currentlySelectedMeal, appState.currentlySelectedFood);
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Close the nutrition facts page
                    },
                  ),
                  ],
                );
                },
              );
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
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${appState.currentlySelectedUserMeal.name} Nutrition Facts')),
      body: SafeArea(
        child: ListView(
          children: [
            Column(
              spacing: 15,
              children: [
                // Meal name
                SizedBox(height: 0,),
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
                  ),
                ),
                SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(350, 50),
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
          ]
        ),
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
    var appState = context.watch<CurrentAppState>();

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
    return ListView(
      padding: EdgeInsets.all(10),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 15,
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
            // Today's info
            Column(
              spacing: 15,
              children: [
                Text('Today\'s Nutrition Facts', style: TextStyle(fontSize: 20, decoration: TextDecoration.underline,)),
                DailyNutritionFacts(),
              ]
            ),
            // Weight Tracking
            Column(
              spacing: 15,
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
                ),
                SizedBox(height: 15,),
              ]
            )
          ]
        ),
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
    return Scaffold
    (
      appBar: AppBar(title: Text('Today\'s Nutrition Facts'),),
      body: Column(
        spacing: 15,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //header
          SizedBox(height: 0,),
          Text('Today\'s Nutrition Info', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline,),),
          // spacer
          SizedBox(height: 0,),
          // Daily Nutrition Facts
          DailyNutritionFacts(),
        ],
      )
    );
  }
}

class DailyNutritionFacts extends StatelessWidget {
  const DailyNutritionFacts({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<CurrentAppState>();
    
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
      ]
    );
  }
}

class WeightGraph extends StatefulWidget {
  const WeightGraph({super.key});

  @override
  State<WeightGraph> createState() => _WeightGraphState();
}

class _WeightGraphState extends State<WeightGraph> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<CurrentAppState>();
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
    var appState = context.watch<CurrentAppState>();
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
                        color: theme.colorScheme.primaryContainer,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 300,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('   ${appState.weightList[index].date.month}/${appState.weightList[index].date.day}/${appState.weightList[index].date.year}', style: TextStyle(fontSize: 17),),
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
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);
    
    return Scaffold
    (
      appBar: AppBar(title: Text('Log New Weight'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          // Weight info header
          SizedBox(height: 0,),
          Text('Weight Info', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
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
                        }
                        catch (e) {
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
          SizedBox(height: 25,),
          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
              foregroundColor: theme.colorScheme.primary, // text color
              side: BorderSide(width: 3, color: theme.colorScheme.primary)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // Add the new weight data to the weight list in app state
              appState.addNewWeight(newWeightData),
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
    var appState = context.watch<CurrentAppState>();

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
                        }
                        catch (e) {
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
          SizedBox(height: 25,),
          // Delete Button
            ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
              foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
              side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14))
              ),
            child: Text('Delete', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                title: Text('Confirm Deletion'),
                content: Text('Are you sure you want to delete this weight entry? This action cannot be undone.'),
                actions: [
                  TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  ),
                  TextButton(
                  child: Text('Delete', style: TextStyle(color: Color.fromARGB(255, 179, 14, 14))),
                  onPressed: () {
                    // Remove the weight data from the weight list in app state
                    appState.removeWeight(appState.currentlySelectedWeight);
                    // Close the dialog and navigate back to the weight log menu
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  ),
                ],
                );
              },
              ),
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
        // Clear Data
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: InkWell(
            child: SizedBox(
              width: 350,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Clear Data', style: TextStyle(fontSize: 20)),
                  Icon(Icons.arrow_right_sharp, size: 30,),
                ],
              )
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ClearDataMenu()));
            }
          )
        )
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
    var appState = context.watch<CurrentAppState>();
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

                        // check if the value is not zero
                        if (temp > 0)
                        {
                          maxCalories = temp; // Update the max calories
                        }
                        else
                        {
                          // if the inputted value is empty, reset to original value
                          maxCalories = appState.defaultData.dailyCalories;
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

                        // check if the value is not zero
                        if (temp > 0)
                        {
                          maxCarbs = temp; // Update the max carbs
                        }
                        else
                        {
                          // if the inputted value is empty, reset to original value
                          maxCarbs = appState.defaultData.dailyCarbs;
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

                        // check if the value is not zero
                        if (temp > 0)
                        {
                          maxFat = temp; // Update the max calories
                        }
                        else
                        {
                          // if the inputted value is empty, reset to original value
                          maxFat = appState.defaultData.dailyFat;
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

                        // check if the value is not zero
                        if (temp > 0)
                        {
                          maxProtein = temp; // Update the max calories
                        }
                        else
                        {
                          // if the inputted value is empty, reset to original value
                          maxProtein = appState.defaultData.dailyProtein;
                        }
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 25,),
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
              fixedSize: const Size(350, 50),
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

class DefaultMealsMenu extends StatelessWidget {
  const DefaultMealsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<CurrentAppState>();
    
    return Scaffold
    (
      appBar: AppBar(title: Text('Default Meals'),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 15,
        children: [
          // Default meals header
          SizedBox(height: 0,),
          Text('Default Meal Info', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
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
                        hintText: appState.defaultData.mealNames.isEmpty ? '3' : appState.defaultData.mealNames.length.toString(),
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
                          if (temp > appState.defaultData.mealNames.length)
                          {
                            for (int i = appState.defaultData.mealNames.length; i < temp; i++)
                            {
                              // Add a new meal to the list
                              appState.defaultData.mealNames.add('Meal ${i + 1}');
                            }
                          }
                          else if (temp < appState.defaultData.mealNames.length)
                          {
                            // Remove meals from the list
                            appState.defaultData.mealNames.removeRange(temp, appState.defaultData.mealNames.length);
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
                          appState.defaultData.mealNames.clear();
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
                  for (int i = 0; i < appState.defaultData.mealNames.length; i++)
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
                  for (var mealName in appState.defaultData.mealNames)
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
          SizedBox(height: 25,),
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
  List<Food> foodSearchResults = []; // List to hold search results
  List<UserMeal> userMealSearchResults = []; // List to hold user meal search results
  bool isSearchActive = false; // Track if search is active
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold
      (
        appBar: AppBar(
          title: Text('Saved Foods & Meals'),
          // tabs at the bottom of the app bar
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search)),
              Tab(icon: Icon(Icons.dining)),
              Tab(icon: Icon(Icons.barcode_reader)),
            ],
            // when a tab is selected, it will reset the search results
            onTap: (index) {
              // Reset search results when switching tabs
              foodSearchResults.clear();
              userMealSearchResults.clear();
              isSearchActive = false; // Reset search active state
              setState(() {});
            }
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
                  child: SearchBar(
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    hintText: 'Search Foods',
                    onChanged: (query) {
                      // Perform search and update foodSearchResults
                      if (query.isNotEmpty) {
                        foodSearchResults = appState.foods
                          .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
                          .map((food) => Food(foodData: food, serving: 1))
                          .toList();
                        isSearchActive = true; // Set search active when query is not empty
                        setState(() {});
                      }
                      if (query.isEmpty) {
                        foodSearchResults.clear(); // Clear search results if query is empty
                        isSearchActive = false; // Set search inactive when query is empty
                        setState(() {});
                      }
                    },
                  ),
                ),
                // list of foods
                SizedBox(
                  width: 370,
                  height: 570,
                    child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: isSearchActive
                      ? (foodSearchResults.isEmpty ? 1 : foodSearchResults.length)
                      : appState.foods.length,
                    itemBuilder: (context, index) {
                      // If there are search results, display them instead of all foods
                      if (isSearchActive) {
                        if (foodSearchResults.length == 0) {
                          return Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'No results found',
                              style: TextStyle(fontSize: 17, color: theme.textTheme.bodyMedium?.color),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        else {
                          // Use the search result instead of the original food
                          return Container(
                            height: 50,
                            color: theme.colorScheme.primaryContainer,
                            child: InkWell(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 330,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('   ${foodSearchResults[index].foodData.name}', style: TextStyle(fontSize: 17),),
                                        Text('${foodSearchResults[index].foodData.calories}', style: TextStyle(fontSize: 17),),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // open Nutrition facts
                                appState.currentlySelectedFood = foodSearchResults[index];
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditFoodMenu()));
                              },
                            ),
                          );
                        }
                      }
                      // If no search results, display all foods
                      return Container(
                        height: 50,
                        color: theme.colorScheme.primaryContainer,
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
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditFoodMenu()));
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(color: theme.colorScheme.onSurface,),
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
            // Meal Tab
            Column(
              spacing: 20,
              children: [
                SizedBox(height: 0,),
                // search bar
                // search bar
                SizedBox(
                  width: 350,
                  height: 50,
                  child: SearchBar(
                    elevation: WidgetStateProperty.all(0),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    hintText: 'Search Foods',
                    onChanged: (query) {
                      // Perform search and update userMealSearchResults
                      if (query.isNotEmpty) {
                        userMealSearchResults = appState.userMeals
                          .where((userMeal) => userMeal.name.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                        isSearchActive = true; // Set search active when query is not empty
                        setState(() {});
                      }
                      if (query.isEmpty) {
                        userMealSearchResults.clear(); // Clear search results if query is empty
                        isSearchActive = false; // Set search inactive when query is empty
                        setState(() {});
                      }
                    },
                  ),
                ),
                // list of user meals
                SizedBox(
                  width: 370,
                  height: 570,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: isSearchActive
                      ? (userMealSearchResults.isEmpty ? 1 : userMealSearchResults.length)
                      : appState.userMeals.length,
                    itemBuilder: (context, index) {
                      // If there are search results, display them instead of all user meals
                      if (isSearchActive) {
                        if (userMealSearchResults.length == 0) {
                          return Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(
                              'No results found',
                              style: TextStyle(fontSize: 17, color: theme.textTheme.bodyMedium?.color),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        else {
                          // Use the search result instead of the original user meals
                          return Container(
                            height: 50,
                            color: theme.colorScheme.primaryContainer,
                            child: InkWell(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: 330,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('   ${userMealSearchResults[index].name}', style: TextStyle(fontSize: 17),),
                                        Text('${userMealSearchResults[index].getCalories()}', style: TextStyle(fontSize: 17),),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () { 
                                // open Nutrition facts
                                appState.currentlySelectedUserMeal = userMealSearchResults[index];
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditUserMeal()));
                              },
                            ),
                          );
                        }
                      }
                      // If no search results, display all user meals
                      return Container(
                        height: 50,
                        color: theme.colorScheme.primaryContainer,
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
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditUserMeal()));
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => Divider(color: theme.colorScheme.onSurface,),
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
    var appState = context.watch<CurrentAppState>();
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
          // Spacer
          SizedBox(height: 25,),
          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
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
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);
    FoodData tempFoodData = appState.currentlySelectedFood.foodData;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${appState.currentlySelectedFood.foodData.name}'),
        ),

      body: Column(
        spacing: 15,
        children: [
          SizedBox(height: 0,),
          Text(appState.currentlySelectedFood.foodData.name, style: TextStyle(fontSize: 25),),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 15,
            children: [
              // name field
              SizedBox(
                width: 350,
                height: 50,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: tempFoodData.name,
                  ),
                  onChanged: (value) {
                    tempFoodData.name = value; // Update the name value
                  },
                ),
              ),
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
              SizedBox(height: 10,),
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
                  fixedSize: const Size(350, 50),
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
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Create Saved Meal'),),
      body: SafeArea(
        child: ListView(
          children: [
            Column(
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
                                var appState = context.read<CurrentAppState>();
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
                SizedBox(height: 25,),
                // Save Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(350, 50),
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
            ),
          ]
        ),
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
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Edit Meal'),),
      body: SafeArea(
        child: ListView(
          children: [
            Column(
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
                                var appState = context.read<CurrentAppState>();
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
                  fixedSize: const Size(350, 50),
                  foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
                  side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14))
                  ),
                  child: Text('Delete Meal', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                  // Show a confirmation dialog before deleting the meal
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm Deletion'),
                      content: Text('Are you sure you want to delete this meal? This action cannot be undone.'),
                      actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        },
                      ),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: Color.fromARGB(255, 179, 14, 14))),
                        onPressed: () {
                        // Delete the user meal from the list
                        appState.deleteUserMeal(appState.currentlySelectedUserMeal);
                        // Close the dialog and navigate back
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                        },
                      ),
                      ],
                    );
                    },
                  );
                  },
                ),
              ]
            ),
          ]
        ),
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
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Food to ${widget.userMeal.name}'),
          // Tabs at the bottom of the app bar
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
                            color: theme.colorScheme.primaryContainer,
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
    var appState = context.watch<CurrentAppState>();
    var theme = Theme.of(context);

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
          SizedBox(height: 25),
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
              // add the food to the user meal
              widget.userMeal.addFood(appState.currentlySelectedFood);
              appState.updateCurrentlySelectedUserMealData(widget.userMeal);
              
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
              // Show a confirmation dialog before removing the food
              showDialog(
                context: context,
                builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Confirm Removal'),
                  content: Text('Are you sure you want to remove this food from the meal?'),
                  actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                  TextButton(
                    child: Text('Remove', style: TextStyle(color: Color.fromARGB(255, 179, 14, 14))),
                    onPressed: () {
                    // Remove the food from the meal
                    widget.userMeal.removeFood(appState.currentlySelectedFood);
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Close the nutrition facts page
                    },
                  ),
                  ],
                );
                },
              );
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
    var appState = context.watch<CurrentAppState>();
    
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
    var appState = context.watch<CurrentAppState>();
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
          SizedBox(height: 25,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(350, 50),
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

class ClearDataMenu extends StatelessWidget {
  const ClearDataMenu({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clear Data'),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          spacing: 15,
          children: [
            SizedBox(height: 0,),
            Text('Are you sure you want to clear all data?', style: TextStyle(fontSize: 20), textAlign: TextAlign.center,),
            SizedBox(
              width: 350,
              child: Text(
                'All user data is saved locally and is not collected. Deleting user data will wipe all days, foods, user meals, weights, and user settings',
                style: TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 25,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(350, 50),
                foregroundColor: Color.fromARGB(255, 179, 14, 14), // text color
                side: BorderSide(width: 3, color: Color.fromARGB(255, 179, 14, 14))
              ),
              child: Text('Clear Data', style: TextStyle(fontSize: 20)),
              onPressed: () {
                // Show the warning pop-up
                showDialog(
                  context: context,
                  builder: (context) => ClearDataWarningPopUp(),
                ).then((value) {
                  // pop the dialog and return to the previous screen
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ClearDataWarningPopUp extends StatefulWidget {
  const ClearDataWarningPopUp({super.key});

  @override
  State<ClearDataWarningPopUp> createState() => _ClearDataWarningPopUpState();
}

class _ClearDataWarningPopUpState extends State<ClearDataWarningPopUp> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<CurrentAppState>();
    return AlertDialog(
      title: Text('Clear Data Warning'),
      content: Text(
        'Are you sure you want to clear all data? This action cannot be undone.',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // show another confirmation dialog
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Confirm Clear Data'),
                content: Text('This will delete all user data. Are you absolutely sure?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false), // Cancel
                    child: Text('No, Go Back'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Clear all data in the app state
                      appState.clearDatabase();
                      // Close the dialog and return to the previous screen
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Close the warning dialog
                    },
                    child: Text('Yes, Clear Data', style: TextStyle(color: Color.fromARGB(255, 179, 14, 14))),
                  ),
                ],
              ),
            );
          },
          child: Text('Clear Data', style: TextStyle(color: Color.fromARGB(255, 179, 14, 14))),
        ),
      ],
    );
  }
}

// ================================= DATA =================================

class DayData {
  int id = 0; // Unique identifier for the day
  DateTime date = DateTime.now();
  int maxCalories = 2000;
  int maxProtein = 67;
  int maxFat = 78;
  int maxCarbs = 275;

  List<Meal> meals = [];

  // DayData(DefaultData defaultData, {DateTime? date}) {
  //   // Initialize meals with default meal names
  //   for (var mealName in defaultData.mealNames) {
  //     meals.add(Meal()..mealName = mealName);
  //   }

  //   // Set default max values
  //   maxCalories = defaultData.dailyCalories;
  //   maxProtein = defaultData.dailyProtein;
  //   maxFat = defaultData.dailyFat;
  //   maxCarbs = defaultData.dailyCarbs;
  // }

  DayData({
    this.id = 0,
    required this.date,
    this.maxCalories = 2000,
    this.maxProtein = 67,
    this.maxFat = 78,
    this.maxCarbs = 275,
    List<Meal>? meals,
  }) : meals = meals ?? [];

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
      newMeal.addNewFood(Food(foodData: food.foodData, serving: food.serving));
    }
    // Add the new meal to the meals list
    meals.add(newMeal);
  }

  Map<String, Object> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'maxCalories': maxCalories,
      'maxProtein': maxProtein,
      'maxFat': maxFat,
      'maxCarbs': maxCarbs,
      'meals': meals.map((meal) => '${meal.mealName},${meal.foods.map((food) => '${food.foodData.id}:${food.serving}').join(',')}').join('|'),
    };
  }

  @override
  String toString() {
    return 'DayData{id: $id, date: $date, maxCalories: $maxCalories, maxProtein: $maxProtein, maxFat: $maxFat, maxCarbs: $maxCarbs, meals: $meals}';
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
  String name;
  int id; // Unique identifier for the user meal

  UserMeal({this.name = "User Meal", this.id = 0, 
    List<Food>? foodInMeal}) : foodInMeal = foodInMeal ?? [];

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

  // Convert UserMeal to a map for database storage
  Map<String, Object> toMap() {
    return {
      'id': id,
      'name': name,
      'foodInMeal': foodInMeal.map((food) => '${food.foodData.id}:${food.serving}').join(','),
    };
  }

  @override
  String toString() {
    return 'UserMeal{id: $id, name: $name, foodInMeal: $foodInMeal}';
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
  int id; // Unique identifier for the food
  String name;
  int calories;
  int protein;
  int fat;
  int carbs;

  FoodData({
    this.id = 0,
    this.name = "Unnamed Food",
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0
  });

  // Convert FoodData to a map for database storage
  Map<String, Object> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }

  @override
  String toString() {
    return 'FoodData{id: $id, name: $name, calories: $calories, protein: $protein, fat: $fat, carbs: $carbs}';
  }
}

class WeightData {
  int id; // Unique identifier for the weight data
  DateTime date;
  double weight; // Default weight

  WeightData({this.id = 0, DateTime? date, this.weight = 160}) : date = date ?? DateTime.now();

  // Convert WeightData to a map for database storage
  Map<String, Object> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
    };
  }

  @override
  String toString() {
    return 'WeightData{id: $id, date: ${date.toIso8601String()}, weight: $weight}';
  }
}

class DefaultData {
  int id = 0; // Unique identifier for the default data
  int dailyCalories = 2000;
  int dailyProtein = 67;
  int dailyFat = 78;
  int dailyCarbs = 275;
  ThemeMode themeMode = ThemeMode.light;

  List<String> mealNames;

  DefaultData({
    this.id = 0,
    this.dailyCalories = 2000,
    this.dailyProtein = 67,
    this.dailyFat = 78,
    this.dailyCarbs = 275,
    this.themeMode = ThemeMode.light,
    List<String>? mealNames,
  }) : mealNames = mealNames ?? ['Breakfast', 'Lunch', 'Dinner'];

  // Convert DefaultData to a map for database storage
  Map<String, Object> toMap() {
    return {
      'id': id,
      'dailyCalories': dailyCalories,
      'dailyProtein': dailyProtein,
      'dailyFat': dailyFat,
      'dailyCarbs': dailyCarbs,
      'themeMode': themeMode == ThemeMode.dark ? 'dark' : 'light',
      'mealNames': mealNames.join(','),
    };
  }

  @override
  String toString() {
    return 'DefaultData{id: $id, dailyCalories: $dailyCalories, dailyProtein: $dailyProtein, dailyFat: $dailyFat, dailyCarbs: $dailyCarbs, themeMode: $themeMode, mealNames: $mealNames}';
  }
}