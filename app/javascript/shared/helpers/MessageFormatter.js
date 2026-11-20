import MarkdownIt from 'markdown-it';
import mila from 'markdown-it-link-attributes';
import mentionPlugin from './markdownIt/link';

const isValidImageDimension = value =>
  /^(?:\d+(?:\.\d+)?(?:px|%)?|auto)$/i.test(value);

const setImageSizing = inlineToken => {
  const imgSrc = inlineToken.attrGet('src');
  if (!imgSrc) return;
  const url = new URL(imgSrc, 'https://chatwoot.local');
  const width = url.searchParams.get('cw_image_width');
  if (width && isValidImageDimension(width)) {
    inlineToken.attrSet(
      'style',
      `width: ${width}; max-width: 100%; height: auto;`
    );
    return;
  }
  const height = url.searchParams.get('cw_image_height');
  if (height && isValidImageDimension(height)) {
    inlineToken.attrSet('style', `height: ${height};`);
  }
};

const processInlineToken = blockToken => {
  blockToken.children.forEach(inlineToken => {
    if (inlineToken.type === 'image') {
      setImageSizing(inlineToken);
    }
  });
};

const imgResizeManager = md => {
  md.core.ruler.after('inline', 'add-image-sizing', state => {
    state.tokens.forEach(blockToken => {
      if (blockToken.type === 'inline') {
        processInlineToken(blockToken);
      }
    });
  });
};

const fillEmptyTableCells = md => {
  md.core.ruler.after('inline', 'fill-empty-table-cells', state => {
    state.tokens.forEach((token, index) => {
      if (token.type !== 'th_open' && token.type !== 'td_open') return;
      const inline = state.tokens[index + 1];
      if (inline.children.length) return;
      const nbsp = new state.Token('text', '', 0);
      nbsp.content = '\u00a0';
      inline.children.push(nbsp);
    });
  });
};

const createMarkdownInstance = (linkify = true) => {
  return MarkdownIt({
    html: false,
    xhtmlOut: true,
    breaks: true,
    langPrefix: 'language-',
    linkify,
    typographer: true,
    quotes: '\u201c\u201d\u2018\u2019',
    maxNesting: 20,
  })
    .disable(['lheading'])
    .use(mentionPlugin)
    .use(imgResizeManager)
    .use(fillEmptyTableCells)
    .use(mila, {
      attrs: {
        class: 'link',
        rel: 'noreferrer noopener nofollow',
        target: '_blank',
      },
    });
};

const COLWIDTHS_MARKER_REGEX =
  /^[ \t>]*<!--cw-colwidths:[\d,]+-->[ \t]*\r?\n?/gm;

const TWITTER_USERNAME_REGEX = /(^|[^@\w])@(\w{1,15})\b/g;
const TWITTER_USERNAME_REPLACEMENT = '$1[@$2](http://twitter.com/$2)';
const TWITTER_HASH_REGEX = /(^|\s)#(\w+)/g;
const TWITTER_HASH_REPLACEMENT = '$1[#$2](https://twitter.com/hashtag/$2)';

class MessageFormatter {
  constructor(
    message,
    isATweet = false,
    isAPrivateNote = false,
    linkify = true
  ) {
    this.message = (message || '').replace(COLWIDTHS_MARKER_REGEX, '');
    this.isAPrivateNote = isAPrivateNote;
    this.isATweet = isATweet;
    this.linkify = linkify;
    this.md = createMarkdownInstance(linkify);
  }

  formatMessage() {
    let updatedMessage = this.message;
    if (this.isATweet && !this.isAPrivateNote) {
      updatedMessage = updatedMessage.replace(
        TWITTER_USERNAME_REGEX,
        TWITTER_USERNAME_REPLACEMENT
      );
      updatedMessage = updatedMessage.replace(
        TWITTER_HASH_REGEX,
        TWITTER_HASH_REPLACEMENT
      );
    }
    return this.md.render(updatedMessage);
  }

  disableImageRendering() {
    this.md.disable(['add-image-sizing']);
    this.md.renderer.rules.image = () => '';
  }

  get formattedMessage() {
    return this.formatMessage();
  }

  get plainText() {
    const strippedOutHtml = new DOMParser().parseFromString(
      this.formattedMessage,
      'text/html'
    );
    return strippedOutHtml.body.textContent || '';
  }
}

export default MessageFormatter;
