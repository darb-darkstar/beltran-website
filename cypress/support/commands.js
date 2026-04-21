Cypress.Commands.add('visitWithHeader', (url) => {
  cy.visit(url, {
    headers: {
      'x-ci-test': 'true'
    }
  });
});