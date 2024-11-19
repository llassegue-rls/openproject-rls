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

require "rails_helper"

RSpec.describe Project::LifeCycle do
  it "cannot be instantiated" do
    expect { described_class.new }.to raise_error(NotImplementedError)
  end

  it "cannot be instantiated with an invalid type" do
    expect { described_class.new(type: "InvalidType") }.to raise_error(ActiveRecord::SubclassNotFound)
  end

  it "can be instantiated with a valid type" do
    expect { described_class.new(type: "Project::Gate") }.not_to raise_error
  end

  describe "with an instantiated Gate" do
    subject { build :project_gate }

    it "allows setting a life_cycle" do
      expected_life_cycle = create :gate
      subject.life_cycle = expected_life_cycle

      expect(subject.save).to be(true)
      expect(subject.reload.life_cycle).to eq(expected_life_cycle)
    end

    context "when the Gate is already saved" do
      subject { create :project_gate }

      it "does not allow updating the life_cycle" do
        expect(subject).to have_readonly_attribute(:life_cycle_id)
      end
    end
  end

  # For more specs see:
  # - spec/support/shared/project_life_cycle_helpers.rb
  # - spec/models/project/gate_spec.rb
  # - spec/models/project/stage_spec.rb
end
