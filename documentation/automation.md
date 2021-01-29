# K-12 Automation Inventory

**Table of Contents**

-   [K-12 Automation Inventory](#k-12-automation-inventory)
    -   [Key Workflows](#key-workflows)
    -   [Unpackaged Metadata](#unpackaged-metadata)
    -   [Utility Tasks and Flows](#utility-tasks-and-flows)
        -   [`add_picklist_values`](#addpicklistvalues)
            -   [Basic Usage](#basic-usage)
                -   [Task Documentation](#task-documentation)
            -   [Examples](#examples)
                -   [Basic Example](#basic-example)
                -   [Basic Example With Sorting](#basic-example-with-sorting)
                -   [Basic Example With Other Last](#basic-example-with-other-last)
                -   [Including Record Types](#including-record-types)
                -   [Including Multiple Record Types](#including-multiple-record-types)
                -   [Adding Multiple Values](#adding-multiple-values)
                -   [Sorting Alphabetically, With Other Last](#sorting-alphabetically-with-other-last)
            -   [Limitations](#limitations)
    -   [Trialforce Source Org (TSO) Updates](#trialforce-source-org-tso-updates)
        -   [How is the TSO updated during a release?](#how-is-the-tso-updated-during-a-release)
        -   [How do I access the trial experience?](#how-do-i-access-the-trial-experience)
        -   [What needs to go in `unpackaged/config/trial` versus `unpackaged/{pre,post}`?](#what-needs-to-go-in-unpackagedconfigtrial-versus-unpackagedprepost)

## Key Workflows

| Workflow                     | Flow                 | Org Type         | Managed | Namespace |
| ---------------------------- | -------------------- | ---------------- | ------- | --------- |
| Development                  | `dev_org`            | `dev`            |         |           |
| Development (Namespaced)     | `dev_org_namespaced` | `dev_namespaced` |         | ✔         |
| QA                           | `qa_org`             | `dev`            |         |           |
| Regression                   | `regression_org`     | `release`        | ✔       |           |
| Latest Trial Template        | N/A                  | `trial`          | ✔       |           |
| Update Trialforce Source Org | `trial_org`          | `release`        | ✔       |           |
| Upgraded Org                 | `upgraded_org`       | `release`        | ✔       |           |
| Net New Org                  | `net_new_org`        | `release`        | ✔       |           |

## Unpackaged Metadata

Unpackaged directory structure:

```
unpackaged/config
├── installer
└── trial
```

Each directory is used as follows:

| Directory          | Purpose                      | Deploy task           | Retrieve task |
| ------------------ | ---------------------------- | --------------------- | ------------- |
| `config/installer` | Sets `K12Kit` App as default | `deploy_k12_app`      |               |
| `config/trial`     | Unmanaged TSO configuration  | `deploy_trial_config` |               |

## Utility Tasks and Flows

-   **`regression_org`** Simulates an K12 org upgraded from the latest production release to the current beta and its dependencies (EDA), using the unpackaged metadata from the current beta. Use this when you want an upgraded org without needing to make any manual configurations.

-   **`net_new_org`** Simulates the creation of a new K12 org for a new customer, installing the latest beta of K12 and dependencies (EDA). Use this when you want a fully configured regression environment that matches a new installation.

-   **`upgraded_org`** Simulates a push upgrade of K12 and dependencies (EDA) to existing customer orgs, from the latest production release to the current beta. This means all push-upgradable components have been updated, but only the unpackaged metadata from the previous version will exist in the org (and not the unpackaged metadata from the current beta.) Use this when you want to see which manual configuration steps are required in order for existing customers to use new functionality.

## Trialforce Source Org (TSO) Updates

K-12 is the first SFDO product to maintain its Trialforce Source Org (TSO) using CumulusCI automation. While defining the trial configuration via CCI makes it easier to keep the TSO up to date, it does add some complexity. This section provides some additional context on the process.

### How is the TSO updated during a release?

The basic process during each release:

1. The TSO is updated using the `trial_org` flow, which:
    1. Upgrades to the latest version of the EDA managed package and deploys pre-install (`dependencies`),
    2. Installs the latest version of the K-12 managed package,
    3. Deploys post-install metadata, sets admin permissions, and sets the `hed__Account_Processor__c` (`config_managed`)
    4. Enables course connections, and
    5. Deploys unmanaged trial metadata.
2. A new Trialforce Template ID is generated,
3. The `trial` scratch org definition file is updated with the latest template ID.

### How do I access the trial experience?

You have two options:

1. To see a trial org based on the current release's Trialforce Template ID, use the `trial` scratch org config (e.g. `cci org browser trial`).
2. To see the output of the `trial_org` flow that is run aginst the TSO, use the `trial_org` flow and the `release` scratch org config (e.g. `cci flow run trial_org --org release`).

### What needs to go in `unpackaged/config/trial` versus `unpackaged/{pre,post}`?

The short answer, two kinds of metadata go in `unpackaged/config/trial`:

1. **Managed components that aren't upgradeable.** Example: Adding a picklist value to a `CustomField`. We don't need to include it in pre/post-install config since we're assuming that the newly added value will be included as part of the installation.
2. **Unmanaged components that are trial-only.** Example: A custom report that is intended for the TSO only.

It isn't necessary to include things in both `unpackaged/config/trial` and `unpackaged/{pre,post}` folders, as the latter are run against the TSO at each release.
