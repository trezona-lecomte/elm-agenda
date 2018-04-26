describe('Event Management', function() {
  before(function () {
    cy.visit('/');
  });

  context('when in daily mode', function () {
    it('allows creation with a button', function () {
      cy.contains('Add Event').click();
      cy.get('.input').type('Foo bar baz');
      cy.contains('Cancel').click();

      cy.contains('Add Event').click();
      cy.get('.input').type('My event');
      cy.contains('Save').click();

      cy.get('div.elm-agenda__schedule-event-summary').should('contain', 'My event');
    });

    it('allows creation by dragging', function () {
      cy.get('#quarter-3').trigger('mousedown', { force: true });
      cy.get('#quarter-4').trigger('mouseup', { force: true });

      cy.get('div.elm-agenda__schedule-event-summary').should('contain', 'Untitled');
      cy.get('div.elm-agenda__schedule-event-time').should('contain', '1:00 AM - 1:15 AM');
    });

    it('allows deletion with a button', function () {
      cy.contains('Add Event').click();
      cy.get('.input').type('Foo bar event');
      cy.contains('Save').click();

      // TODO: Probably need to start using data-* attributes...
      cy.get('.elm-agenda__schedule-event-remove-link').first().click({ force: true});

      cy.get('div.elm-agenda__schedule-event-summary').should('not.contain', 'Foo bar event');
    });
  });
});
