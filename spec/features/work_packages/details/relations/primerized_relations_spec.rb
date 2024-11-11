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

RSpec.describe "Primerized work package relations tab",
               :js, :with_cuprite do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:full_wp_view) { Pages::FullWorkPackage.new(work_package) }
  let(:relations_tab) { Components::WorkPackages::Relations.new(work_package) }
  let(:relations_panel_selector) { ".detail-panel--relations" }
  let(:relations_panel) { find(relations_panel_selector) }
  let(:work_packages_page) { Pages::PrimerizedSplitWorkPackage.new(work_package) }
  let(:tabs) { Components::WorkPackages::PrimerizedTabs.new }

  let(:type1) { create(:type) }
  let(:type2) { create(:type) }

  let(:to1) { create(:work_package, type: type1, project:, start_date: Date.current, due_date: Date.current + 1.week) }
  let(:to2) { create(:work_package, type: type2, project:) }
  let(:to3) { create(:work_package, type: type1, project:) }
  let(:from1) { create(:work_package, type: type1, project:) }

  let!(:relation1) do
    create(:relation,
           from: work_package,
           to: to1,
           relation_type: Relation::TYPE_FOLLOWS)
  end
  let!(:relation2) do
    create(:relation,
           from: work_package,
           to: to2,
           relation_type: Relation::TYPE_RELATES)
  end
  let!(:relation3) do
    create(:relation,
           from: from1,
           to: work_package,
           relation_type: Relation::TYPE_BLOCKED)
  end
  let!(:relation4) do
    create(:relation,
           from: to1,
           to: from1,
           relation_type: Relation::TYPE_FOLLOWS)
  end
  let!(:child_wp) do
    create(:work_package,
           parent: work_package,
           type: type1,
           project: project)
  end
  let!(:not_yet_child_wp) do
    create(:work_package,
           type: type1,
           project:)
  end

  current_user { user }

  def label_for_relation_type(relation_type)
    I18n.t("work_package_relations_tab.relations.label_#{relation_type}_plural").capitalize
  end

  before do
    work_packages_page.visit_tab!("relations")
    expect_angular_frontend_initialized
    work_packages_page.expect_subject
    loading_indicator_saveguard
  end

  describe "rendering" do
    it "renders the relations tab" do
      scroll_to_element relations_panel
      expect(page).to have_css(relations_panel_selector)

      tabs.expect_counter("relations", 4)

      target = relation1.to == work_package ? "from" : "to"
      target_relation_type = target == "from" ? relation1.reverse_type : relation1.relation_type

      relation_row = relations_panel.find("[data-test-selector='op-relation-row-#{relation1.id}']")

      within(relations_panel) do
        # We reference the reverse type as the "from" node of the relation
        # is the currently visited work package, and the "to" node is the
        # relation target. From the current user's perspective on the work package's
        # page, this is the "reverse" relation.
        expect(page).to have_text(label_for_relation_type(target_relation_type))
      end
      within(relation_row) do
        expect(page).to have_text(relation1.to.type.name.upcase)
        expect(page).to have_text(relation1.to.id)
        expect(page).to have_text(relation1.to.status.name)
        expect(page).to have_text(relation1.to.subject)
        expect(page).to have_text(I18n.l(relation1.to.start_date))
        expect(page).to have_text(I18n.l(relation1.to.due_date))
      end

      relation_row = relations_panel.find("[data-test-selector='op-relation-row-#{relation2.id}']")

      within(relations_panel) do
        # We reference the reverse type as the "from" node of the relation
        # is the currently visited work package, and the "to" node is the
        # relation target. From the current user's perspective on the work package's
        # page, this is the "reverse" relation.
        expect(page).to have_text(label_for_relation_type(target_relation_type))
      end

      within(relation_row) do
        expect(page).to have_text(relation2.to.type.name.upcase)
        expect(page).to have_text(relation2.to.id)
        expect(page).to have_text(relation2.to.status.name)
        expect(page).to have_text(relation2.to.subject)
      end

      target = relation3.to == work_package ? "from" : "to"
      target_relation_type = target == "from" ? relation3.reverse_type : relation3.relation_type

      relation_row = relations_panel.find("[data-test-selector='op-relation-row-#{relation3.id}']")

      within(relations_panel) do
        # We reference the relation type as the "from" node of the relation
        # is not the currently visited work package. From the current user's
        # perspective on the work package's page, this is the "forward" relation.
        expect(page).to have_text(label_for_relation_type(target_relation_type))
      end

      within(relation_row) do
        expect(page).to have_text(relation3.to.type.name.upcase)
        expect(page).to have_text(relation3.to.id)
        expect(page).to have_text(relation3.to.status.name)
        expect(page).to have_text(relation3.to.subject)
      end
    end
  end

  describe "deletion" do
    it "can delete relations" do
      scroll_to_element relations_panel

      # Find the first relation and delete it
      relation_row = relations_panel.find("[data-test-selector='op-relation-row-#{relation1.id}']")

      within(relation_row) do
        page.find("[data-test-selector='op-relation-row-#{relation1.id}-action-menu']").click
        page.find("[data-test-selector='op-relation-row-#{relation1.id}-delete-button']").click
      end

      wait_for_reload

      # Expect the relation to be gone
      within "##{WorkPackageRelationsTab::IndexComponent::FRAME_ID}" do
        expect(page).to have_no_text(relation1.to.subject)
      end

      expect { relation1.reload }.to raise_error(ActiveRecord::RecordNotFound)

      tabs.expect_counter("relations", 3)
    end

    it "can delete children" do
      scroll_to_element relations_panel

      # Find the first relation and delete it
      child_row = relations_panel.find("[data-test-selector='op-relation-row-#{child_wp.id}']")

      within(child_row) do
        page.find("[data-test-selector='op-relation-row-#{child_wp.id}-action-menu']").click
        page.find("[data-test-selector='op-relation-row-#{child_wp.id}-delete-button']").click
      end

      wait_for_reload

      within "##{WorkPackageRelationsTab::IndexComponent::FRAME_ID}" do
        expect(page).to have_no_text(child_wp.subject)
      end

      expect(child_wp.reload.parent).to be_nil

      tabs.expect_counter("relations", 3)
    end
  end

  describe "editing" do
    it "renders an edit form" do
      scroll_to_element relations_panel

      relation_row = relations_panel.find("[data-test-selector='op-relation-row-#{relation1.id}']")

      within(relation_row) do
        page.find("[data-test-selector='op-relation-row-#{relation1.id}-action-menu']").click
        page.find("[data-test-selector='op-relation-row-#{relation1.id}-edit-button']").click
      end

      within "##{WorkPackageRelationsTab::WorkPackageRelationDialogComponent::DIALOG_ID}" do
        wait_for_network_idle
        expect(page).to have_text("Edit successor (after)")
        expect(page).to have_field("Work package", readonly: true)
        expect(page).to have_button("Add description")
        expect(page).to have_field("Description", visible: :hidden)

        click_link_or_button "Add description"

        expect(page).to have_field("Description")

        fill_in "Description", with: "Discovered relations have descriptions!"

        click_link_or_button "Save"
      end

      # Reflects new description
      wait_for_reload
      within(relation_row) do
        expect(page).to have_text("Discovered relations have descriptions!")
      end

      # Unchanged
      tabs.expect_counter("relations", 4)

      # Edit again
      within(relation_row) do
        page.find("[data-test-selector='op-relation-row-#{relation1.id}-action-menu']").click
        page.find("[data-test-selector='op-relation-row-#{relation1.id}-edit-button']").click
      end

      within "##{WorkPackageRelationsTab::WorkPackageRelationDialogComponent::DIALOG_ID}" do
        wait_for_network_idle
        expect(page).to have_text("Edit successor (after)")
        expect(page).to have_field("Work package", readonly: true)
        expect(page).to have_no_button("Add description")
        expect(page).to have_field("Description", visible: :visible, with: "Discovered relations have descriptions!")

        fill_in "Description", with: "And they can be edited!"

        click_link_or_button "Save"
      end

      # Reflects new description
      wait_for_reload
      within(relation_row) do
        expect(page).to have_text("And they can be edited!")
      end

      # Unchanged
      tabs.expect_counter("relations", 4)
    end

    it "does not have an edit action for children" do
      scroll_to_element relations_panel

      child_row = relations_panel.find("[data-test-selector='op-relation-row-#{child_wp.id}']")

      within(child_row) do
        page.find("[data-test-selector='op-relation-row-#{child_wp.id}-action-menu']").click
        expect(page).to have_no_css("[data-test-selector='op-relation-row-#{child_wp.id}-edit-button']")
      end
    end
  end

  describe "creating a relation" do
    it "renders the new relation form for the selected type and creates the relation" do
      scroll_to_element relations_panel

      relations_panel.find("[data-test-selector='new-relation-action-menu']").click

      within page.find_by_id("new-relation-action-menu-list") do # Primer appends "list" to the menu id automatically
        click_link_or_button "Successor (after)"
      end

      wait_for_reload

      within "##{WorkPackageRelationsTab::WorkPackageRelationFormComponent::DIALOG_ID}" do
        expect(page).to have_text("Add successor (after)")
        expect(page).to have_button("Add description")

        autocomplete_field = page.find("[data-test-selector='work-package-relation-form-to-id']")
        select_autocomplete(autocomplete_field,
                            query: to3.subject,
                            results_selector: "body")

        click_link_or_button "Add description"

        fill_in "Description", with: "Discovered relations have descriptions!"

        click_link_or_button "Save"
      end

      wait_for_reload

      within relations_panel do
        new_relation = Relation.last
        expect(new_relation.to).to eq(to3)
        new_relation_row = page.find("[data-test-selector='op-relation-row-#{new_relation.id}']")
        expect(new_relation_row).to have_text(to3.subject)
        expect(new_relation_row).to have_text("Discovered relations have descriptions!")
      end

      # Bumped by one
      tabs.expect_counter("relations", 5)
    end

    it "does not autocomplete unrelatable work packages" do
      # to1 is already related to work_package as relation1
      # in a successor relation, so it should not be autocompleteable anymore
      # under the "Successor (after)" type
      scroll_to_element relations_panel

      relations_panel.find("[data-test-selector='new-relation-action-menu']").click

      within page.find_by_id("new-relation-action-menu-list") do # Primer appends "list" to the menu id automatically
        click_link_or_button "Successor (after)"
      end

      wait_for_reload

      within "##{WorkPackageRelationsTab::WorkPackageRelationFormComponent::DIALOG_ID}" do
        expect(page).to have_text("Add successor (after)")
        expect(page).to have_button("Add description")

        autocomplete_field = page.find("[data-test-selector='work-package-relation-form-to-id']")
        search_autocomplete(autocomplete_field,
                            query: to1.subject,
                            results_selector: "body")
        expect_no_ng_option(autocomplete_field,
                            to1.subject,
                            results_selector: "body")
      end
    end
  end

  describe "attaching a child" do
    it "renders the new child form and creates the child relationship" do
      scroll_to_element relations_panel

      relations_panel.find("[data-test-selector='new-relation-action-menu']").click

      tabs.expect_counter("relations", 4)

      within page.find_by_id("new-relation-action-menu-list") do # Primer appends "list" to the menu id automatically
        click_link_or_button "Child"
      end

      wait_for_reload

      within "##{WorkPackageRelationsTab::AddWorkPackageChildFormComponent::DIALOG_ID}" do
        expect(page).to have_text("Add child")

        autocomplete_field = page.find("[data-test-selector='work-package-child-form-id']")
        select_autocomplete(autocomplete_field,
                            query: not_yet_child_wp.subject,
                            results_selector: "body")

        click_link_or_button "Save"
      end

      wait_for_reload

      within relations_panel do
        not_yet_child_wp.reload
        expect(not_yet_child_wp.parent).to eq(work_package)

        child_row = page.find("[data-test-selector='op-relation-row-#{not_yet_child_wp.id}']")
        expect(child_row).to have_text(not_yet_child_wp.subject)
      end

      # Bumped by one
      tabs.expect_counter("relations", 5)
    end
  end
end
