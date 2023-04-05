# frozen_string_literal: true

module ForumTopicsHelper
  def forum_topic_category_select(object, field)
    select(object, field, ForumTopic.reverse_category_mapping.to_a)
  end

  def available_min_user_levels
    ForumTopic::MIN_LEVELS.select { |_name, level| level <= CurrentUser.level }.to_a
  end

  def new_forum_topic?(topic, read_forum_topics)
    read_forum_topics.map(&:id).exclude?(topic.id)
  end

  def forum_topic_status(topic)
    if topic.bulk_update_requests.any?(&:is_pending?)
      :pending
    elsif topic.category_name == "Tags" && topic.bulk_update_requests.present? && topic.bulk_update_requests.all?(&:is_approved?)
      :approved
    elsif topic.category_name == "Tags" && topic.bulk_update_requests.present? && topic.bulk_update_requests.all?(&:is_rejected?)
      :rejected
    else
      nil
    end
  end

  def forum_post_vote_icon(vote)
    case vote.score
    when 1
      upvote_icon
    when -1
      downvote_icon
    else
      meh_icon
    end
  end
end
