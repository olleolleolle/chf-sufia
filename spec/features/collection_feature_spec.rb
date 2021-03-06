require 'rails_helper'

# Feature tests are really slow always, and even slower cause it's so slow
# for us to create records in samvera. So we pack a bunch of stuff
# into each scenario, even though that's often said to be not great test design.

RSpec.feature "Collections", js: true do
  let(:title) { "test object" }
  let(:subject) { "some subject" }
  let!(:work) { FactoryGirl.create(:work, :with_complete_metadata, title: [title], subject: [subject]) }
  let!(:collection) { FactoryGirl.create(
    :collection, :public, :with_image, members: [work],
    description: ['See also <a href="https://en.wikipedia.org">Wikipedia</a>. <i>italics</i> <b>bold</b> <cite>citation</cite>'])
  }

  scenario "displays collection with item, searches" do

    visit collection_path(collection)

    expect(page).to have_text("1 item")
    expect(page).to have_link(title, href: curation_concerns_generic_work_path(work.id))

    # The description formatter (in app/helpers/description_formatter_helper.rb)
    # adds a 'target' attribute to all links on collections.
    # (See https://github.com/sciencehistory/chf-sufia/pull/1196/)

    expect(page).to have_link('Wikipedia', href: 'https://en.wikipedia.org')
    expect(page.find_link('Wikipedia')[:target]).to eq('_blank')

    expect(page).to have_css("i",    :text => "italics")
    expect(page).to have_css("b",    :text => "bold")
    expect(page).to have_css("cite", :text => "citation")

    # Could not get test of facet search functionality to work reliably on Travis, it was
    # flaky, seemed to be on waiting for the page transition to actually show facet results,
    # not sure what was going on, unable to get it fixed in a day of working on it, better
    # no test than flaky test.

              # # facets there? Can click on them?
              # within("div.facets") do
              #   click_link "Subject"
              #   click_link(subject)
              # end

              # # # still on page, still see result, with facet limit

              # expect(page).to have_current_path(collection_path(collection), only_path: true)
              # # need to make sure we're waiting for actual page reload, with new query param, otherwise
              # # capybara might not be waiting for page reload, leads to test flakiness on travis.
              # # not totally sure why this requires a longer wait time on travis, but it does. Solr caches I guess.
              # # might make more sense to figure out how to trigger solr to cache all facets on suite build.
              # expect(page).to have_current_path(/#{Regexp.quote(CGI.escape subject)}/, wait: 20)
              # expect(page).to have_text("1 item")
              # expect(page).to have_link(title, href: curation_concerns_generic_work_path(work.id))
              # expect(page).to have_css(".constraints-container .constraint-value", text: subject)

    # # do a query search too
    within(".chf-collection-search-form") do
      page.fill_in "q", with: title
      click_on class: "collection-submit"
    end
    expect(page).to have_current_path(collection_path(collection), only_path: true)
    # need to make sure we're waiting for actual page reload, with new query param, otherwise
    # capybara might not be waiting for page reload, leads to test flakiness on travis.
    expect(page).to have_current_path(/#{Regexp.quote(CGI.escape title)}/)
    expect(page).to have_text("1 item")
    expect(page).to have_link(title, href: curation_concerns_generic_work_path(work.id))
    within(".constraints-container") do
      expect(page).to have_field("q", with: title)
    end
    # do NOT keep the facet limit, fresh search on main query box
    expect(page).not_to have_css(".constraints-container .constraint-value", text: subject) # facet limit still there
  end

  scenario "collection list page" do
    visit collections_path
    expect(page).to have_http_status(200)
    expect(page).to have_text(collection.title.first)
  end

end
