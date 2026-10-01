import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';

/// The immutable state currently presented by Home.
sealed class HomeState {
  const HomeState();
}

/// No Home read has started yet.
final class HomeInitial extends HomeState {
  const HomeInitial();
}

/// The first Home snapshot is being loaded.
final class HomeLoading extends HomeState {
  const HomeLoading();
}

/// A valid Home snapshot is available.
final class HomeData extends HomeState {
  const HomeData(this.summary);

  final HomeSummary summary;
}

/// A newer snapshot is being loaded while the previous one remains visible.
final class HomeRefreshing extends HomeState {
  const HomeRefreshing(this.summary);

  final HomeSummary summary;
}

/// The initial Home read failed and there is no valid snapshot to show.
final class HomeError extends HomeState {
  const HomeError(this.failure);

  final AppFailure failure;
}
