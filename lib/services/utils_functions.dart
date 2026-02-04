import 'package:intl/intl.dart';
import 'package:mifinper/core/enums.dart';
import 'package:mifinper/models/account_data.dart';

class Utils {
  String getTheNextSequenceCode(String accountParentCode, List accounts) {
    int nextInt = accounts.length + 1;
    String next = nextInt.toString();
    String lastCode = accounts.last['code'];
    List<String> numbers = lastCode.split(".");
    String lastNumberFormatExample = numbers.last;

    if (next.length < lastNumberFormatExample.length) {
      int diff = lastNumberFormatExample.length - next.length;
      for (int i = 0; i < diff; i++) {
        next = "0$next";
      }
    }

    next = accountParentCode + next;

    return next;
  }

  bool checkPositiveBalance(AccountData accountData, num balanceValue) {
    bool isPositive = true;

    if (accountData.type == AccountType.asset.name) {
      if (balanceValue < 0) {
        isPositive = !isPositive;
      }
    } else if (accountData.type == AccountType.liability.name) {
      isPositive = !isPositive;
      if (balanceValue >= 0) {
        isPositive = !isPositive;
      }
    } else if (accountData.type == AccountType.expense.name) {
      isPositive = !isPositive;
    }

    return isPositive;
  }

  bool checkPositiveBalanceInTransaction(String acountType, num balanceValue, bool isDebit) {
    bool isPositive = true;

    if (acountType == AccountType.asset.name) {
      if (!isDebit) {
        isPositive = !isPositive;
      }
    } else if (acountType == AccountType.liability.name) {
      isPositive = !isPositive;
      if (isDebit) {
        isPositive = !isPositive;
      }
    } else if (acountType == AccountType.expense.name) {
      isPositive = !isPositive;
    }

    return isPositive;
  }

  String formatCurrency(AccountData accountData, dynamic value) {
    final number = num.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2)
        .format(number.abs());
  }

  String formatCurrencyFromNumber(num number) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2)
        .format(number.abs());
  }

  String formatDate(String dateString) {
    final DateTime dateTime = DateTime.parse(dateString);
    return DateFormat.yMMMd().format(dateTime);
  }

  AccountData setAccountData(dynamic accountData) {
    return AccountData(
      name: accountData['name'],
      description: accountData['description'],
      code: accountData['code'],
      nature: accountData['nature'],
      type: accountData['type'],
      isFinal: accountData['final'],
      balance: accountData['balance'],
      withInterest: accountData['with_interest'] ?? false,
      withInsurance: accountData['with_insurance'] ?? false,
    );
  }
}
