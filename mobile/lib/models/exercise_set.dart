class ExerciseSet {
  ExerciseSet({required this.w, required this.r});

  double w;
  String r;

  ExerciseSet clone() => ExerciseSet(w: w, r: r);

  Map<String, dynamic> toJson() => {'w': w, 'r': r};

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        w: (json['w'] as num).toDouble(),
        r: json['r'].toString(),
      );
}
