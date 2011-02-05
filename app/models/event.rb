class Event < ActiveRecord::Base
  # if more types are added, make sure to update app/views/events/_event,
  # which currently assumes the #{event}ed always converts an event to
  # its past tense form
  # TODO objection breaks this convention
  EVENT_TYPES = ["yes_vote", "no_vote", "second", "objection", "objection_withdrawn", "comment"]
  HUMAN_READABLE_EVENT_TYPES = {
    'yes_vote' => 'Yes Vote',
    'no_vote' => 'No Vote',
    'second' => 'Second',
    'objection' => 'Objection',
    'objection_withdrawn' => 'Objection Withdrawn',
    'comment' => 'Comment'
  }

  belongs_to  :member
  belongs_to  :motion

  validates   :member_id,   :uniqueness => {
                              :scope => [:motion_id, :event_type]
                            },
                            :unless => :comment?
  validates   :event_type,  :presence   => true,
                            :inclusion  => {
                              :in => EVENT_TYPES
                            }

  validate    :motion_creator_cannot_second,  :if => :is_second?
  after_create :update_waitingsecond_motion, :if => :is_second?

  scope :votes,   where(:event_type  => %w(yes_vote no_vote))
  scope :yes_votes, where(:event_type => 'yes_vote')
  scope :no_votes, where(:event_type => 'no_vote')
  scope :seconds,    where(:event_type  => "second")
  scope :objections, where(:event_type  => "objection")
  scope :objection_withdrawns, where(:event_type => 'objection_withdrawn')
  scope :for_motion, lambda { |motion_id| where(:motion_id => motion_id) }

  # @return [true, false] Whether or not this is a Voting Event
  def is_vote?
    %w(yes_vote no_vote).include?(event_type)
  end
  alias :vote? :is_vote?

  # @return [true, false] Whether or not this is a Seconding Event
  def is_second?
    event_type == "second"
  end
  alias :second? :is_second?

  # @return [true, false] Whether or not this is a Objecting Event
  def is_objection?
    event_type == "objection"
  end
  alias :objection? :is_objection?

  def comment?
    event_type == 'comment'
  end

  def formatted_event_type(format = :human)
    if format == :human
      HUMAN_READABLE_EVENT_TYPES[event_type]
    else
      event_type
    end
  end

private
  # Will error if the motion creator attempts to second their motion
  def motion_creator_cannot_second
    errors.add(:member, "Member cannot second a motion that they created.") if motion.member == member
  end

  def update_waitingsecond_motion
    return unless motion.waitingsecond?
    if motion.expedited?
      motion.voting! if motion.can_expedite?
    else
      motion.discussing! if motion.can_discuss?
    end
  end
end
