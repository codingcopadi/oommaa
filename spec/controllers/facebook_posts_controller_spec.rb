require 'rails_helper'

RSpec.describe FacebookPostsController, type: :controller do
  let(:page) { create(:facebook_page) }
  let(:valid_attributes) { FactoryGirl.attributes_for(:facebook_post, facebook_page_id: page.id) }
  let!(:statuses) { FacebookPost.statuses.keys }

  before(:each) do
    login_user
  end

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #change_status" do
    it "changes status" do
      facebook_post = FacebookPost.create! valid_attributes
      expect(statuses).to be_many

      statuses.each do |status|
        post :change_status, params: { post_id: facebook_post.id, status: status }
        expect(assigns(:post).status).to eq(status)
      end
    end

    it "calls ShutDownCheckerJob on reported_to_facebook status change" do
      facebook_post = FacebookPost.create! valid_attributes

      post :change_status, params: { post_id: facebook_post.id, status: :reported_to_facebook }
      expect(ShutDownCheckerJob.jobs.size).to eq(1)
    end

    it "does not call ShutDownCheckerJob on other status change" do
      facebook_post = FacebookPost.create! valid_attributes

      (statuses - ["reported_to_facebook"]).each do |status|
        post :change_status, params: { post_id: facebook_post.id, status: status }
        expect(ShutDownCheckerJob.jobs.size).to eq(0)
      end
    end
  end

end
