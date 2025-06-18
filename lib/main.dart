import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Calorie Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)
        ),
        home: HomePage()
      ),
    );
  }
}

// Current state of the app
class MyAppState extends ChangeNotifier {
  // contains all the foods in the database
  List<FoodData> foods = [];

  // default data
  DefaultData defaultData = DefaultData();

  // current day data
  late DayData currentDay;

  Food currentlySelectedFood = Food(foodData: FoodData(), serving: 1);
  Meal currentlySelectedMeal = Meal();

  bool isAddFoodMenuOpen = false;

  // constructor
  MyAppState() {
    currentDay = DayData(defaultData);
  }

  void addFoodToDatabase(FoodData food) {
    foods.add(food);
    notifyListeners();
  }

  void addNewFoodToMeal(Meal meal, Food food) {
    // Add the food to the currently selected meal
    meal.addNewFood(food);
    // Reset the currently selected food


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
    currentDay.meals.add(meal);
    // Optionally add to default meals if not already present
    if (toDefault && !defaultData.meals.contains(meal.mealName)) {
      defaultData.meals.add(meal.mealName);
    }
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

    return Scaffold(
      appBar: AppBar(
        // set the title to today's date
        title: Text('${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}', textAlign: TextAlign.center,),
        backgroundColor: Colors.blueGrey
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
        selectedItemColor: Colors.amber[800],
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

    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // spacer
        SizedBox(height: 0,),
        // Calories Header
        InkWell(
          // TODO - Possibly change this to a bar instead of numbers
          child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Max calories
            Column(
            children: [
              Text(
              'Max Calories',
              style: TextStyle(fontSize: 15),
              ),
              Text(
              '${appState.defaultData.dailyCalories}',
              style: TextStyle(fontSize: 30),
              ),
            ]
            ),
            // minus
            Column(
            children: [
              Text(
              '',
              style: TextStyle(fontSize: 15),
              ),
              Text(
              '-',
              style: TextStyle(fontSize: 30),
              ),
            ]
            ),
            // Calories Used
            Column(
            children: [
              Text(
              'Calories Used',
              style: TextStyle(fontSize: 15),
              ),
              Text(
                // TODO - this needs to calculate the calories used from the meals
              '${appState.currentDay.getCalories()}',
              style: TextStyle(fontSize: 30),
              ),
            ]
            ),
            // equals
            Column(
            children: [
              Text(
              '',
              style: TextStyle(fontSize: 15),
              ),
              Text(
              '=',
              style: TextStyle(fontSize: 30),
              ),
            ]
            ),
            // Calories Left
            Column(
            children: [
              Text(
              'Calories Left',
              style: TextStyle(fontSize: 15),
              ),
              Text(
                // TODO - this needs to calculate the calories left from the meals
              '${appState.defaultData.dailyCalories - appState.currentDay.getCalories()}',
              style: TextStyle(fontSize: 30),
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
          child: Text('Add new meal', style: TextStyle(fontSize: 20)),
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black)
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
                color: Colors.blueGrey,
              ),
              child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 5,
                      children: [
                        // sets the meal name
                        Text(widget.meal.mealName, style: TextStyle(fontSize: 30, color: Colors.white), textAlign: TextAlign.left),
                        Icon(Icons.edit, color: const Color.fromARGB(255, 87, 87, 87),),
                      ],
                    ),
                    // sets the calories for the meal
                    Text(
                      '${widget.meal.getCalories()}',
                      style: TextStyle(fontSize: 30, color: Colors.white), textAlign: TextAlign.right
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
              final isGrey = foodIndex % 2 == 0;
              return Container(
                decoration: BoxDecoration(
                color: isGrey ? const Color.fromARGB(255, 219, 219, 219) : null,
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
              child: Icon(Icons.add_box),
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

    return DefaultTabController(
      length: 2,
      child: Scaffold
      (
        appBar: AppBar(
          // TODO - change the 'meal' to show what meal the food would be added to
          title: Text('Add New Food to Meal'),
          // search or scan tabs selection
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search)),
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
                      // TODO - change the hint text to default to the meal name
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
                        color: const Color.fromARGB(169, 207, 207, 207),
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
                    foregroundColor: Colors.blueAccent, // text color
                    side: BorderSide(width: 3, color: Colors.blueAccent)
                    ),
                  child: Text('Create New Food', style: TextStyle(fontSize: 20)),
                  onPressed: () => {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateNewFoodMenu()))
                  },
                ),
              ],
            ),
            // Scan Tab
            Placeholder(),
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

    return Scaffold
    (
      // TODO - change name of the meal bar to be the meal
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
          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Colors.blueAccent, // text color
              side: BorderSide(width: 3, color: Colors.blueAccent)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // TODO - save button
              print('finish save button for edit meal')
            },
          ),
          // Remove button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Colors.red, // text color
              side: BorderSide(width: 3, color: Colors.red)
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
              print(appState.currentDay.meals);
              print(appState.defaultData.meals);
              // pop all the way back to the home page
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // Remove from daily meals
          TextButton(
            child: Text('Future Days'),
            onPressed:() {
              appState.removeMeal(appState.currentlySelectedMeal, futureDays: true);
              print(appState.currentDay.meals);
              print(appState.defaultData.meals);
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
              foregroundColor: Colors.blueAccent, // text color
              side: BorderSide(width: 3, color: Colors.blueAccent)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
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

// TODO - the Food that is currently selected's serving size changes even when the save button is NOT pressed
class _FoodNutritionFactsState extends State<FoodNutritionFacts> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold
    (
      appBar: AppBar(
        title: Text('${appState.currentlySelectedFood.foodData.name} Nutrition Facts'),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Colors.blueAccent, // text color
              side: BorderSide(width: 3, color: Colors.blueAccent)
              ),
            child: Text(
              context.read<MyAppState>().isAddFoodMenuOpen ? 'Add Food to Meal' : 'Save',
              style: TextStyle(fontSize: 20),
            ),
            onPressed: () {
              // if the user is coming from the AddFoodMenu, add the food to the meal
              if (context.read<MyAppState>().isAddFoodMenuOpen) {
                appState.addNewFoodToMeal(appState.currentlySelectedMeal, appState.currentlySelectedFood);
                Navigator.of(context).pop(); // Close the nutrition facts page
              } 
              else
              {
                // TODO - save button for adjusting the inputted serving size and meal
                print('finish save button for adjusting the inputted serving size and meal');
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
              foregroundColor: Colors.red, // text color
              side: BorderSide(width: 3, color: Colors.red)
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

// TODO - this only works with foods right now and not meals or days
class _MacroBreakdownState extends State<MacroBreakdown> {

  int get carbs => widget.carbs ?? 0;
  int get fat => widget.fat ?? 0;
  int get protein => widget.protein ?? 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

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
                value: carbs / appState.defaultData.dailyCarbs,
                backgroundColor: const Color.fromARGB(88, 0, 197, 99),
                color: Color.fromARGB(255, 0, 197, 99),
              ),
            ),
            SizedBox(
              height: 7,
              width: 240,
              child: LinearProgressIndicator(
                // current / max
                value: fat / appState.defaultData.dailyFat,
                backgroundColor: const Color.fromARGB(88, 255, 172, 64),
                color: Colors.orangeAccent,
              ),
            ),
            SizedBox(
              height: 7,
              width: 240,
              child: LinearProgressIndicator(
                // current / max
                value: protein / appState.defaultData.dailyProtein,
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
            Text('${carbs} / ${appState.defaultData.dailyCarbs}', style: TextStyle(fontSize: 17)),
            // Fat
            Text('${fat} / ${appState.defaultData.dailyFat}', style: TextStyle(fontSize: 17)),
            // Protein
            Text('${protein } / ${appState.defaultData.dailyProtein}', style: TextStyle(fontSize: 17)),
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
      // TODO - change name of the meal bar to be the meal
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

class WeightGraph extends StatelessWidget {
  const WeightGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 400,
      child: LineChart(
        LineChartData( 
          // disables a border around the graph
          borderData: FlBorderData(show: false),
          // labels
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 40
              ),
            ),
            topTitles: AxisTitles(), // defaults to nothing
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5, // comment this to get the graph to auto scale
                reservedSize: 40
              ),
            ),
            rightTitles: AxisTitles(), // defaults to nothing
          ),
          // Intervale for the grid
          gridData: FlGridData(
            horizontalInterval: 5,
            verticalInterval: 1,
          ),
          // disables the user from touching the graph
          lineTouchData: LineTouchData(enabled: false),
          // Data for the graph
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 280), FlSpot(1, 270), FlSpot(2, 275), FlSpot(3, 260),
              ],
            ),
          ],
        ), 
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
  final List<String> dates = <String>['10/24', '10/25', '10/26', '10/27','10/28', '10/29', '10/30', '10/31','11/1', '11/11', '11/12', '11/13', '11/14', '11/16'];

  @override
  Widget build(BuildContext context) {
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
                // TODO - change based on the size of the lists
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  return Container(
                        height: 50,
                        color: const Color.fromARGB(169, 207, 207, 207),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 300,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('   ${dates[index]}', style: TextStyle(fontSize: 17),),
                                  Text('198', style: TextStyle(fontSize: 17),),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.more_horiz),
                              onPressed: () {
                                // TODO - edit weight
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditWeightMenu()));
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
                foregroundColor: Colors.blueAccent, // text color
                side: BorderSide(width: 3, color: Colors.blueAccent)
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

class LogNewWeightMenu extends StatelessWidget {
  const LogNewWeightMenu({super.key});

  @override
  Widget build(BuildContext context) {
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
                        hintText: 'mm/dd/yyyy',
                      ),
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
                    ),
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
              foregroundColor: Colors.blueAccent, // text color
              side: BorderSide(width: 3, color: Colors.blueAccent)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // TODO - save button
              print('finish save button for log new weight')
            },
          ),
        ]
      
      )
    );
  }
}

class EditWeightMenu extends StatelessWidget {
  const EditWeightMenu({super.key});

  @override
  Widget build(BuildContext context) {
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
                        // TODO - default to already existing value
                        hintText: '12/21/2024',
                      ),
                    ),
                  ),
                  // Weight
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        // TODO - default to already existing value
                        hintText: '191',
                      ),
                    ),
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
              foregroundColor: Colors.blueAccent, // text color
              side: BorderSide(width: 3, color: Colors.blueAccent)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // TODO - save button
              print('finish save button for edit weight')
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Colors.red, // text color
              side: BorderSide(width: 3, color: Colors.red)
              ),
            child: Text('Delete', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // TODO - delete button
              print('finish delete button for edit weight')
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
        // Option 1
        // NOTE: only option 1 needs the top and bottom borders, all other should only have a bottom border
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
        // Option 2
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
        // Option 3
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: InkWell(
            child: SizedBox(
              width: 350,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Saved Foods', style: TextStyle(fontSize: 20)),
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
      ]
    );
  }
}

class CaloriesAndMacrosGoalsMenu extends StatelessWidget {
  const CaloriesAndMacrosGoalsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      // TODO - change name of the meal bar to be the meal
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
                        hintText: 'Enter Calories',
                      ),
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
              foregroundColor: Colors.blueAccent, // text color
              side: BorderSide(width: 3, color: Colors.blueAccent)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // TODO - save button
              print('finish save button for calories and macros goals')
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
                  for (var mealName in appState.defaultData.meals)
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
          // Save button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(250, 50),
              foregroundColor: Colors.blueAccent, // text color
              side: BorderSide(width: 3, color: Colors.blueAccent)
              ),
            child: Text('Save', style: TextStyle(fontSize: 20)),
            onPressed: () => {
              // TODO - save button
              print('finish save button for default meals')
            },
          ),
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

// TODO - saved foods needs to go to a different UI so foods can be edited
class _SavedFoodsMenuState extends State<SavedFoodsMenu> {
  // TODO - figure out a way to make this work more seemlessly with the add food menu

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return DefaultTabController(
      length: 2,
      child: Scaffold
      (
        appBar: AppBar(
          // TODO - change the 'meal' to show what meal the food would be added to
          title: Text('Saved Foods'),
          // search or scan tabs selection
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search)),
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
                      // TODO - change the hint text to default to the meal name
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
                        color: const Color.fromARGB(169, 207, 207, 207),
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
                    foregroundColor: Colors.blueAccent, // text color
                    side: BorderSide(width: 3, color: Colors.blueAccent)
                    ),
                  child: Text('Create New Food', style: TextStyle(fontSize: 20)),
                  onPressed: () => {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateNewFoodMenu()))
                  },
                ),
              ],
            ),
            // Scan Tab
            Placeholder(),
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
          //           // TODO - default the value to be no
          //           hint: Text('Select a Meal'),
          //           // TODO - Change this to show the meals that are available
          //           items: <String>['No', 'Meal 1', 'Meal 2', 'Meal 3'].map((String value) {
          //             return DropdownMenuItem<String>(
          //               value: value,
          //               child: Text(value),
          //             );
          //           }).toList(),
          //           // TODO - finish the changes
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
              foregroundColor: Colors.blueAccent, // text color
              side: BorderSide(width: 3, color: Colors.blueAccent)
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


// ================================= DATA =================================

class DayData {
  DateTime date = DateTime.now();
  int maxCalories = 2600;
  int maxProtein = 146;
  int maxFat = 67;
  int maxCarbs = 316;

  List<Meal> meals = [];

  DayData(DefaultData defaultData) {
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
    meals.add(meal);
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
    // Check if the food already exists in the meal
    foods.add(food);
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

class WeightList {
  List<WeightData> weights = [];
}

class WeightData {
  DateTime date = DateTime.now();
  int weight = 999;
}

class DefaultData {
  int dailyCalories = 2600;
  int dailyProtein = 146;
  int dailyFat = 67;
  int dailyCarbs = 316;

  List<String> meals = ['Breakfast', 'Lunch', 'Dinner'];
}
