# frozen_string_literal: true

class IpAddressPolicy < ApplicationPolicy
  def show?
    user.is_moderator?
  end

  def html_data_attributes
    super & record.attributes.keys.map(&:to_sym)
  end
end
