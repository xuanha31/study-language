import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/content_repository.dart';
import '../../data/models/course.dart';

sealed class ContentState extends Equatable {
  const ContentState();
  @override
  List<Object?> get props => [];
}

class ContentLoading extends ContentState {
  const ContentLoading();
}

class ContentLoaded extends ContentState {
  final List<Course> courses;
  const ContentLoaded(this.courses);
  @override
  List<Object?> get props => [courses];
}

class ContentError extends ContentState {
  final String message;
  const ContentError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Tải danh sách khóa học từ manifest.
class ContentCubit extends Cubit<ContentState> {
  final ContentRepository repo;
  ContentCubit(this.repo) : super(const ContentLoading());

  Future<void> load() async {
    emit(const ContentLoading());
    try {
      final courses = await repo.loadCourses();
      emit(ContentLoaded(courses));
    } catch (e) {
      emit(ContentError('Không tải được nội dung: $e'));
    }
  }
}
