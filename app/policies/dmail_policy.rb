# frozen_string_literal: true

class DmailPolicy < ApplicationPolicy
  def create?
    unbanned?
  end

  def index?
    !user.is_anonymous?
  end

  def mark_all_as_read?
    !user.is_anonymous?
  end

  def update?
    !user.is_anonymous? && record.owner_id == user.id
  end

  def show?
    return true if user.is_owner?
    !user.is_anonymous? && record.owner_id == user.id
  end

  def reportable?
    unbanned? && record.owner_id == user.id && record.is_recipient? && !record.is_automated? && !record.from.is_moderator? && record.created_at.after?(1.year.ago)
  end

  def permitted_attributes_for_create
    [:title, :body, :to_name, :to_id]
  end

  def permitted_attributes_for_update
    [:is_read, :is_deleted]
  end

  def api_attributes
    super + [:key]
  end
end
