// TODO WIP - Better understanding required, might contain misunderstood information.
// As far as I can tell for now, they are used to restrict applying styles to line or inline level.
// Rules that apply to the line can't be applied inline.
// For example ResolveBlockFormatRule is responsible for applying BLOCK styling attributes
// like headings, code block, ol, ui, while ResolveInlineFormatRule is responsible for
// applying bold, italics, underline etc. For a complete list check https://quilljs.com/docs/formats
enum AttributeScope {
  INLINE,
  BLOCK,
  EMBEDS,
  IGNORE, // attributes that can be ignored. TODO Improve doc with an example.
}
