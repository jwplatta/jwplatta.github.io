Jekyll::Hooks.register :posts, :post_render do |post|
  img_path = post.data['img_path']
  next unless img_path && !img_path.empty?

  # Ensure img_path ends with /
  img_path = img_path.end_with?('/') ? img_path : "#{img_path}/"

  # Replace relative img src attributes (not starting with / or http)
  post.output = post.output.gsub(/(<img\s[^>]*src=")(?!\/|https?:\/\/)([^"]+)(")/) do
    "#{$1}#{img_path}#{$2}#{$3}"
  end
end
