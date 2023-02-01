String symbolToString(Symbol symbol) {
  final symbolString = symbol.toString();
  return symbolString.substring(8, symbolString.length - 2);
}

Map<String, dynamic> toStringKeys(Map<Symbol, dynamic> source) =>
    source.map<String, dynamic>((key, value) => MapEntry(symbolToString(key), value));

Map<Symbol, dynamic> toSymbolKeys(Map<String, dynamic> source) =>
    source.map<Symbol, dynamic>((key, value) => MapEntry(Symbol(key), value));
