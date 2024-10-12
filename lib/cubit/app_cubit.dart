import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:smart_attendance/model/person.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppInitial());

  List<Person> persons = [];

  void setState(Function update) {
    update();
    emit(UpdateState());
    emit(ReturnState());
  }
}
