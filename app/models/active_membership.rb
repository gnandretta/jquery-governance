class ActiveMembership < ActiveRecord::Base
  belongs_to :member

  def self.active_at(time)
    where("start_time <= ?", time).
      where("end_time >= ? OR end_time IS NULL", time)
  end

  def self.members_active_at(time)
    members = active_at(time).map(&:member)
    members.uniq
  end
end
