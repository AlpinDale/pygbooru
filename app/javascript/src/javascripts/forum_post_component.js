import Utility from "./utility";

class ForumPostComponent {
  static initialize() {
    if ($("#c-forum-topics #a-show, #c-forum-posts #a-show").length) {
      $(document).on("click.danbooru.forum_post", ".edit_forum_post_link", ForumPostComponent.showEditPostForm);
      $(document).on("click.danbooru.forum_post", ".edit_forum_topic_link", ForumPostComponent.showEditTopicForm);
      $(document).on("click.danbooru.forum_post", "#new-response-link", ForumPostComponent.showNewForumPostForm);
      $(document).on("click.danbooru.forum_post", ".forum-post-copy-id", ForumPostComponent.copyID);
      $(document).on("click.danbooru.forum_post", ".forum-post-copy-link", ForumPostComponent.copyLink);
    }
  }

  static showNewForumPostForm(e) {
    $("#topic-response").show();
    $("#forum_post_body").get(0).scrollIntoView(false);
    $("#forum_post_body").selectEnd();
    e.preventDefault();
  }

  static showEditPostForm(e) {
    $(this).closest(".forum-post").find(".edit_forum_post").show();
    e.preventDefault();
  }

  static showEditTopicForm(e) {
    $(this).closest(".forum-post").find(".edit_forum_topic").show();
    e.preventDefault();
  }

  static async copyID(e) {
    let id = $(this).closest(".forum-post").data("id");
    let link = `forum #${id}`;
    Utility.copyToClipboard(link);
    e.preventDefault();
  }

  static async copyLink(e) {
    let id = $(this).closest(".forum-post").data("id");
    let link = `${window.location.origin}/forum_posts/${id}`;
    Utility.copyToClipboard(link);
    e.preventDefault();
  }
}

$(document).ready(ForumPostComponent.initialize);

export default ForumPostComponent;
