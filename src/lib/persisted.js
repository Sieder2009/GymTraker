import { writable } from 'svelte/store';

/**
 * A writable Svelte store that is automatically saved to and loaded
 * from localStorage. Falls back to plain in-memory state if
 * localStorage isn't available (e.g. private browsing, sandboxed
 * previews) so the app never breaks — it just won't remember data
 * between sessions in that case.
 */
export function persisted(key, initial) {
  let storageOk = true;
  let data = initial;

  try {
    const raw = localStorage.getItem(key);
    if (raw !== null) data = JSON.parse(raw);
  } catch (e) {
    storageOk = false;
  }

  const store = writable(data);

  store.subscribe((value) => {
    if (!storageOk) return;
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch (e) {
      storageOk = false;
    }
  });

  return store;
}
