guard 'rails' do
  watch('Gemfile.lock')
  watch(%r{^lib/.*})
  watch(%r{^config/.*\.rb})
  watch(%r{^config/counterfind\.yml})
  watch(%r{^config/database\.yml})
  watch(%r{^config/secrets\.yml})
  watch(%r{^config/initializers/.*})
  watch(%r{^config/environments/.*})
  watch(%r{^db/schema.rb})
end

guard 'livereload' do
  extensions = {
    css: :css,
    scss: :css,
    sass: :css,
    js: :js,
    coffee: :js,
    es6: :js,
    html: :html,
    png: :png,
    gif: :gif,
    jpg: :jpg,
    jpeg: :jpeg,
  }

  rails_view_exts = %w(erb haml slim)

  # file types LiveReload may optimize refresh for
  compiled_exts = extensions.values.uniq
  watch(%r{public/.+\.(#{compiled_exts * '|'})})

  extensions.each do |ext, type|
    watch(%r{
          (?:app|vendor)
          (?:/assets/\w+/(?<path>[^.]+) # path+base without extension
           (?<ext>\.#{ext})) # matching extension (must be first encountered)
          (?:\.\w+|$) # other extensions
          }x) do |m|
      path = m[1]
      "/assets/#{path}.#{type}"
    end
  end

  # file needing a full reload of the page anyway
  watch(%r{app/views/.+\.(#{rails_view_exts * '|'})$})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{app/policies/.+\.rb})
  watch(%r{config/locales/.+\.yml})
end
