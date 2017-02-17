require 'rails_helper'

RSpec.describe FacebookPost, type: :model do
  let(:post) { create(:facebook_post) }
  let(:post_with_links) {
    create(:facebook_post,
           message: "Get yours here >> http://bit.ly/2ksZpIv or here: https://bit.ly/2kHJRz3",
           link: "https://www.fanprint.com/products/tom-brady-goat-stats")
  }
  let(:post_with_fb_links) {
    create(:facebook_post,
           message: "Get yours here >> https://www.facebook.com/something or here: https://bit.ly/2kHJRz3",
           link: "https://www.facebook.com/fanprint/photos/a.469606039735992.116788.461431677220095/1531062416923677/?type=3")
  }
  let(:post_with_all_links) {
    create(:facebook_post, all_links: [
      "https://www.counterfind.com/something",
      "http://somedomain.co.uk/something",
      "http://somedomain.co.uk/something_else"
    ])
  }

  it { is_expected.to define_enum_for(:status) }

  it "has not_suspect status by default" do
    expect(post.status).to eq("not_suspect")
    expect(post.status_changed_at).to be_nil
  end

  describe "#change_status_to!" do
    it "sets status" do
      post.change_status_to!(:whitelisted)
      expect(post.status).to eq("whitelisted")
      expect(post.status_changed_at.to_s).to eq(Time.current.to_s)
    end

    it "call #blacklist_domains! on blacklisting" do
      expect(post).to receive(:blacklist_domains!)
      post.change_status_to!(:blacklisted)
    end

    it "does not call #blacklist_domains! on other status changes" do
      expect(post).to_not receive(:blacklist_domains!)
      post.change_status_to!(:whitelisted)
      post.change_status_to!(:not_suspect)
      post.change_status_to!(:suspect)
    end
  end

  describe "#raw_links" do
    it "extract links from message and link attributes" do
      expect(post_with_links.raw_links).to eq([
        "http://bit.ly/2ksZpIv",
        "https://bit.ly/2kHJRz3",
        "https://www.fanprint.com/products/tom-brady-goat-stats"
      ])
    end

    it "skips facebook.com links" do
      expect(post_with_fb_links.raw_links).to eq(["https://bit.ly/2kHJRz3"])
    end
  end

  describe "#all_domains" do
    it "works as expected" do
      expect(post_with_all_links.all_domains).to eq(["counterfind.com", "somedomain.co.uk"])
    end
  end

  describe "#parse_all_links!" do
    it "works as expected" do
      expect(post.all_links).to be_none
      VCR.use_cassette(:links_parser) do
        post.parse_all_links!
      end
      expect(post.all_links).to be_many
    end
  end
end
