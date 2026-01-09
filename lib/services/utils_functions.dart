

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
        next = "0" + next;
      }
    }

    next = accountParentCode + next;

    return next;
  }
}