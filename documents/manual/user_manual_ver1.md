

# **Task Tracker User Manual**

## **Introduction**
The **Task Tracker** is a Flutter application that allows users to manage tasks by adding, viewing, searching, and deleting tasks. The app integrates with Firebase for persistent task storage and provides an intuitive interface for managing tasks with features like AM/PM or 24-hour time formats.

---

## **Table of Contents**
1. [Installation](#installation)
2. [Features](#features)
3. [How to Use](#how-to-use)
   - [Add a Task](#add-a-task)
   - [View All Tasks](#view-all-tasks)
   - [Search Tasks](#search-tasks)
   - [Delete a Task](#delete-a-task)
4. [Error Handling](#error-handling)
5. [Credits](#credits)

---

## **Installation**

### **Prerequisites**
1. Flutter SDK installed on your system.
2. Firebase account with a Firestore database configured.
3. Internet connection for Firebase integration.

### **Steps**
1. Clone the repository or download the source code.
2. Run `flutter pub get` to install dependencies.
3. Set up Firebase by replacing `firebase_options.dart` with your Firebase configuration file.
4. Run the application using `flutter run`.

---

## **Features**

### **Task Management**
- Add tasks with a name, date, start time, end time, and tags.
- Support for 24-hour or AM/PM time formats.

### **Task Retrieval**
- View all tasks stored in Firebase Firestore.
- Search for tasks by date, tags, or name.

### **Task Deletion**
- Delete individual tasks from the database.

---

## **How to Use**

### **Add a Task**
1. Click the **"Add Task"** button on the main screen.
2. Enter the following details:
   - **Date**: Use the date picker or type in the format `YYYY/MM/DD`.
   - **Start Time**: Enter in `HH:MM` format. Select `AM` or `PM` if using that format.
   - **End Time**: Same as the start time format.
   - **Task Name**: Provide a descriptive name for the task.
   - **Tags**: Add any tags separated by commas.
3. Select **Time Format**:
   - Choose `24-Hour` for direct input.
   - Choose `AM/PM` to enable AM/PM radio buttons for time input.
4. Click **"Add Task"**. A success message confirms the task is saved.

### **View All Tasks**
1. Click the **"Show All Tasks"** button.
2. A list of tasks is displayed with the following details:
   - Date
   - Start Time (converted to 24-hour format)
   - End Time (converted to 24-hour format)
   - Tags

### **Search Tasks**
1. Click the **"Search Tasks"** button.
2. Fill in one or more of the following fields:
   - **Date**: Enter in `YYYY/MM/DD` format.
   - **Tags**: Enter tags separated by commas.
   - **Task Name**: Enter a specific task name.
3. Click **"Search"** to view matching results.

### **Delete a Task**
1. View the list of tasks.
2. Click the **Trash Icon** next to the task you want to delete.
3. Confirm the deletion. A success message will be shown if the task is removed.

---

## **Error Handling**
- If a task cannot be added, a message like `Failed to add task` is displayed.
- For invalid time inputs, the app returns `Invalid Time`.
- If tasks cannot be retrieved or deleted, appropriate messages are displayed.

---

## **Credits**
- **Developer**: Quay Robinson
- **Technologies Used**:
  - Flutter
  - Firebase Firestore
