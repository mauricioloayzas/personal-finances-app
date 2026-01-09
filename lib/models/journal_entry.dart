class JournalEntry {
  final String accountId;
  final num debitValue;
  final num creditValue;

  JournalEntry({
    required this.accountId,
    required this.debitValue,
    required this.creditValue,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      accountId: json['account_id'],
      debitValue: json['debit_value'],
      creditValue: json['credit_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'debit_value': debitValue,
      'credit_value': creditValue,
    };
  }
}