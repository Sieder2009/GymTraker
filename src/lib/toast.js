import { writable } from 'svelte/store';

export const toastMsg = writable('');
export const toastShown = writable(false);

let hideTimer;
let killTimer;

export function toast(msg) {
  clearTimeout(hideTimer);
  clearTimeout(killTimer);
  toastMsg.set(msg);
  toastShown.set(true);
  hideTimer = setTimeout(() => toastShown.set(false), 2100);
}
