class TrainState {
  TrainState({this.activePlanId, this.viewedDayIdx = 0});

  String? activePlanId;
  int viewedDayIdx;

  Map<String, dynamic> toJson() => {
        'activePlanId': activePlanId,
        'viewedDayIdx': viewedDayIdx,
      };

  factory TrainState.fromJson(Map<String, dynamic> json) => TrainState(
        activePlanId: json['activePlanId'] as String?,
        viewedDayIdx: (json['viewedDayIdx'] as num?)?.toInt() ?? 0,
      );
}
