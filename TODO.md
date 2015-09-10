should be able to set default options for a site in its header

have a special mode for images, where an image in a dir is treated as a page. a
description can be attached, so image.jpg would have image.jpg.description.
image pages are rendered using a special image.html.erb template

fix bug where google fonts link still ends up in header even when no fonts are configured

make optional dependencies more verbose, especially when their feature are
directly called. add warnings in.

add header configuration value for google analytics key, which automatically
inserts the google analytics script with the key

add deploy function using rsync and ssh, configured in the site header

an automatic index should be created for sections if one doesnt exist, which
would list subsections and pages

each section should have its own section.yaml, similar to the site's header.yaml
this could be used to set things like the section title

get rid of the img/ directory idea, just have images wherever they are in the site tree

fix paths throughout the program. in particular, section paths may be different
depending on where the executable is run from relative to the site.

smart rendering: only re-render files which have changed since the last rendering.

yaml frontmatter on stylseets with heritable attribute