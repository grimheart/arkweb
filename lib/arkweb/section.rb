module ARKWEB

class Section

  IncludeFileName = 'include.yaml'
  SectionHeader = 'section.yaml'

  def initialize(site, input_path)
    @site = site
    @path = Path.new(@site, input_path, @site.out(:root), relative: true)

    if self.root?
      title = "Home"
    else
      title = @path.link.basename.to_s.capitalize
    end

    @conf = {
      :title => title,
      :desc => false,
      :include => {},
      :autoindex => false
    }
    # Look for a section header file
    header_file = @path.input.join(SectionHeader)
    if header_file.exist?
      header = YAML.load_file(header_file)
      header = Hash[header.map {|k,v| [k.to_sym, v] }]
      @conf = @conf.merge(header) {|k,old,new| new && !new.to_s.empty? ? new : old }
    end

    @title = self.conf(:title)
    @desc = self.conf(:desc) || ''

    # Get all single-file pages in this section
    @pages = {}
    @path.input.glob(Site::Types[:pages]).each do |path|
      page = Page.new(@site, path, self)
      @pages[page.path.name] = page
    end

    # Get all composite pages in this section
    @path.input.glob('*.page/').each do |path|
      page = Page.new(@site, path, self)
      @pages[page.path.name] = page
    end

    if self.conf(:autoindex) && !self.has_page?('index')
      @pages['index'] = Page.new(@site, @site.autoindex, self, autoindex: true)
    end

    # Order pages by ctime and give them an index
    @ordered_pages = Hash[@pages.sort {|p1,p2| p1.last <=> p2.last }]
    @ordered_pages.each_with_index do |pair,i|
      pair.last.index = i + 1
    end
  end
  attr_reader :site
  attr_reader :path
  attr_reader :title
  attr_reader :desc
  attr_reader :pages
  attr_reader :ordered_pages

  def conf(key)
    key = key.to_sym
    unless @conf.has_key?(key)
      raise ArgumentError "No such configuration: #{key}"
    end
    return @conf[key]
  end

  def pages
    return @pages.values
  end

  def members
    return @pages.select {|n,p| n != 'index' }.values
  end

  def page(name)
    unless self.has_page?(name)
      raise ArgumentError, "Section #{self} has no page named '#{name}'"
    end
    @pages[name]
  end

  def has_page?(name)
    @pages.has_key?(name)
  end

  def has_index?
    return self.has_page?('index') || self.conf(:autoindex)
  end

  def root?
    return @path.link == Pathname.new('/')
  end

  def page_count
    return @pages.length
  end

  def link_to(**args)
    if self.has_index?
      args[:text] ||= @title
      return HTML.link_to(self, **args)
    else
      return HTML.span(@title)
    end
  end

  def inspect
    return "#<AW::Section:#{@path.link}>"
  end
end

end # module ARKWEB

