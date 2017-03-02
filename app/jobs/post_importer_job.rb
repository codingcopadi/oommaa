# import a single FB "post" (may be post, image or video) and its page
class PostImporterJob
  include Sidekiq::Worker
  sidekiq_options queue: "posts"

  def perform(url, user_email = "user@example.com", brand_id = nil)
    object_id, type = FbURLParser.new(url).call
    return unless object_id

    begin
      data = case type
      when :photo
        FBPhotoReader.new(object_id: object_id, token: token).call
      when :post
        FBPostReader.new(object_id: object_id, token: token).call
      when :video
        FBVideoReader.new(object_id: object_id, token: token).call
      else # type not supported
        return
      end
    rescue Koala::Facebook::ClientError => e
      if e.fb_error_code == 100
        # so it's a photo...
        if e.message.match?(/nonexisting field.*type \(Photo\)/i)
          FBPhotoReader.new(object_id: object_id, token: token).call
        # so it's a post...
        elsif e.message.match?(/nonexisting field.*type \(Post\)/i)
          FBPostReader.new(object_id: object_id, token: token).call
        # cannot read for some reason (deleted? old?)
        elsif e.message.match?(/Object with ID .* does not exist/i)
          logger.info "PostImporterJob: cannot read URL, skipping #{url}"
          return
        else
          raise e
        end
      else
        raise e
      end
    end

    data["id"] = data["id"].split("_").last

    return if FacebookPost.exists?(facebook_id: data["id"])

    page = find_or_create_page(data["from"]["id"], brand_id)
    # create a post from the submitted URL
    create_post(data, page, user_email)
  end

  private

  def find_or_create_page(object_id, brand_id)
    data = FBPageReader.new(object_id: object_id, token: token).call

    if page = FacebookPage.find_by(facebook_id: data["id"])
      if brand_id && !brand_id.in?(page.brand_ids)
        page.brand_ids << brand_id
        page.save!
        logger.info "PostImporterJob: Brand ##{brand_id} added to FacebookPage #{page.id}"
      end
      return page
    end

    brand_ids = ([brand_id] + matching_brand_ids_for(data["name"])).uniq.compact

    page = FacebookPage.create!(
      facebook_id: data["id"],
      name: data["name"],
      url: data["link"],
      image_url: data.dig("picture", "data", "url"),
      brand_ids: brand_ids
    )

    logger.info "PostImporterJob: created new FacebookPage #{page.id}"
    page
  end

  def create_post(data, page, user_email)
    post = page.facebook_posts.create!(
      facebook_id: data["id"],
      message: data["name"],
      published_at: data["created_time"],
      permalink: data["permalink_url"],
      image_url: data["picture"],
      link: data["link"],
      # we start as blacklisted, but PostStatusJob will also run
      status: "blacklisted",
      blacklisted_at: Time.now,
      blacklisted_by: user_email
    )

    post.parse_all_links!
    # mark its domains as blacklisted
    Domain.blacklist_new_domains!(post.all_domains)
    # this will **probably** keep the post as blacklisted
    PostStatusJob.perform_async(post.id)
    # import screenshots
    PostScreenshotsJob.perform_async(post.id)
    logger.info "PostImporterJob: created new FacebookPost #{post.id}"

    post
  end

  def matching_brand_ids_for(term)
    Brand.select(:id, :name).find_all do |brand|
      term.to_s.match?(/#{brand.name}/i)
    end.map(&:id)
  end

  def token
    Rails.configuration.counterfind["facebook"]["tokens"].sample
  end

  def logger
    @logger ||= Logger.new(Rails.root.join('log/jobs.log'))
  end
end
