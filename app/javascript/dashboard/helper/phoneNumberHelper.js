import { parsePhoneNumberFromString } from 'libphonenumber-js';

const digitsOnly = value => String(value || '').replace(/\D/g, '');

export const normalizePhoneNumber = value => {
  const input = typeof value === 'string' ? value.trim() : '';
  if (!input) return '';

  const digits = digitsOnly(input);
  if (!digits) return '';

  if (input.startsWith('+')) return `+${digits}`;
  if (digits.startsWith('00')) return `+${digits.slice(2)}`;

  // Brazilian numbers already carrying country code 55 must not be prefixed twice.
  if (digits.startsWith('55') && [12, 13].includes(digits.length)) {
    return `+${digits}`;
  }

  const parsed = parsePhoneNumberFromString(input, 'BR');
  if (parsed?.isPossible()) return parsed.number;

  // A country calling code may be provided without a leading plus sign.
  const international = parsePhoneNumberFromString(`+${digits}`);
  if (digits.length > 11 && international?.isPossible()) {
    return international.number;
  }

  // Numbers without an explicit international prefix are Brazilian by default.
  return `+55${digits.replace(/^0(?=\d{10,11}$)/, '')}`;
};

export const getPhoneNumberSearchTerms = value => {
  const input = typeof value === 'string' ? value.trim() : '';
  const normalized = normalizePhoneNumber(value);
  if (!normalized) return [];

  const terms = [input, normalized, digitsOnly(normalized)];
  // Some older contacts were saved as national numbers without +55.
  if (normalized.startsWith('+55')) {
    terms.push(normalized.slice(3));
  }

  // Full digit strings do not match phone values stored with formatting.
  terms.push(...(input.match(/\d{4,}/g) || []));

  return [...new Set(terms.filter(term => term.length >= 4))];
};
