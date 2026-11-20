import { showBadgeOnFavicon, initFaviconSwitcher } from '../faviconHelper';

describe('favicon branding', () => {
  const createFavicon = size => ({
    sizes: { 0: `${size}x${size}` },
    href: '',
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('uses the TBA Chat badge artwork at each declared favicon size', () => {
    const favicons = [createFavicon(16), createFavicon(32), createFavicon(96)];
    vi.spyOn(document, 'querySelectorAll').mockReturnValue(favicons);

    showBadgeOnFavicon();

    expect(favicons.map(({ href }) => href)).toEqual([
      '/brand-assets/tba-favicon-badge-16x16.png?v=20261120',
      '/brand-assets/tba-favicon-badge-32x32.png?v=20261120',
      '/brand-assets/tba-favicon-badge-96x96.png?v=20261120',
    ]);
  });

  it('restores the versioned TBA Chat icon when the page becomes visible', () => {
    const favicons = [createFavicon(16), createFavicon(32), createFavicon(96)];
    vi.spyOn(document, 'querySelectorAll').mockReturnValue(favicons);
    let onVisibilityChange;
    vi.spyOn(document, 'addEventListener').mockImplementation((event, handler) => {
      if (event === 'visibilitychange') onVisibilityChange = handler;
    });
    vi.spyOn(document, 'visibilityState', 'get').mockReturnValue('visible');

    initFaviconSwitcher();
    onVisibilityChange();

    expect(favicons.map(({ href }) => href)).toEqual([
      '/brand-assets/tba-favicon-16x16.png?v=20261120',
      '/brand-assets/tba-favicon-32x32.png?v=20261120',
      '/brand-assets/tba-favicon-96x96.png?v=20261120',
    ]);
  });
});
