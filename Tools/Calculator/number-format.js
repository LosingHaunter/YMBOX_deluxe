(function (root) {
  "use strict";

  const MAX_SIGNIFICANT_DIGITS = 7;
  const numericText = /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?$/i;
  const inputValues = new WeakMap();
  const boundInputs = new WeakSet();
  const inputFormats = new WeakMap();

  function format(value, digits = MAX_SIGNIFICANT_DIGITS) {
    if (!Number.isFinite(value)) return "--";
    const precision = Math.max(1, Math.min(MAX_SIGNIFICANT_DIGITS, Math.trunc(digits) || MAX_SIGNIFICANT_DIGITS));
    const [mantissa, exponent] = value.toPrecision(precision).split("e");
    const trimmed = mantissa.includes(".") ? mantissa.replace(/0+$/, "").replace(/\.$/, "") : mantissa;
    return exponent === undefined ? trimmed : `${trimmed}e${exponent}`;
  }

  // Counts and integer settings must remain exact, including uint32 values.
  function decimal(value) {
    return Number.isInteger(value) ? String(value) : format(value);
  }

  function formatArray(value) {
    if (Number.isFinite(value)) return decimal(value);
    if (Array.isArray(value)) {
      const entries = value.map(formatArray);
      if (entries.every(entry => entry !== null)) return `[${entries.join(", ")}]`;
    }
    return null;
  }

  function raw(value) {
    const text = String(value ?? ""), trimmed = text.trim();
    const normalized = trimmed.replace(",", ".");
    if (numericText.test(normalized) && Number.isFinite(Number(normalized))) return decimal(Number(normalized));
    if (trimmed.startsWith("[")) {
      try { return formatArray(JSON.parse(trimmed)) ?? text; } catch {}
    }
    // Preserve auto, incomplete/invalid edits, and nonnumeric text verbatim.
    return text;
  }

  function readInput(input) {
    const saved = inputValues.get(input);
    return saved && saved.display === input.value ? saved.raw : input.value;
  }

  function version(value) {
    const text = raw(value);
    // Keep the requested 1.0 notation without adding more than seven digits.
    return /^[+-]?\d{1,6}$/.test(text) ? `${text}.0` : text;
  }

  function writeInput(input, value) {
    const full = String(value ?? "");
    input.value = (inputFormats.get(input) || raw)(full);
    inputValues.set(input, {raw: full, display: input.value});
  }

  function bindInput(input, formatter = raw) {
    if (boundInputs.has(input)) return;
    boundInputs.add(input);
    inputFormats.set(input, formatter);
    // Capture explicit edits before calculator input handlers run. Formatting
    // on blur neither recalculates from rounded text nor marks a field manual.
    input.addEventListener("input", () => {
      inputValues.set(input, {raw: input.value, display: input.value});
    });
    input.addEventListener("blur", () => writeInput(input, readInput(input)));
    writeInput(input, readInput(input));
  }

  const api = Object.freeze({MAX_SIGNIFICANT_DIGITS, format, decimal, raw, version, readInput, writeInput, bindInput});
  root.YMBOXNumberFormat = api;
  if (typeof module !== "undefined" && module.exports) module.exports = api;
})(typeof window !== "undefined" ? window : globalThis);
