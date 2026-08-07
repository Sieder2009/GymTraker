import '../models/exercise_template.dart';
import '../models/muscle_group.dart';

/// Which muscles [ex] trains and roughly how much (0-100 intensity) — the
/// data behind the detailed body diagram on the Exercises tab. Matched by
/// [ExerciseTemplate.id] against real exercise-science knowledge (which
/// muscles a given lift trains is a fact, not copyrightable content), with
/// a category-level fallback so any exercise the GitHub-hosted database
/// adds later — even one this table has never seen — still gets a
/// reasonable, non-empty diagram instead of a blank one.
Map<MuscleGroup, double> muscleActivationForExercise(ExerciseTemplate ex) {
  return _byId[ex.id] ?? _categoryDefault(ex.category);
}

Map<MuscleGroup, double> _categoryDefault(String category) {
  switch (category) {
    case 'chest':
      return const {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 35, MuscleGroup.triceps: 35};
    case 'back':
      return const {MuscleGroup.lats: 80, MuscleGroup.upperBack: 55, MuscleGroup.biceps: 30};
    case 'shoulders':
      return const {MuscleGroup.frontDelts: 70, MuscleGroup.sideDelts: 60, MuscleGroup.triceps: 25};
    case 'legs':
      return const {MuscleGroup.quads: 80, MuscleGroup.glutes: 50, MuscleGroup.hamstrings: 25};
    case 'arms':
      return const {MuscleGroup.biceps: 60, MuscleGroup.triceps: 60, MuscleGroup.forearms: 30};
    case 'core':
      return const {MuscleGroup.abs: 90, MuscleGroup.obliques: 35};
    case 'cardio':
      return const {MuscleGroup.quads: 55, MuscleGroup.calves: 45, MuscleGroup.hamstrings: 30};
    default:
      return const {};
  }
}

const Map<String, Map<MuscleGroup, double>> _byId = {
  // --- Chest ---
  'bench_press': {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 40, MuscleGroup.triceps: 40},
  'incline_bench_press': {MuscleGroup.chest: 90, MuscleGroup.frontDelts: 55, MuscleGroup.triceps: 35},
  'decline_bench_press': {MuscleGroup.chest: 100, MuscleGroup.triceps: 45, MuscleGroup.frontDelts: 25},
  'close_grip_bench_press': {MuscleGroup.chest: 75, MuscleGroup.triceps: 65, MuscleGroup.frontDelts: 30},
  'wide_grip_bench_press': {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 35, MuscleGroup.triceps: 30},
  'dumbbell_bench_press': {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 40, MuscleGroup.triceps: 35},
  'incline_dumbbell_press': {MuscleGroup.chest: 90, MuscleGroup.frontDelts: 55, MuscleGroup.triceps: 30},
  'decline_dumbbell_press': {MuscleGroup.chest: 100, MuscleGroup.triceps: 40, MuscleGroup.frontDelts: 25},
  'smith_machine_bench_press': {MuscleGroup.chest: 95, MuscleGroup.frontDelts: 40, MuscleGroup.triceps: 40},
  'floor_press': {MuscleGroup.chest: 85, MuscleGroup.triceps: 55, MuscleGroup.frontDelts: 25},
  'chest_fly': {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 15},
  'incline_chest_fly': {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 20},
  'cable_fly': {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 15},
  'low_cable_fly': {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 10},
  'pec_deck': {MuscleGroup.chest: 100, MuscleGroup.frontDelts: 10},
  'chest_press_machine': {MuscleGroup.chest: 95, MuscleGroup.frontDelts: 35, MuscleGroup.triceps: 30},
  'dips': {MuscleGroup.chest: 80, MuscleGroup.triceps: 60, MuscleGroup.frontDelts: 30},
  'weighted_dips': {MuscleGroup.chest: 80, MuscleGroup.triceps: 65, MuscleGroup.frontDelts: 30},
  'push_ups': {MuscleGroup.chest: 90, MuscleGroup.triceps: 40, MuscleGroup.frontDelts: 30, MuscleGroup.abs: 15},
  'incline_push_ups': {MuscleGroup.chest: 80, MuscleGroup.triceps: 35, MuscleGroup.frontDelts: 25, MuscleGroup.abs: 10},
  'decline_push_ups': {MuscleGroup.chest: 95, MuscleGroup.triceps: 40, MuscleGroup.frontDelts: 35, MuscleGroup.abs: 20},
  'pullover': {MuscleGroup.chest: 60, MuscleGroup.lats: 50, MuscleGroup.triceps: 20},
  'svend_press': {MuscleGroup.chest: 90, MuscleGroup.frontDelts: 20},

  // --- Back ---
  'deadlift': {
    MuscleGroup.lowerBack: 90,
    MuscleGroup.hamstrings: 65,
    MuscleGroup.glutes: 70,
    MuscleGroup.traps: 45,
    MuscleGroup.forearms: 35,
    MuscleGroup.lats: 25,
  },
  'sumo_deadlift': {
    MuscleGroup.glutes: 80,
    MuscleGroup.hamstrings: 55,
    MuscleGroup.lowerBack: 80,
    MuscleGroup.traps: 40,
    MuscleGroup.forearms: 30,
    MuscleGroup.quads: 35,
  },
  'romanian_deadlift': {MuscleGroup.hamstrings: 90, MuscleGroup.glutes: 60, MuscleGroup.lowerBack: 60},
  'stiff_leg_deadlift': {MuscleGroup.hamstrings: 95, MuscleGroup.glutes: 55, MuscleGroup.lowerBack: 55},
  'deficit_deadlift': {
    MuscleGroup.lowerBack: 90,
    MuscleGroup.hamstrings: 70,
    MuscleGroup.glutes: 65,
    MuscleGroup.traps: 40,
  },
  'rack_pull': {MuscleGroup.lowerBack: 70, MuscleGroup.traps: 60, MuscleGroup.forearms: 50, MuscleGroup.lats: 30},
  'trap_bar_deadlift': {
    MuscleGroup.glutes: 70,
    MuscleGroup.hamstrings: 60,
    MuscleGroup.lowerBack: 75,
    MuscleGroup.quads: 40,
    MuscleGroup.traps: 35,
  },
  'pull_ups': {MuscleGroup.lats: 100, MuscleGroup.biceps: 50, MuscleGroup.upperBack: 35, MuscleGroup.rearDelts: 15},
  'chin_ups': {MuscleGroup.lats: 90, MuscleGroup.biceps: 65, MuscleGroup.upperBack: 30},
  'weighted_pull_ups': {MuscleGroup.lats: 100, MuscleGroup.biceps: 55, MuscleGroup.upperBack: 35},
  'assisted_pull_ups': {MuscleGroup.lats: 90, MuscleGroup.biceps: 45, MuscleGroup.upperBack: 30},
  'lat_pulldown': {MuscleGroup.lats: 100, MuscleGroup.biceps: 40, MuscleGroup.upperBack: 30},
  'close_grip_lat_pulldown': {MuscleGroup.lats: 100, MuscleGroup.biceps: 50, MuscleGroup.upperBack: 25},
  'wide_grip_lat_pulldown': {MuscleGroup.lats: 100, MuscleGroup.biceps: 30, MuscleGroup.upperBack: 35},
  'single_arm_lat_pulldown': {MuscleGroup.lats: 95, MuscleGroup.biceps: 40, MuscleGroup.obliques: 15},
  'barbell_row': {MuscleGroup.lats: 80, MuscleGroup.upperBack: 65, MuscleGroup.biceps: 35, MuscleGroup.rearDelts: 25},
  'pendlay_row': {MuscleGroup.upperBack: 75, MuscleGroup.lats: 70, MuscleGroup.biceps: 30, MuscleGroup.rearDelts: 25},
  'dumbbell_row': {MuscleGroup.lats: 85, MuscleGroup.upperBack: 55, MuscleGroup.biceps: 35, MuscleGroup.rearDelts: 20},
  'chest_supported_row': {MuscleGroup.upperBack: 70, MuscleGroup.lats: 65, MuscleGroup.rearDelts: 30, MuscleGroup.biceps: 30},
  'seated_cable_row': {MuscleGroup.upperBack: 70, MuscleGroup.lats: 65, MuscleGroup.biceps: 35, MuscleGroup.rearDelts: 20},
  'one_arm_cable_row': {MuscleGroup.lats: 75, MuscleGroup.upperBack: 60, MuscleGroup.biceps: 30, MuscleGroup.obliques: 15},
  't_bar_row': {MuscleGroup.upperBack: 75, MuscleGroup.lats: 70, MuscleGroup.biceps: 30, MuscleGroup.rearDelts: 20},
  'machine_row': {MuscleGroup.upperBack: 70, MuscleGroup.lats: 60, MuscleGroup.biceps: 30},
  'inverted_row': {MuscleGroup.upperBack: 70, MuscleGroup.lats: 60, MuscleGroup.biceps: 35, MuscleGroup.rearDelts: 20},
  'face_pull': {MuscleGroup.rearDelts: 85, MuscleGroup.upperBack: 45, MuscleGroup.traps: 30},
  'straight_arm_pulldown': {MuscleGroup.lats: 90, MuscleGroup.triceps: 20},
  'hyperextension': {MuscleGroup.lowerBack: 90, MuscleGroup.glutes: 45, MuscleGroup.hamstrings: 40},
  'good_morning': {MuscleGroup.lowerBack: 80, MuscleGroup.hamstrings: 60, MuscleGroup.glutes: 50},
  'shrugs': {MuscleGroup.traps: 100, MuscleGroup.forearms: 25},
  'dumbbell_shrugs': {MuscleGroup.traps: 100, MuscleGroup.forearms: 25},
  'back_extension_machine': {MuscleGroup.lowerBack: 90, MuscleGroup.glutes: 40, MuscleGroup.hamstrings: 30},

  // --- Shoulders ---
  'overhead_press': {MuscleGroup.frontDelts: 90, MuscleGroup.sideDelts: 40, MuscleGroup.triceps: 40, MuscleGroup.traps: 25},
  'dumbbell_shoulder_press': {MuscleGroup.frontDelts: 90, MuscleGroup.sideDelts: 45, MuscleGroup.triceps: 35},
  'seated_shoulder_press': {MuscleGroup.frontDelts: 90, MuscleGroup.sideDelts: 40, MuscleGroup.triceps: 35},
  'machine_shoulder_press': {MuscleGroup.frontDelts: 90, MuscleGroup.sideDelts: 35, MuscleGroup.triceps: 30},
  'arnold_press': {MuscleGroup.frontDelts: 85, MuscleGroup.sideDelts: 55, MuscleGroup.triceps: 35},
  'push_press': {MuscleGroup.frontDelts: 90, MuscleGroup.sideDelts: 35, MuscleGroup.triceps: 40, MuscleGroup.quads: 20},
  'behind_neck_press': {MuscleGroup.sideDelts: 60, MuscleGroup.frontDelts: 60, MuscleGroup.triceps: 35, MuscleGroup.traps: 25},
  'lateral_raise': {MuscleGroup.sideDelts: 100, MuscleGroup.traps: 15},
  'cable_lateral_raise': {MuscleGroup.sideDelts: 100, MuscleGroup.traps: 15},
  'leaning_lateral_raise': {MuscleGroup.sideDelts: 100},
  'front_raise': {MuscleGroup.frontDelts: 100},
  'plate_front_raise': {MuscleGroup.frontDelts: 100, MuscleGroup.abs: 10},
  'rear_delt_fly': {MuscleGroup.rearDelts: 100, MuscleGroup.upperBack: 25},
  'cable_rear_delt_fly': {MuscleGroup.rearDelts: 100, MuscleGroup.upperBack: 25},
  'upright_row': {MuscleGroup.sideDelts: 70, MuscleGroup.traps: 60, MuscleGroup.biceps: 20},
  'cuban_press': {MuscleGroup.sideDelts: 60, MuscleGroup.rearDelts: 50, MuscleGroup.frontDelts: 40},
  'landmine_press': {MuscleGroup.frontDelts: 80, MuscleGroup.sideDelts: 30, MuscleGroup.triceps: 35, MuscleGroup.abs: 15},

  // --- Legs ---
  'squats': {MuscleGroup.quads: 90, MuscleGroup.glutes: 60, MuscleGroup.lowerBack: 30, MuscleGroup.hamstrings: 20},
  'front_squat': {MuscleGroup.quads: 100, MuscleGroup.glutes: 45, MuscleGroup.abs: 25},
  'box_squat': {MuscleGroup.quads: 85, MuscleGroup.glutes: 65, MuscleGroup.lowerBack: 30},
  'pause_squat': {MuscleGroup.quads: 90, MuscleGroup.glutes: 65, MuscleGroup.lowerBack: 30},
  'bulgarian_split_squat': {MuscleGroup.quads: 85, MuscleGroup.glutes: 65, MuscleGroup.hamstrings: 25},
  'goblet_squat': {MuscleGroup.quads: 90, MuscleGroup.glutes: 50, MuscleGroup.abs: 15},
  'hack_squat': {MuscleGroup.quads: 100, MuscleGroup.glutes: 40},
  'smith_machine_squat': {MuscleGroup.quads: 90, MuscleGroup.glutes: 55},
  'leg_press': {MuscleGroup.quads: 90, MuscleGroup.glutes: 50, MuscleGroup.hamstrings: 20},
  'single_leg_press': {MuscleGroup.quads: 90, MuscleGroup.glutes: 55, MuscleGroup.hamstrings: 20},
  'lunges': {MuscleGroup.quads: 85, MuscleGroup.glutes: 65, MuscleGroup.hamstrings: 25},
  'walking_lunges': {MuscleGroup.quads: 85, MuscleGroup.glutes: 70, MuscleGroup.hamstrings: 25},
  'reverse_lunges': {MuscleGroup.quads: 80, MuscleGroup.glutes: 70, MuscleGroup.hamstrings: 30},
  'step_ups': {MuscleGroup.quads: 85, MuscleGroup.glutes: 65, MuscleGroup.calves: 20},
  'leg_extension': {MuscleGroup.quads: 100},
  'leg_curl': {MuscleGroup.hamstrings: 100, MuscleGroup.glutes: 15},
  'seated_leg_curl': {MuscleGroup.hamstrings: 100, MuscleGroup.glutes: 15},
  'nordic_curl': {MuscleGroup.hamstrings: 100, MuscleGroup.glutes: 20},
  'hip_thrust': {MuscleGroup.glutes: 100, MuscleGroup.hamstrings: 35, MuscleGroup.lowerBack: 15},
  'glute_bridge': {MuscleGroup.glutes: 100, MuscleGroup.hamstrings: 30},
  'cable_kickback': {MuscleGroup.glutes: 90, MuscleGroup.hamstrings: 20},
  'hip_abduction': {MuscleGroup.glutes: 80},
  'hip_adduction': {MuscleGroup.quads: 35, MuscleGroup.glutes: 20},
  'calf_raise': {MuscleGroup.calves: 100},
  'seated_calf_raise': {MuscleGroup.calves: 100},
  'leg_press_calf_raise': {MuscleGroup.calves: 100},
  'donkey_calf_raise': {MuscleGroup.calves: 100},
  'sissy_squat': {MuscleGroup.quads: 100, MuscleGroup.abs: 15},

  // --- Arms ---
  'barbell_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 25},
  'ez_bar_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 25},
  'dumbbell_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 25},
  'alternating_dumbbell_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 25},
  'hammer_curl': {MuscleGroup.biceps: 80, MuscleGroup.forearms: 55},
  'preacher_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 15},
  'concentration_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 15},
  'cable_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 20},
  'spider_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 15},
  'drag_curl': {MuscleGroup.biceps: 100, MuscleGroup.forearms: 20},
  'reverse_curl': {MuscleGroup.biceps: 75, MuscleGroup.forearms: 60},
  'triceps_pushdown': {MuscleGroup.triceps: 100},
  'rope_pushdown': {MuscleGroup.triceps: 100},
  'overhead_triceps_extension': {MuscleGroup.triceps: 100},
  'skull_crushers': {MuscleGroup.triceps: 100},
  'close_grip_bench_triceps': {MuscleGroup.triceps: 75, MuscleGroup.chest: 45, MuscleGroup.frontDelts: 20},
  'close_grip_push_up': {MuscleGroup.triceps: 70, MuscleGroup.chest: 60, MuscleGroup.frontDelts: 25},
  'triceps_dip_machine': {MuscleGroup.triceps: 100, MuscleGroup.chest: 20},
  'wrist_curl': {MuscleGroup.forearms: 100},
  'reverse_wrist_curl': {MuscleGroup.forearms: 100},
  'forearm_training': {MuscleGroup.forearms: 100},

  // --- Core ---
  'plank': {MuscleGroup.abs: 80, MuscleGroup.obliques: 50},
  'side_plank': {MuscleGroup.obliques: 90, MuscleGroup.abs: 40},
  'crunches': {MuscleGroup.abs: 100},
  'bicycle_crunches': {MuscleGroup.abs: 90, MuscleGroup.obliques: 60},
  'cable_crunch': {MuscleGroup.abs: 100},
  'sit_ups': {MuscleGroup.abs: 100},
  'leg_raise': {MuscleGroup.abs: 100, MuscleGroup.quads: 15},
  'hanging_leg_raise': {MuscleGroup.abs: 100, MuscleGroup.forearms: 20},
  'hanging_knee_raise': {MuscleGroup.abs: 100, MuscleGroup.forearms: 15},
  'russian_twist': {MuscleGroup.obliques: 100, MuscleGroup.abs: 40},
  'ab_wheel': {MuscleGroup.abs: 100, MuscleGroup.obliques: 30, MuscleGroup.lowerBack: 20},
  'mountain_climbers': {MuscleGroup.abs: 80, MuscleGroup.quads: 30, MuscleGroup.frontDelts: 20},
  'flutter_kicks': {MuscleGroup.abs: 100, MuscleGroup.quads: 15},
  'dead_bug': {MuscleGroup.abs: 85, MuscleGroup.obliques: 35},
  'pallof_press': {MuscleGroup.obliques: 90, MuscleGroup.abs: 40},
  'woodchopper': {MuscleGroup.obliques: 100, MuscleGroup.abs: 35},

  // --- Cardio ---
  'running': {MuscleGroup.quads: 60, MuscleGroup.calves: 60, MuscleGroup.hamstrings: 40, MuscleGroup.glutes: 30},
  'treadmill': {MuscleGroup.quads: 60, MuscleGroup.calves: 60, MuscleGroup.hamstrings: 40, MuscleGroup.glutes: 30},
  'rowing_machine': {MuscleGroup.lats: 60, MuscleGroup.quads: 40, MuscleGroup.upperBack: 40, MuscleGroup.biceps: 25},
  'cycling': {MuscleGroup.quads: 80, MuscleGroup.calves: 40, MuscleGroup.hamstrings: 25},
  'stationary_bike': {MuscleGroup.quads: 80, MuscleGroup.calves: 40, MuscleGroup.hamstrings: 25},
  'jump_rope': {MuscleGroup.calves: 90, MuscleGroup.quads: 30},
  'stair_climber': {MuscleGroup.quads: 70, MuscleGroup.glutes: 50, MuscleGroup.calves: 40},
  'elliptical': {MuscleGroup.quads: 55, MuscleGroup.hamstrings: 35, MuscleGroup.glutes: 30},
  'battle_ropes': {MuscleGroup.frontDelts: 50, MuscleGroup.sideDelts: 40, MuscleGroup.abs: 40, MuscleGroup.forearms: 30},
  'burpees': {MuscleGroup.quads: 50, MuscleGroup.chest: 40, MuscleGroup.abs: 40, MuscleGroup.frontDelts: 30},
  'swimming': {MuscleGroup.lats: 50, MuscleGroup.frontDelts: 40, MuscleGroup.abs: 30, MuscleGroup.quads: 25},
};
