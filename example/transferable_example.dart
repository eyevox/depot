import 'package:depot/depot.dart';

enum StartPosition {
  ready,
  steady,
  go
}

class StartState extends Transferable {
  DateTime startTime;
  StartPosition state;

  StartState(this.startTime, this.state);

  StartState.fromMap(Map<String, dynamic> data):
      startTime = Transferable.materialize(data['startTime']) as DateTime,
      state = Transferable.materialize(data['state']) as StartPosition;

  void setPosition(StartPosition position) {
    print('position set to $position');
    state = position;
  }

  @override
  Map<String, dynamic> toMap() => {
    'startTime': Transferable.serialize(startTime),
    'state': Transferable.serialize(state)
  };

  @override
  bool operator ==(Object other) {
    if(other is StartState) {
      return startTime == other.startTime && state == other.state;
    }
    return false;
  }
  
  @override
  int get hashCode => super.hashCode;
  
  
}

class RunnerData extends Transferable {
  String runner;
  TransferableList<StartState> states;

  RunnerData(this.runner, this.states);

  RunnerData.fromMap(Map<String, dynamic> data) :
      runner = data['runner'] as String,
      states = TransferableList(Transferable.materialize(data['states']).cast<StartState>());

  @override
  Map<String, dynamic> toMap() => {
    'runner': runner,
    'states': Transferable.serialize(states) // states.map((state) => state.toMap())
  };
}

