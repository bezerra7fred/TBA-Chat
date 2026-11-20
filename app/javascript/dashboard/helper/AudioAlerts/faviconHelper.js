export const showBadgeOnFavicon = () => {
  const favicons = document.querySelectorAll('.favicon');

  favicons.forEach(favicon => {
    const newFileName = `/brand-assets/tba-favicon-badge-${favicon.sizes[0]}.png?v=20261120`;
    favicon.href = newFileName;
  });
};

export const initFaviconSwitcher = () => {
  const favicons = document.querySelectorAll('.favicon');

  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      favicons.forEach(favicon => {
        const oldFileName = `/brand-assets/tba-favicon-${favicon.sizes[0]}.png?v=20261120`;
        favicon.href = oldFileName;
      });
    }
  });
};
