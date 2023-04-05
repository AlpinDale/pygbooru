require 'test_helper'

class ModActionsControllerTest < ActionDispatch::IntegrationTest
  context "The mod actions controller" do
    context "index action" do
      should "work" do
        create(:mod_action)
        get mod_actions_path
        assert_response :success
      end

      should "hide ip ban actions from non-moderators" do
        ip_ban = create(:ip_ban)
        create(:mod_action, description: "undeleted ip ban for #{ip_ban.ip_addr}", subject: ip_ban)

        get mod_actions_path(search: { category: "ip_ban_undelete" }), as: :json

        assert_response :success
        assert_equal(0, response.parsed_body.count)
      end

      should "hide moderation report actions from non-moderators" do
        report = as(create(:user)) { create(:moderation_report, model: create(:comment)) }
        create(:mod_action, description: "handled modreport ##{report.id}", category: "moderation_report_handled", subject: report)

        get mod_actions_path, as: :json

        assert_response :success
        assert_equal(0, response.parsed_body.count)
      end

      context "searching" do
        setup do
          @mod_action = create(:mod_action, description: "blah")
          @promote_action = create(:mod_action, category: "user_level_change", creator: create(:builder_user, name: "rumia"))
        end

        should respond_to_search({}).with { [@promote_action, @mod_action] }
        should respond_to_search(category: ModAction.categories["user_level_change"].to_s).with { @promote_action }
        should respond_to_search(description_matches: "blah").with { @mod_action }

        should respond_to_search(creator_name: "rumia").with { @promote_action }
        should respond_to_search(creator: { level: User::Levels::BUILDER }).with { @promote_action }
      end

      context "category enum searches" do
        setup do
          @ban = create(:mod_action, category: :post_ban)
          @unban = create(:mod_action, category: :post_unban)
        end

        should respond_to_search(category: "post_ban").with { [@ban] }
        should respond_to_search(category: "post_unban").with { [@unban] }
        should respond_to_search(category: "Post_ban").with { [@ban] }
        should respond_to_search(category: "post_ban post_unban").with { [@unban, @ban] }
        should respond_to_search(category: "post_ban,post_unban").with { [@unban, @ban] }
        should respond_to_search(category: "44").with { [@ban] }
        should respond_to_search(category_id: "44").with { [@ban] }
        should respond_to_search(category_id: "44,45").with { [@unban, @ban] }
        should respond_to_search(category_id: ">=44").with { [@unban, @ban] }
      end
    end

    context "show action" do
      should "work" do
        @mod_action = create(:mod_action)
        get mod_action_path(@mod_action)
        assert_redirected_to mod_actions_path(search: { id: @mod_action.id })
      end
    end
  end
end
