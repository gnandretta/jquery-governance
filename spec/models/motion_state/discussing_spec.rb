require 'spec_helper'

module MotionState
  describe Discussing do
    before(:all) do
      @active_member = Factory(:membership).member
      @inactive_member = Factory(:expired_membership).member
      @motion = Factory(:discussing_motion)
      @motion_state = @motion.state
    end

    describe ".public?" do
      it "returns false" do
        Discussing.should_not be_public
      end
    end

    describe ".open?" do
      it "returns true" do
        Discussing.should be_open
      end
    end

    describe ".closed?" do
      it "returns false" do
        Discussing.should_not be_closed
      end
    end

    describe "permit?" do
      it "allows an active member to see the motion" do
        @motion_state.permit?(:see, @active_member).should be_true
      end

      it "doesn't allow an inactive member to see the motion" do
        @motion_state.permit?(:see, @inactive_member).should be_false
      end

      it "allows an active member to object the motion" do
        @motion_state.permit?(:object, @active_member).should be_true
      end

      it "doesn't allow a member to object the motion more than once" do
        @active_member.object(@motion)
        @motion_state.permit?(:object, @active_member).should be_false
      end

      it "doesn't allow an inactive member to object the motion" do
        @motion_state.permit?(:object, @inactive_member).should be_false
      end

      it "doesn't allow an active member to vote the motion" do
        @motion_state.permit?(:vote, @active_member).should be_false
      end

      it "doesn't allow an inactive member to vote the motion" do
        @motion_state.permit?(:vote, @inactive_member).should be_false
      end

      it "doesn't allow an active member to second another member's motion" do
        @motion_state.permit?(:second, @active_member).should be_false
      end

      it "doesn't allow an active member to second its own motion" do
        @owned_motion_state = Factory(:discussing_motion, :member => @active_member).state
        @owned_motion_state.permit?(:second, @active_member).should be_false
      end

      it "doesn't allow an inactive member to second the motion" do
        @motion_state.permit?(:second, @inactive_member).should be_false
      end
    end

    describe "scheduled_update" do
      describe "for a non objected motion" do
        before do
          @motion = Factory(:discussing_motion)
          @motion_state = @motion.state
        end

        it "doesn't update the motion state before 24 hours" do
          @motion_state.scheduled_update(23.hours)
          @motion.should be_discussing
        end

        it "updates the motion state to 'voting' after 24 hours" do
          @motion_state.scheduled_update(24.hours)
          @motion.should be_voting
        end
      end

      describe "for an objected motion" do
        before do
          @motion = Factory(:discussing_motion)
          @motion_state = @motion.state
          Factory(:membership).member.object(@motion)
        end

        it "doesn't update the motion state before 48 hours" do
          @motion_state.scheduled_update(47.hours)
          @motion.should be_discussing
        end

        it "updates the motion state to 'voting' after 48 hours" do
          @motion_state.scheduled_update(48.hours)
          @motion.should be_voting
        end
      end
    end
  end
end
