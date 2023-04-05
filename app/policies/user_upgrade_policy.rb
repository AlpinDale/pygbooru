# frozen_string_literal: true

class UserUpgradePolicy < ApplicationPolicy
  def create?
    !user.is_anonymous?
  end

  def new?
    true
  end

  def show?
    record.recipient == user || record.purchaser == user || user.is_owner?
  end

  def refund?
    user.is_owner? && record.complete?
  end

  def receipt?
    (record.purchaser == user || user.is_owner?) && record.has_receipt?
  end

  def payment?
    user.is_owner? && record.has_payment?
  end
end
