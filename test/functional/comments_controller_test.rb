require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  context "A comments controller" do
    setup do
      @mod = FactoryBot.create(:moderator_user)
      @user = FactoryBot.create(:member_user, name: "cirno")
      @post = create(:post, id: 100)

      CurrentUser.user = @user
    end

    teardown do
      CurrentUser.user = nil
    end

    context "index action" do
      context "grouped by post" do
        should "render all comments for .js" do
          @comment = as(@user) { create(:comment, post: @post) }
          get comments_path(post_id: @post.id), xhr: true

          assert_response :success
          assert_equal("text/javascript", response.media_type)
        end

        should "show posts with visible comments" do
          @comment = as(@user) { create(:comment, post: @post) }
          get comments_path(group_by: "post")

          assert_response :success
          assert_select "div#post_#{@post.id}", 1
          assert_select "div#post_#{@post.id} .comment", 1
          assert_select "div#post_#{@post.id} .show-all-comments-link", 0
        end

        should "not bump posts with nonbumping comments" do
          as(@user) { create(:comment, post: @post, do_not_bump_post: true) }
          get comments_path(group_by: "post")

          assert_response :success
          assert_select "#post_#{@post.id}", 0
        end

        should "not bump posts with only deleted comments" do
          as(@user) { create(:comment, post: @post, is_deleted: true) }
          get comments_path(group_by: "post")

          assert_response :success
          assert_select "#post_#{@post.id}", 0
        end
      end

      context "grouped by comment" do
        should "render" do
          create(:comment)

          get comments_path(group_by: "comment")
          assert_response :success
        end
      end

      context "searching" do
        setup do
          @user_comment = create(:comment, created_at: 10.minutes.ago, updated_at: 3.minutes.ago, post: @post, score: 10, do_not_bump_post: true, creator: @user)
          @mod_comment = create(:comment, post: build(:post, tag_string: "touhou"), body: "blah", is_sticky: true, creator: @mod)
          @deleted_comment = create(:comment, creator: create(:user, name: "deleted"), is_deleted: true, is_sticky: true, do_not_bump_post: true, score: 10, body: "blah")
        end

        context "as a regular user" do
          setup { CurrentUser.user = @user }

          should respond_to_search(other_params: {group_by: "comment"}).with { [@deleted_comment, @mod_comment, @user_comment] }
          should respond_to_search(body_matches: "blah").with { @mod_comment }
          should respond_to_search(score: 10).with { @user_comment }
          should respond_to_search(is_sticky: "true").with { @mod_comment }
          should respond_to_search(is_deleted: "true").with { @deleted_comment }
          should respond_to_search(do_not_bump_post: "true").with { @user_comment }
          should respond_to_search(is_edited: "true").with { @user_comment }
          should respond_to_search(is_edited: "false").with { [@deleted_comment, @mod_comment] }
          should respond_to_search(creator_name: "deleted").with { [] }
        end

        context "as the creator of a deleted comment" do
          setup { CurrentUser.user = @deleted_comment.creator }

          should respond_to_search(other_params: {group_by: "comment"}).with { [@deleted_comment, @mod_comment, @user_comment] }
          should respond_to_search(body_matches: "blah").with { @mod_comment }
          should respond_to_search(score: 10).with { @user_comment }
          should respond_to_search(is_sticky: "true").with { @mod_comment }
          should respond_to_search(is_deleted: "true").with { @deleted_comment }
          should respond_to_search(do_not_bump_post: "true").with { @user_comment }
          should respond_to_search(is_edited: "true").with { @user_comment }
          should respond_to_search(is_edited: "false").with { [@deleted_comment, @mod_comment] }
          should respond_to_search(creator_name: "deleted").with { @deleted_comment }
        end

        context "as a moderator" do
          setup { CurrentUser.user = @mod }

          should respond_to_search(other_params: {group_by: "comment"}).with { [@deleted_comment, @mod_comment, @user_comment] }
          should respond_to_search(body_matches: "blah").with { [@deleted_comment, @mod_comment] }
          should respond_to_search(score: 10).with { [@deleted_comment, @user_comment] }
          should respond_to_search(is_sticky: "true").with { [@deleted_comment, @mod_comment] }
          should respond_to_search(is_deleted: "true").with { @deleted_comment }
          should respond_to_search(do_not_bump_post: "true").with { [@deleted_comment, @user_comment] }
          should respond_to_search(is_edited: "true").with { @user_comment }
          should respond_to_search(is_edited: "false").with { [@deleted_comment, @mod_comment] }
          should respond_to_search(creator_name: "deleted").with { @deleted_comment }
        end

        context "using includes" do
          should respond_to_search(post_id: 100).with { @user_comment }
          should respond_to_search(post_tags_match: "touhou").with { @mod_comment }
          should respond_to_search(creator_name: "cirno").with { @user_comment }
          should respond_to_search(creator: {level: User::Levels::MODERATOR}).with { @mod_comment }
        end
      end

      context "for atom feeds" do
        should "render" do
          @comment = as(@user) { create(:comment, post: @post) }
          get comments_path(format: "atom")
          assert_response :success
        end

        should "not show comments on restricted posts" do
          @post.update!(is_banned: true)
          @comment = as(@user) { create(:comment, post: @post) }

          get comments_path(format: "atom")
          assert_response :success
          assert_equal(0, response.parsed_body.css("entry").size)
        end
      end
    end

    context "search action" do
      should "render" do
        get search_comments_path
        assert_redirected_to comments_path(group_by: "comment")
      end
    end

    context "show action" do
      should "render" do
        @comment = create(:comment, post: @post)
        get comment_path(@comment.id)
        assert_redirected_to post_path(@comment.post, anchor: "comment_#{@comment.id}")
      end

      context "for a deleted comment" do
        should "not show the creator, updater, or body to non-Moderators" do
          @comment = create(:comment, post: @post, is_deleted: true)
          get comment_path(@comment.id), as: :json

          assert_response :success
          assert_equal(@comment.id, response.parsed_body["id"])
          assert_nil(response.parsed_body["creator_id"])
          assert_nil(response.parsed_body["updater_id"])
          assert_nil(response.parsed_body["body"])
        end
      end
    end

    context "edit action" do
      should "render" do
        @comment = create(:comment, post: @post)
        get_auth edit_comment_path(@comment.id), @user
        assert_response :success
      end
    end

    context "update action" do
      setup do
        @comment = create(:comment, post: @post)
      end

      context "when updating another user's comment" do
        should "succeed if updater is a moderator" do
          put_auth comment_path(@comment.id), @mod, params: {comment: {body: "abc"}}, xhr: true

          assert_equal("abc", @comment.reload.body)
          assert_match(/updated comment ##{@comment.id}/, ModAction.last.description)
          assert_equal(@comment, ModAction.last.subject)
          assert_equal(@mod, ModAction.last.creator)
          assert_response :success
        end

        should "fail if updater is not a moderator" do
          @mod_comment = as(@mod) { create(:comment, post: @post) }
          put_auth comment_path(@mod_comment.id), @user, params: {comment: {body: "abc"}}, xhr: true
          assert_not_equal("abc", @mod_comment.reload.body)
          assert_response 403
        end
      end

      context "when stickying a comment" do
        should "succeed if updater is a moderator" do
          put_auth comment_path(@comment.id), @mod, params: {comment: {is_sticky: true}}, xhr: true

          assert_equal(true, @comment.reload.is_sticky)
          assert_match(/updated comment ##{@comment.id}/, ModAction.last.description)
          assert_equal(@comment, ModAction.last.subject)
          assert_equal(@mod, ModAction.last.creator)
          assert_response :success
        end

        should "fail if updater is not a moderator" do
          put_auth comment_path(@comment.id), @user, params: {comment: {is_sticky: true}}, xhr: true
          assert_response 403
          assert_equal(false, @comment.reload.is_sticky)
        end
      end

      context "for a deleted comment" do
        should "not allow the creator to edit the comment" do
          @comment.update!(is_deleted: true)
          put_auth comment_path(@comment.id), @user, params: { comment: { body: "blah" }}, xhr: true

          assert_response 403
          assert_not_equal("blah", @comment.reload.body)
        end
      end

      should "update the body" do
        put_auth comment_path(@comment.id), @user, params: {comment: {body: "abc"}}, xhr: true

        assert_equal("abc", @comment.reload.body)
        assert_match(/updated comment ##{@comment.id}/, ModAction.last.description)
        assert_equal(@comment, ModAction.last.subject)
        assert_equal(@user, ModAction.last.creator)
        assert_response :success
      end

      should "allow changing the body and is_deleted" do
        put_auth comment_path(@comment.id), @user, params: {comment: {body: "herp derp", is_deleted: true}}, xhr: true

        assert_equal("herp derp", @comment.reload.body)
        assert_equal(true, @comment.is_deleted)
        assert_match(/deleted comment ##{@comment.id}/, ModAction.last.description)
        assert_equal(@comment, ModAction.last.subject)
        assert_equal(@user, ModAction.last.creator)
        assert_response :success
      end

      should "not allow changing do_not_bump_post or post_id" do
        @another_post = as(@user) { create(:post) }

        put_auth comment_path(@comment.id), @comment.creator, params: { do_not_bump_post: true }
        assert_response 403
        assert_equal(false, @comment.reload.do_not_bump_post)

        put_auth comment_path(@comment.id), @comment.creator, params: { post_id: @another_post.id }
        assert_response 403
        assert_equal(@post.id, @comment.reload.post_id)
      end
    end

    context "new action" do
      should "work" do
        get_auth new_comment_path, @user
        assert_response :success
      end

      should "work when quoting a post" do
        @comment = create(:comment)
        get_auth new_comment_path(id: @comment.id), @user, as: :javascript
        assert_response :success
      end

      should "not allow quoting a deleted comment" do
        @comment = create(:comment, is_deleted: true)
        get_auth new_comment_path(id: @comment.id), @user
        assert_response 403
      end
    end

    context "create action" do
      should "create a comment" do
        assert_difference("Comment.count", 1) do
          post_auth comments_path, @user, params: { comment: { post_id: @post.id, body: "blah" } }
        end
        comment = Comment.last
        assert_redirected_to post_path(comment.post)
      end

      should "not allow commenting on nonexistent posts" do
        assert_difference("Comment.count", 0) do
          post_auth comments_path, @user, params: { comment: { post_id: -1, body: "blah" } }
        end
        assert_redirected_to comments_path
      end
    end

    context "destroy action" do
      should "mark comment as deleted" do
        @comment = create(:comment, post: @post)
        delete_auth comment_path(@comment.id), @user

        assert_equal(true, @comment.reload.is_deleted)
        assert_redirected_to @comment
        assert_match(/deleted comment ##{@comment.id}/, ModAction.last.description)
        assert_equal(@comment, ModAction.last.subject)
        assert_equal(@user, ModAction.last.creator)
      end

      should "mark all pending moderation reports against the comment as handled" do
        @comment = create(:comment, post: @post)
        report1 = create(:moderation_report, model: @comment, status: :pending)
        report2 = create(:moderation_report, model: @comment, status: :rejected, updater: create(:user))
        delete_auth comment_path(@comment.id), @mod

        assert_redirected_to @comment
        assert_equal(true, @comment.reload.is_deleted)
        assert_equal(true, report1.reload.handled?)
        assert_equal(true, report2.reload.rejected?)
        assert_equal(1, ModAction.moderation_report_handled.where(creator: @mod).count)
      end
    end

    context "undelete action" do
      should "allow Moderators to undelete comments" do
        @comment = create(:comment, post: @post, is_deleted: true)
        post_auth undelete_comment_path(@comment.id), @mod

        assert_redirected_to(@comment)
        assert_equal(false, @comment.reload.is_deleted)
        assert_match(/updated comment ##{@comment.id}/, ModAction.last.description)
        assert_equal(@comment, ModAction.last.subject)
        assert_equal(@mod, ModAction.last.creator)
      end

      should "not allow normal Members to undelete their own comments" do
        @comment = create(:comment, post: @post, is_deleted: true)

        post_auth undelete_comment_path(@comment.id), @user
        assert_response 403
        assert(@comment.reload.is_deleted?)
      end
    end
  end
end
