# frozen_string_literal: true

class ForumPostVote < ApplicationRecord
  belongs_to :creator, class_name: "User"
  belongs_to :forum_post
  belongs_to :bulk_update_request, primary_key: :forum_post_id, foreign_key: :forum_post_id, optional: true

  validates :creator_id, uniqueness: {scope: :forum_post_id}
  validates :score, inclusion: {in: [-1, 0, 1]}

  scope :up, -> {where(score: 1)}
  scope :down, -> {where(score: -1)}

  def self.visible(user)
    all
  end

  def self.forum_post_matches(params, current_user)
    return all if params.blank?
    where(forum_post_id: ForumPost.search(params, current_user).reorder(nil).select(:id))
  end

  def self.search(params, current_user)
    q = search_attributes(params, [:id, :created_at, :updated_at, :score, :creator, :forum_post], current_user: current_user)
    q = q.forum_post_matches(params[:forum_post], current_user)
    q.apply_default_order(params)
  end

  def up?
    score == 1
  end

  def down?
    score == -1
  end

  def meh?
    score == 0
  end

  def vote_type
    case score
    when 1
      "up"
    when -1
      "down"
    when 0
      "meh"
    end
  end

  def self.available_includes
    [:creator, :forum_post]
  end
end
