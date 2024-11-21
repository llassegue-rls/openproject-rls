#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Reminders::ScheduleReminderJob do
  describe ".schedule" do
    let(:reminder) { create(:reminder) }

    subject { described_class.schedule(reminder) }

    it "enqueues a ScheduleReminderJob" do
      expect { subject }
        .to have_enqueued_job(described_class)
              .at(reminder.remind_at)
              .with(reminder)
    end
  end

  describe "#perform" do
    let(:reminder) { create(:reminder) }

    subject { described_class.new.perform(reminder) }

    it "creates a notification from the reminder" do
      notification_svc = nil
      expect { notification_svc = subject }.to change(Notification, :count).by(1) & change(ReminderNotification, :count).by(1)

      aggregate_failures "notification attributes" do
        notification = notification_svc.result

        expect(notification.actor_id).to eq(reminder.creator_id)
        expect(notification.recipient_id).to eq(reminder.creator_id)
        expect(notification.resource).to eq(reminder.remindable)
        expect(notification.reason).to eq("reminder")
      end
    end

    context "when the reminder is already scheduled" do
      before do
        reminder.update_column(:job_id, SecureRandom.uuid)
      end

      it "does not create a notification from the reminder" do
        expect { subject }.not_to change(Notification, :count)
      end
    end
  end
end
