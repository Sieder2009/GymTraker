import { writable } from 'svelte/store';
import { persisted } from './persisted.js';
import { defaultPrograms } from './data.js';

// which of the 3 pages is active — not persisted, app always opens on Training
export const activeScreen = writable('training');

// the user's saved training programs — this is what "speichern" refers to
export const programs = persisted('ironpeak:programs', defaultPrograms());

// which plan / which day within it is currently being viewed
export const trainState = persisted('ironpeak:trainState', {
  activePlanId: null,
  viewedDayIdx: 0,
});

// Bench/Deadlift/Squat: personal record + logged history per lift, shown on the "Kraft" tab
export const BIG_LIFTS = ['bench', 'deadlift', 'squat'];
export const bigLifts = persisted('ironpeak:bigLifts', {
  bench: { pr: 0, history: [] },
  deadlift: { pr: 0, history: [] },
  squat: { pr: 0, history: [] },
});
