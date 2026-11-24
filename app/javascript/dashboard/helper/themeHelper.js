import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

export const setColorTheme = isOSOnDarkMode => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';
  if (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark'
  ) {
    document.body.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    document.body.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};

export const isDarkModeActive = () => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';
  const isOSOnDarkMode =
    typeof window !== 'undefined' && window.matchMedia
      ? window.matchMedia('(prefers-color-scheme: dark)').matches
      : false;
  return (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark' ||
    (typeof document !== 'undefined' &&
      document.body.classList.contains('dark'))
  );
};

export const toggleColorTheme = () => {
  const currentDark = isDarkModeActive();
  const newTheme = currentDark ? 'light' : 'dark';
  LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, newTheme);
  const isOSOnDarkMode =
    typeof window !== 'undefined' && window.matchMedia
      ? window.matchMedia('(prefers-color-scheme: dark)').matches
      : false;
  setColorTheme(isOSOnDarkMode);
  return !currentDark;
};
