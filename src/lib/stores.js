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

// bodyweight target and history, shown on the "Gewicht" tab
export const GOAL_WEIGHT = 80.0;
export const weightData = persisted('ironpeak:weightData', []);
