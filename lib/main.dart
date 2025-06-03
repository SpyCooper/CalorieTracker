// import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)
      ),
      home: HomePage()
    );
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
        title: Text('September 22, 2025', textAlign: TextAlign.center,),
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
    
    body: ListView(
      children: [
        page
      ]
    ),

    resizeToAvoidBottomInset: false,
    );
  }
}

class MealsPage extends StatelessWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(
      spacing: 25,
      children: [
        // spacer
        SizedBox(height: 0,),
        // Calories Header
        InkWell(
          // TODO - Possibly change this to a bar instead of numbers
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
              // Total calories
              Column(
                children: [
                  Text(
                    'Total Calories',
                    style: TextStyle(fontSize: 15),
                  ),
                  Text(
                    '2000',
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
                    '0',
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
                    '2000',
                    style: TextStyle(fontSize: 30),
                  ),
                ]
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => NutritionFacts()));
          }
        ),
        // TODO - create meals from the day's meals
        // MEAL 1
        Container(
          child: MealBox()
        ),
        // MEAL 2
        Container(
          child: MealBox()
        ),
        // MEAL 3
        Container(
          child: MealBox()
        ),
        // Add new meal button
        Container(
          child: Column(
            children: [
              ElevatedButton(
                child: Text('Add new meal', style: TextStyle(fontSize: 20)),
                // Icon(Icons.add_box),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddNewMeal()));
                }
              )
            ]
          )
        ),
      ]
    );
  }
}

/*
Meal requires:
name - name of the meal
food list - list of the food in the meal
*/

class MealBox extends StatelessWidget {
  const MealBox({
    super.key,
  });

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Meal 1', style: TextStyle(fontSize: 30, color: Colors.white), textAlign: TextAlign.left),
                      IconButton(
                        icon: Icon(Icons.edit),
                        // TODO - edit meal
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditMealMenu()));
                        }
                      )
                    ],
                  ),
                  // TODO - calories needs to calculate this based on the food in the meal
                  InkWell(
                    child: Text(
                      '400',
                      style: TextStyle(fontSize: 30, color: Colors.white), textAlign: TextAlign.right
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => NutritionFacts()));
                    }
                  ),
                ],
              )
            ),
            // TODO - every other entry needs to have a grey background
            // Entry 1
            Container(
              decoration: BoxDecoration(
                // border: Border.all(color: Colors.black),
                color: const Color.fromARGB(255, 219, 219, 219)
              ),
              child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TODO - get the info from a food object
                    Text('Food 1', style: TextStyle(fontSize: 20), textAlign: TextAlign.left),
                    Text('200', style: TextStyle(fontSize: 20), textAlign: TextAlign.right),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => NutritionFacts()));
                }
              )
            ),
            // Entry 2
            Container(
              decoration: BoxDecoration(
                // border: Border.all(color: Colors.black),
              ),
              child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TODO - get the info from a food object
                    Text('Food 2', style: TextStyle(fontSize: 20), textAlign: TextAlign.left),
                    Text('200', style: TextStyle(fontSize: 20), textAlign: TextAlign.right),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => NutritionFacts()));
                }
              )
            ),
            // Entry 3
            Container(
              decoration: BoxDecoration(
                // border: Border.all(color: Colors.black),
                color: const Color.fromARGB(255, 219, 219, 219)
              ),
              child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TODO - get the info from a food object
                    Text('Food 1', style: TextStyle(fontSize: 20), textAlign: TextAlign.left),
                    Text('200', style: TextStyle(fontSize: 20), textAlign: TextAlign.right),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => NutritionFacts()));
                }
              )
            ),
            // Add button
            ElevatedButton(
              child: Icon(Icons.add_box),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddFoodMenu()));
              }
            ),
          ],
        )
      )
    );
  }
}

class AddFoodMenu extends StatelessWidget {
  const AddFoodMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      // TODO - change name of the meal bar to be the meal
      appBar: AppBar(title: Text('Add new food to meal'),),

      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('finish list of foods', style: TextStyle(fontSize: 30))
          ],
        )
      )
    );
  }
}

class EditMealMenu extends StatelessWidget {
  const EditMealMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      // TODO - change name of the meal bar to be the meal
      appBar: AppBar(title: Text('Edit Meal 1'),),
      body: Container(
        child: Column(
          spacing: 15,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Labels for the inputs
                Column(
                  spacing: 30,
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
                          // TODO - change the hint text to default to the meal name
                          hintText: 'Name',
                        ),
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
      )
    );
  }
}

// TODO - implement a pop up to remove a meal from the meal list
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
              // TODO - remove the meal just for today
              Navigator.pop(context, 'Today Only');
            },
          ),
          // Remove from daily meals
          TextButton(
            child: Text('Future Days'),
            onPressed:() {
              // TODO - remove from daily meals
              Navigator.pop(context, 'From Future Days');
            },
          ),
        ],
      ),
    );
  }
}


class AddNewMeal extends StatelessWidget {
  const AddNewMeal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      appBar: AppBar(title: Text('Add New Meal'),),
      body: Container(
        child: Column(
          spacing: 15,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Labels for the inputs
                Column(
                  spacing: 30,
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
                          hintText: 'Name',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 175,
                      height: 50,
                      child: DropdownButton<String>(
                          hint: Text('Add Meal Type'),
                          // TODO - implement changing daily meals based on the day's meal and clean this up
                          items: <String>['Add for Today Only', 'Add to Daily Meals'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          
                          // TODO - change the state for the selected meal type
                          onChanged:(String? newValue) {
                            // selectedValue = newValue;
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
                // TODO - save button
                print('finish save button for add new meal')
              },
            ),
          ]
        )
      )
    );
  }
}

class NutritionFacts extends StatelessWidget {
  const NutritionFacts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      // TODO - change name to show the name of the food, meal, or day
      appBar: AppBar(
        title: Text('Nutrition Facts'),
        ),

      body: Container(
        child: Column(
          spacing: 15,
          children: [
            Text('Food Name', style: TextStyle(fontSize: 25),),
            // Calories
            SizedBox(
              width: 380,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calories', style: TextStyle(fontSize: 25),),
                  Text('739', style: TextStyle(fontSize: 25),),
                ]
              ),
            ),
            // Macros
            Text('Macro Nutrients', style: TextStyle(fontSize: 17, decoration: TextDecoration.underline,),),
            MacroBreakdown(),
            // Options
            Text('Options', style: TextStyle(fontSize: 17,decoration: TextDecoration.underline,),),
            // Labels for inputs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  spacing: 30,
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
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          // TODO - default hint text to the selected serving size
                          hintText: 'Decimal Size',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      height: 50,
                      child: DropdownButton<String>(
                          hint: Text('Select Meal'),
                          // TODO - implement multiple meals based on the day's meal and clean this up
                          items: <String>['Meal 1', 'Meal 2', 'Meal 3', 'Meal 4'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          
                          // TODO - add the state for the selected meal
                          onChanged:(String? newValue) {
                            // selectedValue = newValue;
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
                // TODO - save button
                print('finish save button for nutrition facts')
              },
            ),
            // Remove button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(250, 50),
                foregroundColor: Colors.red, // text color
                side: BorderSide(width: 3, color: Colors.red)
                ),
              child: Text('Remove Food', style: TextStyle(fontSize: 20)),
              onPressed: () => {
                // TODO - remove meal / remove food from meal
                print('finish remove button on the nutrition facts')
              },
            )
          ],
        )
      ),
    );
  }
}

class MacroBreakdown extends StatelessWidget {
  const MacroBreakdown({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
            // Fats
            Text('Fats', style: TextStyle(fontSize: 17)),
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
                value: 20 / 100,
                backgroundColor: const Color.fromARGB(88, 0, 197, 99),
                color: Color.fromARGB(255, 0, 197, 99),
              ),
            ),
            SizedBox(
              height: 7,
              width: 240,
              child: LinearProgressIndicator(
                // current / max
                value: 20 / 100,
                backgroundColor: const Color.fromARGB(88, 255, 172, 64),
                color: Colors.orangeAccent,
              ),
            ),
            SizedBox(
              height: 7,
              width: 240,
              child: LinearProgressIndicator(
                // current / max
                value: 20 / 100,
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
            Text('100 / 100', style: TextStyle(fontSize: 17)),
            // Fats
            Text('100 / 100', style: TextStyle(fontSize: 17)),
            // Protein
            Text('100 / 100', style: TextStyle(fontSize: 17)),
          ],
    
        ),
      ]
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 50,
      children: [
        // TODO - check the safe area works correctly
        SafeArea(
          child:Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Progress',
                style: TextStyle(fontSize: 30),
              ),
            ],
          )
        ),
        GridPaper()
      ]
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TODO - check the safe area works correctly
        SafeArea(
          child:Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Settings',
                style: TextStyle(fontSize: 30),
              ),
            ],
          )
        ),
        // Spacer
        SizedBox(height: 30,),
        // TODO - switch all the options to be buttons
        // Option 1
        // NOTE: only option 1 needs the top and bottom borders, all other should only have a bottom border
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(), bottom: BorderSide())),
          child: SizedBox(
            width: 350,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Option 1', style: TextStyle(fontSize: 20)),
                Icon(Icons.arrow_right_sharp, size: 30,),
              ],
            )
          )
        ),
        // Option 2
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: SizedBox(
            width: 350,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Option 2', style: TextStyle(fontSize: 20)),
                Icon(Icons.arrow_right_sharp, size: 30,),
              ],
            )
          )
        ),
        // Option 3
        Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide())),
          child: SizedBox(
            width: 350,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Option 3', style: TextStyle(fontSize: 20)),
                Icon(Icons.arrow_right_sharp, size: 30,),
              ],
            )
          )
        ),
      ]
    );
  }
}