require 'test_helper'

class ModActionTest < ActiveSupport::TestCase
  context "A mod action" do
    setup do
      @user = create(:user)
      @mod = create(:moderator_user)
    end

    should "hide ip addresses from non-moderators in ip ban modactions" do
      as(@mod) { create(:ip_ban, ip_addr: "1.1.1.1", reason: "test") }

      assert_equal(0, ModAction.visible(@user).count)
      assert_equal(1, ModAction.visible(@mod).count)
    end
  end
end
