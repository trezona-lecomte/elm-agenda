var moment = require('moment');

describe('Navigation', function() {
  const todayDate = new Date();
  const yesterdayDate = new Date();
  const tomorrowDate = new Date();

  yesterdayDate.setDate(todayDate.getDate() - 1);
  tomorrowDate.setDate(todayDate.getDate() + 1);

  const today = moment(todayDate);
  const yesterday = moment(yesterdayDate);
  const tomorrow = moment(tomorrowDate);

  function shortFormat(momentDate) {
    return momentDate.format("ddd MMM D YYYY");
  }

  before(function() {
    cy.visit('/');
  });

  context('when in daily mode', function () {
    before(function() {
      cy.contains('Daily').click();
      cy.contains('Daily Schedule');
    });

    it('defaults to today', function () {
      cy.contains(shortFormat(today));
    });

    context('when using the mouse', function() {
      it('paginates in daily intervals', function() {
        cy.contains('>').click();
        cy.contains(shortFormat(tomorrow));

        cy.contains('<').click().click();
        cy.contains(shortFormat(yesterday));
      });

      it('allows resetting to today', function() {
        cy.contains('Today').click();
        cy.contains(shortFormat(today));
      });
    });

    context('when using the keyboard', function() {
      it('paginates in daily intervals', function() {
        cy.get('body').type('n');
        cy.contains(shortFormat(tomorrow));

        cy.get('body').type('jj');
        cy.contains(shortFormat(yesterday));
      });
    });
  });
});
