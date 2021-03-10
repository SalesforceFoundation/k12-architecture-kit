# K-12 Architecture Kit

K-12 Architecture Kit from Salesforce.org provides an education-specific platform for K-12 educational institutions building a CRM. K-12 Architecture Kit adds unmanaged metadata to Salesforce's Education Data Architecture (EDA) managed package to give K-12 educational institution users a familiar nomenclature and data model for common education applications. Also, education developers and administrators can use EDA's advanced trigger management capabilities, robust error handling, and extensible framework to better manage and coordinate their data in Salesforce.

K-12 Architecture Kit is built upon industry-wide best practices from across educational institutions and the Salesforce ecosystem. We welcome your feedback and contributions to K-12 Architecture Kit.

## Get K-12 Architecture Kit

The easiest way to get started with K-12 Architecture Kit is to sign up for a <a href="https://www.salesforce.org/trial/k12/" target="_blank">trial</a>. If you need to install K-12 Architecture Kit in an existing org, use the <a href="https://install.salesforce.org/products/k12" target="_blank">K-12 Architecture Kit installer</a>. See <a href="https://powerofus.force.com/s/article/K12-Install-K12" target="_blank">Install K-12 Architecture Kit</a> for more information.

## Contribute to K-12 Architecture Kit

Use a code formatter, like Prettier, to ensure that code you contribute to EDA is formatted consistent with the EDA code base. 

### Install a package manager

Make sure `yarn` is installed on your local machine. For more information, check <a href="https://classic.yarnpkg.com/en/docs/install/#mac-stableA" target="_blank">yarn installation</a>.

### Install dependency packages

Use a CLI to install dependency packages in your local repo:

```
yarn install
```

If you’re using Prettier, these dependency packages will be installed to your local repo: prettier, prettier-plugin-apex, husky, and lint-staged.

### Configure your code formatter

Configure your code formatter, as needed. For example, customize Prettier configurations in `prettierrc.yml` or specify code for Prettier to ignore in `.prettierignore`.

### Bypass pre-commit hook

Pre-commit hooks help ensure the quality of code, but if you need to bypass them, append `--no-verify` to git commit or use a similar commit option for your GUI clients.

### Troubleshoot errors

If you encounter errors, remove the node_modules folder and run `yarn install` again.

## Learn More

* <a href="https://powerofus.force.com/" target="_blank">Ask questions or get help</a>
* <a href="https://powerofus.force.com/hub-ideas" target="_blank">Feature Request</a>
* <a href="https://powerofus.force.com/s/article/K12-Documentation" target="_blank">User Documentation</a>
* Check out existing <a href="https://github.com/SalesforceFoundation/k12-architecture-kit/labels/bug" target="_blank">bugs</a> and <a href="https://trailblazers.salesforce.com/search?keywords=k-12" target="_blank">feature and enhancement requests</a>
* <a href="https://github.com/SalesforceFoundation/k12-architecture-kit/releases" target="_blank">Release Notes and Beta Releases</a>

## Meta

K-12 Architecture Kit is an application that runs on the Education Data Architecture technology (“EDA”). In order to get started with K-12 Architecture Kit, you must have installed EDA. If you do not currently have EDA, the installer will automatically install EDA into your org with K-12 Architecture Kit. Both K-12 Architecture Kit and EDA are open-source solutions licensed by Salesforce.org (http://salesforce.org/) (“SFDO”) under the BSD-3 Clause License, found at https://opensource.org/licenses/BSD-3-Clause. ANY MASTER SUBSCRIPTION AGREEMENT YOU OR YOUR ENTITY MAY HAVE WITH SFDO DOES NOT APPLY TO YOUR USE OF K-12 Architecture Kit OR EDA. BOTH K-12 Architecture Kit AND EDA ARE PROVIDED “AS IS” AND AS AVAILABLE, AND SFDO MAKES NO WARRANTY OF ANY KIND REGARDING K-12 Architecture Kit OR EDA, WHETHER EXPRESS, IMPLIED, STATUTORY OR OTHERWISE, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM DEFECTS OR NON-INFRINGEMENT, TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW.
SFDO WILL HAVE NO LIABILITY ARISING OUT OF OR RELATED TO YOUR USE OF K-12 Architecture Kit OR EDA FOR ANY DIRECT DAMAGES OR FOR ANY LOST PROFITS, REVENUES, GOODWILL OR INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, EXEMPLARY, COVER, BUSINESS INTERRUPTION OR PUNITIVE DAMAGES, WHETHER AN ACTION IS IN CONTRACT OR TORT AND REGARDLESS OF THE THEORY OF LIABILITY, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES OR IF A REMEDY OTHERWISE FAILS OF ITS ESSENTIAL PURPOSE. THE FOREGOING DISCLAIMER WILL NOT APPLY TO THE EXTENT PROHIBITED BY LAW. SFDO DISCLAIMS ALL LIABILITY AND INDEMNIFICATION OBLIGATIONS FOR ANY HARM OR DAMAGES CAUSED BY ANY THIRD-PARTY HOSTING PROVIDERS.

