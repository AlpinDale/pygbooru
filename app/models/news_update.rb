# frozen_string_literal: true

class NewsUpdate < ApplicationRecord
  belongs_to :creator, class_name: "User"
  belongs_to_updater
  scope :recent, -> {where("created_at >= ?", 2.weeks.ago).order(created_at: :desc).limit(5)}

  def self.visible(user)
    if user.is_admin?
      all
    else
      none
    end
  end

  def self.search(params, current_user)
    q = search_attributes(params, [:id, :created_at, :updated_at, :message, :creator, :updater], current_user: current_user)
    q.apply_default_order(params)
  end
end
