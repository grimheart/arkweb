have a special mode for images, where an image in a dir is treated as a page. a
description can be attached, so image.jpg would have image.md.
image pages are rendered using a special image.html.erb template

automatic gallery mode, where a page is rendered from a set of images in a
composite page directory, without the need for an index.x[.erb]

make optional dependencies more verbose, especially when their feature are
directly called. add warnings in.

yaml frontmatter on stylseets with heritable attribute

frontmatter and heritability for page style and script assets

include feature should support full rendering for whatever files will be
included, but only if the user requests it - this way normal ARKWEB-style pages
can be included and rendered, but complete HTML files from other sources can
also be included without getting wrapped in a template.

apple icon support, windows tile support

when in watch mode, disable message times

move the remaining helper methods found on Site to Helper

smart rendering: when a template is modified, make sure all pages are
re-rendered

builtin support for a development server
ark serve
ark unserve

smart rendering: make sure autoindices are re-rendered when their collected
pages change

fix version information bug

allow markdown in frontmatter `desc:' fields, since these will be used as
snippets and in autoindices as content.

support for pages written as plain text without any markup, i.e., `.txt` files
txt files will be rendered into a preformatted tag

builtin support for frameworks like bootstrap and jquery

store and makes times accessible for: page render time, init time, total render
time

perhaps change favicon to be configurable, so any site image asset can be
configured as the favicon

add structured data pages with types and relations

the path object requires a "unique link" attribute for addressing resources.
currently, section indices will have the same link as their section, making them
unaddressable by link



