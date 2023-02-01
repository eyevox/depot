abstract class DepotException implements Exception {
  String get message;
  @override
  String toString() {
    return message;
  }
}

class NoTramException extends DepotException {
  @override
  final String message;

  NoTramException(Type T) : message = 'Depot error: Type $T is not registered in depot';
}

class NoTramNameException extends DepotException {
  @override
  final String message;

  NoTramNameException(String name) : message = 'Depot error: Name $name is not registered in depot';
}

class NoMethodException extends DepotException {
  @override
  final String message;

  NoMethodException(Type T, Symbol method) : message = 'Depot error: Endpoint $method not found in module $T';
}

class ModuleClosedException extends DepotException {
  @override
  final String message;

  ModuleClosedException(Type T) : message = 'Depot error: Trying to add a call to $T when it is already closed';
}

class DoubleRegistrationException extends DepotException {
  @override
  final String message;

  DoubleRegistrationException(String name)
      : message = 'Depot error: Transferable class under the name $name is already registered';
}

class TypeNotFoundException extends DepotException {
  @override
  final String message;

  TypeNotFoundException(Type T)
      : message = 'Depot error: Transferable type $T not found in the registry';
}

class RequestFoundException extends DepotException {
  @override
  final String message;

  RequestFoundException(int id)
      : message = 'Depot error: reply returned for the unknown call $id';
}

class InternalException extends DepotException {
  @override
  final String message;

  InternalException()
      : message = 'Depot error: internal library error';
}

class ReturnTypeException extends DepotException {
  @override
  final String message;

  ReturnTypeException(Type returned, Type required)
      : message = 'Depot error: $returned is returned instead of $required';
}
