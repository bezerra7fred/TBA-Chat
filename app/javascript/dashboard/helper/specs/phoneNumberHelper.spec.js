import {
  getPhoneNumberSearchTerms,
  normalizePhoneNumber,
} from '../phoneNumberHelper';

describe('phone number lookup normalization', () => {
  it.each([
    ['11987654321', '+5511987654321'],
    ['(11) 98765-4321', '+5511987654321'],
    ['5511987654321', '+5511987654321'],
    ['+55 (11) 98765-4321', '+5511987654321'],
    ['+1 (415) 555-2671', '+14155552671'],
    ['351 912 345 678', '+351912345678'],
    ['001 415 555 2671', '+14155552671'],
    ['+351 912 345 678', '+351912345678'],
  ])('normalizes %s to %s', (input, expected) => {
    expect(normalizePhoneNumber(input)).toBe(expected);
  });

  it('searches both E.164 and legacy Brazilian national formats', () => {
    expect(getPhoneNumberSearchTerms('(11) 98765-4321')).toEqual([
      '5511987654321',
      '11987654321',
    ]);
  });

  it('does not reinterpret an explicitly international number as Brazilian', () => {
    expect(getPhoneNumberSearchTerms('+1 415 555 2671')).toEqual([
      '14155552671',
    ]);
  });

  it('returns no lookup value for empty or non-numeric input', () => {
    expect(normalizePhoneNumber('')).toBe('');
    expect(normalizePhoneNumber('not a phone')).toBe('');
    expect(getPhoneNumberSearchTerms(null)).toEqual([]);
  });
});
