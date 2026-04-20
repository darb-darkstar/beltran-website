describe("Smoke Test - S3 Static Website", () => { 
    it("should load the homepage", () => {
        cy.visit("/");
        
        // Page Rendered
        cy.get('body').should('be.visible');

        // Check for specific content   
        cy.contains("Brad Beltran")
    
        
    
    
    
    
    });

    it('No Console errors', () => {
        cy.visit("/");
        cy.window().then((win) => {
            cy.stub(win.console, 'error').as('consoleError');
        });

        cy.get('@consoleError').should('not.be.called');
    });
});