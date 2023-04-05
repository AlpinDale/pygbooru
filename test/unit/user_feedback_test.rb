require 'test_helper'

class UserFeedbackTest < ActiveSupport::TestCase
  context "A user's feedback" do
    should "create a dmail" do
      user = FactoryBot.create(:user)
      gold = FactoryBot.create(:gold_user)
      member = FactoryBot.create(:user)
      dmail = <<~EOS.chomp
        @#{gold.name} created a "positive record":/user_feedbacks?search%5Buser_id%5D=#{user.id} for your account:

        good job!
      EOS

      assert_difference("Dmail.count", 1) do
        create(:user_feedback, creator: gold, user: user, body: "good job!")
        assert_equal(dmail, user.dmails.last.body)
      end
    end

    context "on validation" do
      should_not allow_value("").for(:body)
      should_not allow_value("   ").for(:body)
      should_not allow_value("\u200B").for(:body)
    end
  end
end
