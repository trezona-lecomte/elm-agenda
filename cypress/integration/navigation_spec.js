describe('Navigation', function() {
  const today = new Date();
  const yesterday = new Date();
  const tomorrow = new Date();
  yesterday.setDate(today.getDate() - 1);
  tomorrow.setDate(today.getDate() + 1);

  before(function() {
    cy.visit('/');
  });

  context('when in daily mode', function () {
    before(function() {
      cy.contains('Daily').click();
      cy.contains('Daily Schedule');
    });

    it('defaults to today', function () {
      cy.contains(today.toDateString());
    });

    it('paginates in daily intervals', function() {
      cy.contains('>').click();
      cy.contains(tomorrow.toDateString());

      cy.contains('<').click().click();
      cy.contains(yesterday.toDateString());
    });

    it('allows resetting to today', function() {
      cy.contains('Today').click();
      cy.contains(today.toDateString());
    });
  });
});
