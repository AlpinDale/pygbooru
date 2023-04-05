# frozen_string_literal: true

class WikiPagePolicy < ApplicationPolicy
  def update?
    unbanned? && (can_edit_locked? || !record.is_locked?)
  end

  def revert?
    update?
  end

  def can_edit_locked?
    user.is_builder?
  end

  def permitted_attributes
    [:title, :body, :other_names, :other_names_string, :is_deleted, (:is_locked if can_edit_locked?)].compact
  end
end
