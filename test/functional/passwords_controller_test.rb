require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  context "The passwords controller" do
    setup do
      @user = create(:user, password: "12345")
    end

    context "edit action" do
      should "work" do
        get_auth edit_user_password_path(@user), @user
        assert_response :success
      end
    end

    context "update action" do
      should "update the password when given a valid old password" do
        put_auth user_password_path(@user), @user, params: { user: { old_password: "12345", password: "abcde", password_confirmation: "abcde" } }

        assert_redirected_to @user
        assert_equal(false, @user.reload.authenticate_password("12345"))
        assert_equal(@user, @user.authenticate_password("abcde"))
        assert_equal(true, @user.user_events.password_change.exists?)
      end

      should "update the password when given a valid login key" do
        signed_user_id = Danbooru::MessageVerifier.new(:login).generate(@user.id)
        put_auth user_password_path(@user), @user, params: { user: { password: "abcde", password_confirmation: "abcde", signed_user_id: signed_user_id } }

        assert_redirected_to @user
        assert_equal(false, @user.reload.authenticate_password("12345"))
        assert_equal(@user, @user.authenticate_password("abcde"))
        assert_equal(true, @user.user_events.password_change.exists?)
      end

      should "not update the password when a deleted user tries to reset their password with a valid login key" do
        @user.update!(is_deleted: true)
        old_password = @user.bcrypt_password_hash

        signed_user_id = Danbooru::MessageVerifier.new(:login).generate(@user.id)
        put_auth user_password_path(@user), @user, params: { user: { password: "abcde", password_confirmation: "abcde", signed_user_id: signed_user_id } }

        assert_response 403
        assert_equal(old_password, @user.reload.bcrypt_password_hash)
        assert_equal(false, @user.user_events.password_change.exists?)
      end

      should "allow the site owner to change the password of other users" do
        @owner = create(:owner_user)
        put_auth user_password_path(@user), @owner, params: { user: { password: "abcde", password_confirmation: "abcde" } }

        assert_redirected_to @user
        assert_equal(false, @user.reload.authenticate_password("12345"))
        assert_equal(@user, @user.authenticate_password("abcde"))
      end

      should "not allow non-owners to change the password of other users" do
        @admin = create(:admin_user)
        put_auth user_password_path(@user), @admin, params: { user: { old_password: "12345", password: "abcde", password_confirmation: "abcde" } }

        assert_response 403
        assert_equal(@user, @user.reload.authenticate_password("12345"))
        assert_equal(false, @user.authenticate_password("abcde"))
      end

      should "not update the password when given an invalid old password" do
        put_auth user_password_path(@user), @user, params: { user: { old_password: "3qoirjqe", password: "abcde", password_confirmation: "abcde" } }

        assert_response :success
        assert_equal(@user, @user.reload.authenticate_password("12345"))
        assert_equal(false, @user.authenticate_password("abcde"))
        assert_equal(false, @user.user_events.password_change.exists?)
      end

      should "not update the password when password confirmation fails for the new password" do
        put_auth user_password_path(@user), @user, params: { user: { old_password: "12345", password: "abcde", password_confirmation: "qerogijqe" } }

        assert_response :success
        assert_equal(@user, @user.reload.authenticate_password("12345"))
        assert_equal(false, @user.authenticate_password("abcde"))
      end
    end
  end
end
