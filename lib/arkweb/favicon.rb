module ARKWEB

class FaviconFormat
  def initialize(site, input_path, output_dir, format, resolution, name=nil)
    @site = site
    @format = format
    @resolution = resolution
    @name = name || "favicon-#{resolution}"
    @path = Path.new(@site, input_path, output_dir,
      output_name: @name,
      output_ext: @format,
      relative: ''
    )
  end
  attr_reader :path
  attr_reader :format
  attr_reader :resolution
  attr_reader :name
end

class Favicon
  def initialize(site, input_path)
    @site = site
    @input_path = input_path
    @formats = []
    format('ico', '16x16', @site.out(:render), 'favicon')
    format('png', '16x16')
    format('png', '32x32')
    format('png', '96x96')
    format('png', '192x192')
  end
  attr_reader :formats

  private

  def format(ext, resolution, output_dir=nil, name=nil)
    output_dir = output_dir || @site.out(:favicons)
    @formats << FaviconFormat.new(@site, @input_path, output_dir, ext, resolution, name)
  end
end

end # module ARKWEB

