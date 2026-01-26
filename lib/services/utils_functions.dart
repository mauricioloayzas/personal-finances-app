import 'package:intl/intl.dart';
import 'package:frontend/core/enums.dart';

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

  bool checkPositiveBalance(dynamic accountData, num balanceValue) {
    bool isPositive = true;

    if (accountData['type'] == AccountType.asset.name) {
      if (balanceValue < 0) {
        isPositive = !isPositive;
      }
    } else if (accountData['type'] == AccountType.liability.name) {
      isPositive = !isPositive;
      if (balanceValue >= 0) {
        isPositive = !isPositive;
      }
    } else if (accountData['type'] == AccountType.expense.name) {
      isPositive = !isPositive;
    }

    return isPositive;
  }

  String formatCurrency(dynamic accountData, dynamic value) {
    final number = num.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2)
        .format(number.abs());
  }
}
