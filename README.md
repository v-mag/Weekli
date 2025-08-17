# Weekli 📊

A modern Flutter app for managing your personal finances with a focus on weekly budgeting and expense tracking.

## Features ✨

### 📈 **Dashboard Overview**
- Real-time balance tracking
- Daily, weekly, and monthly financial summaries
- Interactive charts showing income vs expenses over time
- Recent transaction history

### 💰 **Transaction Management**
- Add income and expense transactions
- Categorize transactions (Food & Dining, Transportation, Shopping, etc.)
- Set transaction titles and descriptions
- Date-based transaction tracking
- Recurring transaction support (daily, weekly, monthly, yearly)

### 📋 **Budget Planning**
- Set weekly budget expectations for different categories
- Track actual spending against budgeted amounts
- Visual budget vs actual comparisons
- Weekly budget rollover

### 🎨 **Modern UI/UX**
- Clean, intuitive interface
- Dark and light theme support
- Smooth animations and transitions
- Responsive design for all screen sizes

### 📱 **Cross-Platform**
- iOS and Android support
- macOS desktop app
- Web browser support

## Getting Started 🚀

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart 3.9.0 or higher
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Weekli
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

**macOS:**
```bash
flutter build macos --release
```

**Web:**
```bash
flutter build web --release
```

## Tech Stack 🛠️

- **Framework**: Flutter 3.9.0
- **Language**: Dart 3.9.0
- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **Charts**: fl_chart
- **Calendar**: table_calendar
- **Local Storage**: shared_preferences

## Project Structure 📁

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── transaction.dart
│   ├── category_budget.dart
│   └── projected_transaction.dart
├── providers/                # State management
│   ├── transaction_provider.dart
│   ├── settings_provider.dart
│   └── theme_provider.dart
├── screens/                  # UI screens
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── budget_screen.dart
│   ├── calendar_screen.dart
│   ├── settings_screen.dart
│   └── add_transaction_wizard.dart
├── services/                 # Business logic
│   └── database_helper.dart
├── theme/                    # App theming
│   └── app_theme.dart
├── utils/                    # Utilities
│   └── navigation_helper.dart
└── widgets/                  # Reusable components
    └── transaction_form_components.dart
```

## Screenshots 📸

### Dashboard Overview
![Dashboard Overview](docs/images/Simulator%20Screenshot%20-%20iPhone%2016e%20-%202025-08-17%20at%2011.48.29.png)

### Transaction Management
![Transaction Form](docs/images/Simulator%20Screenshot%20-%20iPhone%2016e%20-%202025-08-17%20at%2011.48.33.png)

### Budget Planning
![Budget Screen](docs/images/Simulator%20Screenshot%20-%20iPhone%2016e%20-%202025-08-17%20at%2011.48.37.png)

### Calendar View
![Calendar View](docs/images/Simulator%20Screenshot%20-%20iPhone%2016e%20-%202025-08-17%20at%2011.48.42.png)

### Settings & Configuration
![Settings Screen](docs/images/Simulator%20Screenshot%20-%20iPhone%2016e%20-%202025-08-17%20at%2011.48.45.png)

### Transaction History
![Transaction History](docs/images/Simulator%20Screenshot%20-%20iPhone%2016e%20-%202025-08-17%20at%2011.48.50.png)

## Usage Guide 📖

### Adding Transactions
1. Tap the "+" button on the dashboard
2. Choose between "Actual Transaction" or "Budget Entry"
3. Select transaction type (Income/Expense)
4. Fill in amount, category, and date
5. Add optional title and description
6. Set up recurrence if needed
7. Confirm and save

### Setting Budgets
1. Go to the budget screen
2. Select a category and week
3. Set your expected amount
4. Track actual spending against your budget

### Viewing Reports
- **Dashboard**: Overview of your financial health
- **Transactions**: Detailed list of all transactions
- **Calendar**: Monthly view with transaction markers
- **Charts**: Visual representation of spending patterns

## Contributing 🤝

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support 💬

If you encounter any issues or have questions:
- Create an issue on GitHub
- Check the existing issues for solutions
- Review the Flutter documentation for general help

---

**Weekli** - Take control of your weekly finances! 💪
