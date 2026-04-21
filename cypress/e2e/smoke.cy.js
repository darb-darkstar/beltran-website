describe("Smoke Test - S3 Static Website", () => { 
    it("should load the homepage", () => {
        cy.visit('/', {
            headers: {
                'x-ci-test': 'true'
            }
            });

        // Page Rendered
        cy.get('body').should('be.visible');

        // Check for specific content   
        cy.contains("Brad Beltran")
    
        cy.contains("DevOps Engineer");

        cy.contains("Terraform, AWS, and CI/CD automation");

    });

    it('Navigation links are present', () => {
        cy.visit("/", {
            headers: {
                'x-ci-test': 'true'
            }
        });

        cy.contains('Projects'),
        cy.contains('Skills'),
        cy.contains('Contact'),
        cy. contains('Resume');

    });

    it('Project sections are present', () => {
        cy.visit("/#projects", {
            headers: {
                'x-ci-test': 'true'
            }
        });

        cy.contains('AWS Static Website Platform'),
        cy.contains('Terraform Infrastructure Portfolio');
    });

    it('Tech Stack is visible', () => {
        cy.visit("/#skills", {
            headers: {
                'x-ci-test': 'true'
            }
        });

        cy.contains('AWS'),
        cy.contains('Terraform'),
        cy.contains('Docker'),
        cy.contains('Kubewrnetes');
    });

    it('Contact information is visible', () => {
        cy.visit("/#contact", {
            headers: {
                'x-ci-test': 'true'
            }
        });
        cy.contains('bradley.c.beltran@gmail.com'),
        cy.contains('github.com/darbk-darkstar'); 
    });
    
    it('Resume link is functional', () => {
    cy.request({
        url: '/Resume.pdf',
        headers: {
        'x-ci-test': 'true'
        }
    })
    .its('status')
    .should('eq', 200);
    });

    it('No Console errors', () => {
        cy.visit("/", {
            headers: {
                'x-ci-test': 'true'
            }
        });
        
        cy.window().then((win) => {
            cy.stub(win.console, 'error').as('consoleError');
        });

        cy.get('@consoleError').should('not.be.called');
    });
});