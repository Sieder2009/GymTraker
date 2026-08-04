import { WEEKDAYS, freshEx } from './data.js';

// A line is treated as a SET/WEIGHT line if it starts with a digit
// (e.g. "135kg x5 2.1 1.1 ...", "72,5kg x1 5.4", "1x 20.19.15.10").
// Anything else starting a new paragraph is treated as an EXERCISE NAME line,
// optionally carrying a "NxM" or "NxM-M" scheme (sets x reps), e.g.
// "Deadlift 2x3 nt muskelversagen" or "Klimmzüge 2x6-10".
const SET_LINE = /^\d/;
const DAY_HEADER = /^(\d+)\s*\.\s*Wochentag/i;
const DIVIDER_LINE = /^[=\-_*]{3,}$/;
const SCHEME = /(\d+)\s*x\s*([\d]+(?:\s*-\s*[\d]+)?)/i;
const WEIGHT = /^(\d+(?:[.,]\d+)?)\s*kg/i;

function parseWeight(line) {
  const m = line.match(WEIGHT);
  if (!m) return 0;
  return parseFloat(m[1].replace(',', '.'));
}

function cleanName(line) {
  return line
    .replace(SCHEME, '')
    .replace(/[-–]\s*$/, '')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

const X_MARKER = /^\d*x\d*$/i;

// Reads the per-set reps trailing a weight line, e.g. "135 kg x5  2.1  1.1  3.2"
// -> [2,1,1,1,3,2] (each "N.M" token is 2+ sets: first number = set 1, second = set 2, …).
// Letters (x/m, per the log's own legend: x = weniger Gewicht, m = mehr Gewicht) are kept as-is.
function parseHistoryReps(line) {
  const tokens = line.trim().split(/\s+/);
  const xIdx = tokens.findIndex((t) => X_MARKER.test(t));
  if (xIdx === -1) return [];
  const reps = [];
  for (const tok of tokens.slice(xIdx + 1)) {
    for (const part of tok.split('.')) {
      if (!part || part === '—' || part === '-') continue;
      reps.push(/^\d+$/.test(part) ? parseInt(part, 10) : part.toLowerCase());
    }
  }
  return reps;
}

/**
 * @param {string} text raw pasted/uploaded log
 * @returns {{ days: {num:number, exercises:{name:string, sets:number, reps:string, weight:number}[]}[], warnings: string[] }}
 */
export function parseLog(text) {
  const lines = text.split(/\r?\n/).map(l => l.trim());
  const days = [];
  const warnings = [];

  let currentDay = null;
  let currentEx = null;

  function flushExercise() {
    if (currentEx && currentDay) {
      if (currentEx.weight === 0 && currentEx.sawKg) {
        warnings.push(`"${currentEx.name}" (Tag ${currentDay.num}): kein Gewicht erkannt, wird als Körpergewicht geführt.`);
      }
      currentDay.exercises.push({
        name: currentEx.name || 'Unbenannte Übung',
        sets: currentEx.sets,
        reps: currentEx.reps,
        weight: currentEx.weight,
        history: currentEx.history,
      });
    }
    currentEx = null;
  }

  function flushDay() {
    flushExercise();
    if (currentDay) days.push(currentDay);
    currentDay = null;
  }

  for (const raw of lines) {
    if (!raw) continue;
    if (DIVIDER_LINE.test(raw)) continue; // "====" / "----" section dividers, not an exercise

    const dayMatch = raw.match(DAY_HEADER);
    if (dayMatch) {
      flushDay();
      currentDay = { num: parseInt(dayMatch[1], 10), exercises: [] };
      continue;
    }

    if (!currentDay) continue; // skip PR list / mobility routine / anything before day 1

    if (SET_LINE.test(raw)) {
      if (!currentEx) {
        // a weight line with no preceding exercise name — start an "unnamed" one
        currentEx = { name: null, sets: 2, reps: '8', weight: 0, sawKg: false, history: [] };
      }
      const w = parseWeight(raw);
      if (/kg/i.test(raw)) currentEx.sawKg = true;
      if (w > currentEx.weight) currentEx.weight = w;
      const reps = parseHistoryReps(raw);
      if (reps.length) currentEx.history.push({ weight: w, reps });
    } else {
      // new exercise name line
      flushExercise();
      const schemeMatch = raw.match(SCHEME);
      const sets = schemeMatch ? Math.max(1, parseInt(schemeMatch[1], 10)) : 2;
      const reps = schemeMatch ? schemeMatch[2].replace(/\s+/g, '') : '8';
      currentEx = { name: cleanName(raw), sets, reps, weight: 0, sawKg: false, history: [] };
    }
  }
  flushDay();

  if (!days.length) {
    warnings.push('Es wurden keine Tage im Format "1. Wochentag" gefunden — es konnte nichts importiert werden.');
  }

  return { days, warnings };
}

/**
 * Maps the parsed { num, exercises } days onto a 7-day weekday plan
 * (Tag 1 = Montag ... Tag 6 = Samstag, Tag 7 = Sonntag). Any weekday
 * without a matching parsed day becomes a rest day.
 */
export function toWeekdayPlan(parsedDays) {
  return WEEKDAYS.map((label, i) => {
    const found = parsedDays.find(d => d.num === i + 1);
    if (!found || !found.exercises.length) {
      return { label, rest: true, exercises: [] };
    }
    return {
      label,
      rest: false,
      exercises: found.exercises.map(ex =>
        freshEx(ex.name, '', 90, Array.from({ length: ex.sets }, () => ({ w: ex.weight, r: ex.reps })), ex.history)
      ),
    };
  });
}
