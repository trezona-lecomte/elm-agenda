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

      cy.get('div.elm-agenda__schedule-event-label').should('contain', 'My event');
      cy.get('div.elm-agenda__schedule-event-time').should('contain', '8:00 AM - 8:15 AM');
    });

    it('allows deletion with a button', function () {
      cy.contains('Add Event').click();
      cy.get('.input').type('Foo bar event');
      cy.contains('Save').click();

      cy.contains('X').click({force: true});

      cy.get('div.elm-agenda__schedule-event-label').should('not.contain', 'Foo bar event');
    });
  });
});
