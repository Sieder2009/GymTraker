import { deflateSync } from 'node:zlib';
import { writeFileSync, mkdirSync } from 'node:fs';

// Renders the Ironpeak icon (dark rounded square, blue barbell) into raw
// RGBA pixels at 4x supersampling, downsamples for cheap anti-aliasing,
// then hand-encodes a PNG (no image library needed).

function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

const BG = hexToRgb('#101114');
const ACCENT = hexToRgb('#5588ff');
const PLATE = hexToRgb('#f2f2f4');

function inRoundedSquare(x, y, size, radius) {
  const rx = Math.min(Math.max(x, radius), size - radius);
  const ry = Math.min(Math.max(y, radius), size - radius);
  const dx = x - rx, dy = y - ry;
  return dx * dx + dy * dy <= radius * radius;
}

function segmentDist(px, py, x1, y1, x2, y2) {
  const dx = x2 - x1, dy = y2 - y1;
  const len2 = dx * dx + dy * dy;
  let t = len2 ? ((px - x1) * dx + (py - y1) * dy) / len2 : 0;
  t = Math.max(0, Math.min(1, t));
  const cx = x1 + t * dx, cy = y1 + t * dy;
  return Math.hypot(px - cx, py - cy);
}

function render(size) {
  const S = 4; // supersample factor
  const big = size * S;
  const px = new Uint8ClampedArray(big * big * 4);
  const c = size / 512;

  for (let y = 0; y < big; y++) {
    for (let x = 0; x < big; x++) {
      const gx = x / S, gy = y / S;
      let color = null;
      if (inRoundedSquare(gx, gy, size, 112 * c)) {
        color = BG;
        // vertical bar accents
        if (segmentDist(gx, gy, 150 * c, 176 * c, 150 * c, 336 * c) < 17 * c) color = ACCENT;
        if (segmentDist(gx, gy, 362 * c, 176 * c, 362 * c, 336 * c) < 17 * c) color = ACCENT;
        // horizontal bar
        if (segmentDist(gx, gy, 96 * c, 256 * c, 416 * c, 256 * c) < 17 * c) color = ACCENT;
        // plates
        if (segmentDist(gx, gy, 96 * c, 206 * c, 96 * c, 306 * c) < 15 * c) color = PLATE;
        if (segmentDist(gx, gy, 416 * c, 206 * c, 416 * c, 306 * c) < 15 * c) color = PLATE;
      }
      const i = (y * big + x) * 4;
      if (color) {
        px[i] = color[0]; px[i + 1] = color[1]; px[i + 2] = color[2]; px[i + 3] = 255;
      } else {
        px[i] = 0; px[i + 1] = 0; px[i + 2] = 0; px[i + 3] = 0;
      }
    }
  }

  // downsample S x S -> 1
  const out = new Uint8ClampedArray(size * size * 4);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let r = 0, g = 0, b = 0, a = 0;
      for (let sy = 0; sy < S; sy++) {
        for (let sx = 0; sx < S; sx++) {
          const i = ((y * S + sy) * big + (x * S + sx)) * 4;
          r += px[i]; g += px[i + 1]; b += px[i + 2]; a += px[i + 3];
        }
      }
      const n = S * S;
      const o = (y * size + x) * 4;
      out[o] = r / n; out[o + 1] = g / n; out[o + 2] = b / n; out[o + 3] = a / n;
    }
  }
  return out;
}

function crc32(buf) {
  let c, crc = 0xffffffff;
  const table = crc32.table || (crc32.table = (() => {
    const t = [];
    for (let n = 0; n < 256; n++) {
      c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      t[n] = c;
    }
    return t;
  })());
  for (let i = 0; i < buf.length; i++) crc = table[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([len, typeBuf, data, crc]);
}

function encodePNG(pixels, size) {
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type RGBA
  ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;

  const raw = Buffer.alloc(size * (size * 4 + 1));
  for (let y = 0; y < size; y++) {
    raw[y * (size * 4 + 1)] = 0; // filter: none
    for (let x = 0; x < size * 4; x++) {
      raw[y * (size * 4 + 1) + 1 + x] = pixels[y * size * 4 + x];
    }
  }
  const idat = deflateSync(raw);
  return Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);
}

mkdirSync('public', { recursive: true });
for (const size of [180, 192, 512]) {
  const pixels = render(size);
  writeFileSync(`public/icon-${size}.png`, encodePNG(pixels, size));
  console.log(`wrote public/icon-${size}.png`);
}
