module ARKWEB

class Page
  def initialize(site, input_path, section, autoindex: false)
    @site    = site
    @section = section
    @autoindex = autoindex

    if @autoindex
      @path = Path.new(@site, input_path, @section.path.output, output_ext: 'html', output_name: 'index')
    else
      @path = Path.new(@site, input_path, @site.out(:root), output_name: 'index', output_ext: 'html', relative: true, nest: true)
    end

    @index = 0

    if @path.basename[/\.erb$/]
      @erb  = true
      @type = @path.basename[/^.+?\.(.+).erb$/, 1]
    else
      @erb  = false
      @type = @path.basename[/^.+?\.(.+)$/, 1]
    end

    data = @path.input.read
    if (md = data.match(/^(?<metadata>---\s*\n.*?\n?)^(---\s*$\n?)/m))
      @contents = md.post_match
      yaml = md[:metadata]
      box  = Engine::Sandbox.new(:site => @site)
      erb  = ERB.new(yaml)
      yaml = erb.result(box.bindings)
      header = YAML.load(yaml)
    else
      @contents = data
      header = {}
    end

    if self.index?
      p @section.title
      title = "#{@section.title} Index"
    else
      title = @path.name.tr('-', ' ').split(/(\W)/).map(&:capitalize).join
    end

    @conf = {
      :title => title,
      :desc => false,
      :keywords => [],
      :collect => [@section.path.link],
      :paginate => false,
      :index => false,
      :date => false
    }
    @conf[:paginate] = 5 if autoindex
    unless header.empty?
      header = Hash[header.map {|k,v| [k.to_sym, v] }]
      @conf = @conf.merge(header) {|k,old,new| new && !new.to_s.empty? ? new : old }
    end
    @conf[:collect] = [@conf[:collect]].flatten.map(&:to_s)

    @title = self.conf(:title)
    @desc = self.conf(:desc) || ''
    @collect = self.conf(:collect)
    @paginate = self.conf(:paginate) ? self.conf(:paginate).to_i : false

    @user_index = self.conf(:index) || -1

    @date = if self.conf(:date)
      @date = Time.parse(self.conf(:date))
    else
      @date = @path.input.ctime
    end
  end
  attr_reader :site
  attr_reader :path
  attr_reader :section
  attr_reader :type
  attr_reader :title
  attr_reader :contents
  attr_reader :collect
  attr_reader :paginate
  attr_reader :desc
  attr_reader :date
  attr_reader :user_index
  attr_accessor :index

  def conf(key)
    key = key.to_sym
    unless @conf.has_key?(key)
      raise ArgumentError "No such configuration: #{key}"
    end
    return @conf[key]
  end

  def index?
    return @path.name == 'index' || @autoindex
  end

  def trail
    if index?
      return @section.path.link
    else
      return @path.link
    end
  end

  def has_erb?
    return @erb
  end

  def link_to(**args)
    args[:text] ||= @title
    return HTML.link_to(self, **args)
  end

  def to_s
    return @path.input_relative.to_s
  end

  def inspect
    return %Q(#<AW::Page:"#{self}">)
  end

  def <=>(b)
    @date <=> b.date
  end
end


class Collection
  def initialize(page, pages, pagesize)
    @page      = page
    @pages     = pages
    @pagesize  = pagesize
    @pagecount = (@pages.length / @pagesize.to_f).ceil
    @range     = (1..@pagecount)
  end

  attr_reader :range
  attr_reader :pagecount

  def paginate(index, sort: :date, ascending: true)
    index = index - 1
    first = index * @pagesize
    last  = first + (@pagesize - 1)
    pages = @pages.sort {|pa,pb| pa.send(sort) <=> pb.send(sort) }
    pages.reverse! unless ascending
    pages[first..last]
  end

  def links(index)
    links = []
    @range.each do |i|
      if i == index
        links << "<span class=\"pagination pagination-current\">#{index}</span>"
      else
        links << @page.link_to(text: i, klass: 'pagination pagination-link', index: i)
      end
    end
    links.join("\n")
  end

  def inspect
    return "#<AW::Collection:[#{@page.collect.join(",")}]>"
  end
end

end # module ARKWEB

