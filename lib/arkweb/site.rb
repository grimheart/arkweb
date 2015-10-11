module ARKWEB

class Site

  RootSectionName = 'root'
  InputARKWEB     = 'AW'
  OutputARKWEB    = 'AW'

  Types = ClosedStruct.new(
    pages:  "*.{erb,md,html,wiki}",
    images: "*.{jpg,jpeg,png,gif}",
    script: "*.js",
    style:  "*.{css,scss,sass}",
    sass:   "*.{scss,sass}",
    css:    "*.css",
    icon:   "icon.{png,gif,ico,jpg,jpeg}"
  )

  def initialize(root, cli_conf=nil)

    # Basics
    @app = Application.new
    @root = Pathname.new(root)
    raise BrokenSiteError unless @root.directory?
    @name = @root.basename

    # Paths to special input directories and files
    @input = ClosedStruct.new
    @input.aw           = @root + InputARKWEB
    @input.header       = @input.aw.join('header.yaml')
    @input.page_erb     = @input.aw.join('page.html.erb')
    @input.site_erb     = @input.aw.join('site.html.erb')
    @input.autoindex    = @input.aw.join('autoindex.html.erb')
    @input.style        = @input.aw.join('site.{css,sass,scss}')
    @input.images       = @input.aw.join('images')
    @input.scripts      = @input.aw.join('scripts')
    @input.hooks        = @input.aw.join('hook')
    @input.before_hooks = @input.hooks.join('before')
    @input.after_hooks  = @input.hooks.join('after')
    @input._finalize!

    # Load the header
    begin
      header = YAML.load_file(@input.header)
    rescue => e
      raise BrokenSiteError,
      "While loading site '#{@root}': #{e}\nHeader file '#{@input.header}' is missing or malformed."
    end
    header = Hash[header.map {|k,v| [k.to_sym, v] }]

    # Configure details about the site
    @conf = ClosedStruct.new(
      title:         'Untitled',
      author:        false,
      desc:          false,
      keywords:      false,
      google_fonts:  false,
      xuacompat:     false,
      analytics_key: false,
      clean:         false,
      clobber:       false,
      minify:        false,
      validate:      false,
      deploy:        false,
      output:        false,
      tmp:           false,
      cache:         false,
      remote:        false
    )
    if cli_conf
      cli_conf = Hash[cli_conf.opts.map {|k,v| [k.to_sym, v] }]
      @conf._update!(cli_conf)
    end
    @conf._update!(header)

    @conf.tmp = Pathname.new(@conf.tmp) if @conf.tmp
    @conf.output = Pathname.new(@conf.output) if @conf.output

    # Paths to where output files will be located
    @output = ClosedStruct.new
    @output.tmp      = @conf.tmp || @input.aw.join('tmp')
    @output.root     = @conf.output || @input.aw.join('output')
    @output.aw       = @output.root.join(OutputARKWEB)
    @output.images   = @output.aw.join('images')
    @output.scripts  = @output.aw.join('scripts')
    @output.favicons = @output.aw.join('favicons')
    @output._finalize!

    # Decide what templates we'll be using
    if @input.site_erb.exist?
      @site_template = @input.site_erb
    else
      @site_template = @app.root('templates/site.html.erb')
    end

    if @input.page_erb.exist?
      @page_template = @input.page_erb
    else
      @page_template = false
    end

    if @input.autoindex.exist?
      @autoindex = @input.autoindex
    else
      @autoindex = @app.root('templates/autoindex.html.erb')
    end

    # Collect paths to each hook
    @before_hooks = []
    @after_hooks = []
    if @input.before_hooks.exist?
      @before_hooks = @input.before_hooks.children.select {|c| c.executable? }
    end
    if @input.after_hooks.exist?
      @after_hooks = @input.after_hooks.children.select {|c| c.executable? }
    end

    # This variable will store all output paths to be rendered. This will
    # be written into the output as `.pathcache.yaml`, and used for smart
    # rendering to determine what's been changed since the last render.
    @path_cache_file = @output.aw.join('.path-cache.yaml')
    @path_cache = ClosedStruct.new(
      pages:       [],
      images:      [],
      favicons:    [],
      stylesheets: [],
      sections:    []
    )
    if @path_cache_file.exist?
      @smart_rendering = true
      @old_path_cache = ClosedStruct.new(**YAML.load_file(@path_cache_file))
    else
      @smart_rendering = false
      @old_path_cache = false
    end

    # Look for a favicon
    favicon_path = @input.aw.glob(Types.icon).first
    if favicon_path
      @favicon = Favicon.new(self, favicon_path)
      @path_cache.favicons += @favicon.formats.map {|f| f.path.link }
    else
      @favicon = nil
    end
   
    # Get all images in the image dir
    @images = @input.images.glob(Types.images).map {|p| Image.new(self, p) }

    # Get all stylesheets in the AW dir
    sheets = @input.aw.glob(Types.style)
    @styles = {}
    sheets.each do |s|
      s = Stylesheet.new(self, s)
      @styles[s.name] = s
      @path_cache.stylesheets << s.path.link
    end

    # Return a list of sections, which are any subdirectories excluding special subdirectories
    # The root directory is itself a section
    # Each section will later be scanned for pages and media, and then rendered
    subdirs = []
    @root.find do |path|
      if path.directory?
        if path == @input.aw || path.basename.to_s[/^\./] || path.basename.to_s[/\.page$/]
          Find.prune
        else
          subdirs << path
        end
      end
    end
    @sections = {}
    @pages = {}
    subdirs.each do |path|
      s = Section.new(self, path)
      @sections[s.path.link] = s
      @path_cache.sections << s.path.link
      s.pages.each do |page|
        @pages[page.path.link] = page
        @path_cache.pages << page.path.link
      end
    end

    FileUtils.mkdir_p([@output.root, @output.images])

    # Convenience
    @title = @conf.title
    @desc = @conf.desc || ''

    @engine = Engine.new(self)
  end

  attr_reader :app
  attr_reader :engine
  attr_reader :root
  attr_reader :name
  attr_reader :title
  attr_reader :desc
  attr_reader :input
  attr_reader :output
  attr_reader :conf
  attr_reader :styles
  attr_reader :images
  attr_reader :before_hooks
  attr_reader :after_hooks
  attr_reader :favicon
  attr_reader :site_template
  attr_reader :page_template
  attr_reader :autoindex
  attr_reader :path_cache_file
  attr_reader :path_cache
  attr_reader :old_path_cache
  attr_reader :smart_rendering


  #
  # Inspection
  #

  # Return all configuration pairs
  def configs
    return @conf._data
  end

  # Access site sections by name
  def section(key)
    key = Pathname.new(key) unless key.is_a?(Pathname)
    unless @sections.has_key?(key)
      raise ArgumentError, "No section named '#{key}'"
    end
    return @sections[key]
  end

  # Return an array of all sections in the site
  def sections
    return @sections.values
  end

  # Access pages by name
  def page(key)
    key = Pathname.new(key) unless key.is_a?(Pathname)
    unless @pages.has_key?(key)
      raise ArgumentError, "No page named '#{key}'"
    end
    return @pages[key]
  end

  # Return an array of all pages on the site
  def pages
    return @pages.values
  end

  # Get sections and pages by their link path
  def addr(path)
    path = Pathname.new(path) unless path.is_a?(Pathname)
    if @pages.has_key?(path)
      return @pages[path]
    elsif @sections.has_key?(path)
      return @sections[path]
    else
      raise ArgumentError, "No such address: #{path}"
    end
  end


  #
  # Helpers
  #

  def img(name, alt: nil, id: nil, klass: nil)
    alt   = %Q( alt="#{alt}")     if alt
    id    = %Q( id="#{id}")       if id
    klass = %Q( class="#{klass}") if klass

    link = @output.images.relative_path_from(@output.root) + name
    link = "/#{link}"

    return %Q(<img#{id}#{klass}#{alt} src="#{link}" />)
  end



  #
  # Utility
  #

  def inspect
    return %Q(#<AW::Site:"#{@conf[:title]}">)
  end
end # class Site

end # module ARKWEB

