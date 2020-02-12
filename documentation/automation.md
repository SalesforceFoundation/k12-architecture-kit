# K-12 Automation Inventory

**Table of Contents**

- [K-12 Automation Inventory](#k-12-automation-inventory)
    - [Key Workflows](#key-workflows)
    - [Unpackaged Metadata](#unpackaged-metadata)
    - [Utility Tasks and Flows](#utility-tasks-and-flows)
        - [`add_picklist_values`](#addpicklistvalues)
            - [Basic Usage](#basic-usage)
                - [Task Documentation](#task-documentation)
            - [Examples](#examples)
                - [Basic Example](#basic-example)
                - [Basic Example With Sorting](#basic-example-with-sorting)
                - [Basic Example With Other Last](#basic-example-with-other-last)
                - [Including Record Types](#including-record-types)
                - [Including Multiple Record Types](#including-multiple-record-types)
                - [Adding Multiple Values](#adding-multiple-values)
                - [Sorting Alphabetically, With Other Last](#sorting-alphabetically-with-other-last)
            - [Limitations](#limitations)
    - [Trialforce Source Org (TSO) Updates](#trialforce-source-org-tso-updates)
        - [How is the TSO updated during a release?](#how-is-the-tso-updated-during-a-release)
        - [How do I access the trial experience?](#how-do-i-access-the-trial-experience)
        - [What needs to go in `unpackaged/config/trial` versus `unpackaged/{pre,post}`?](#what-needs-to-go-in-unpackagedconfigtrial-versus-unpackagedprepost)

## Key Workflows

| Workflow                     | Flow                 | Org Type         | Managed | Namespace |
|------------------------------|----------------------|------------------|---------|-----------|
| Development                  | `dev_org`            | `dev`            |         |           |
| Development (Namespaced)     | `dev_org_namespaced` | `dev_namespaced` |         | ✔         |
| QA                           | `qa_org`             | `dev`            |         |           |
| Regression                   | `regression_org`     | `release`        | ✔       |           |
| Latest Trial Template        | N/A                  | `trial`          | ✔       |           |
| Update Trialforce Source Org | `trial_org`          | `release`        | ✔       |           |
| Upgraded Org                 | `upgraded_org`       | `dev`            |         |           |
## Unpackaged Metadata

Unpackaged directory structure:

```
unpackaged/config
├── installer
└── trial
```

Each directory is used as follows:

| Directory          | Purpose                      | Deploy task           | Retrieve task |
|--------------------|------------------------------|-----------------------|---------------|
| `config/installer` | Sets `K12Kit` App as default | `deploy_k12_app`      |               |
| `config/trial`     | Unmanaged TSO configuration  | `deploy_trial_config` |               |

## Utility Tasks and Flows

-   **`upgraded_org`** Simulates an org that has been push-upgraded to the latest releases of k12 and underlying dependencies.

### `upgraded_org`

We’ve implemented a custom task in the K-12 Architecture Kit to simulate a push upgrade to existing orgs. 

### `add_picklist_values`

We’ve implemented a custom task in the K-12 Architecture Kit for adding new picklist values to an existing field. This use case is generic enough that this custom task may eventually move into core CumulusCI, but for now it resides in the K-12 repository.

#### Basic Usage

Given an object with an existing picklist field, you can add one or several new picklist options to the field. They will be added to the end of the picklist, unless the picklist to be sorted alphabetically or we pass in the option to leave “Other” at the end.

Additionally, the new picklist options can be added to specific record types, if record types exist on the target object.

If the customer already has a picklist option with the same name on the picklist field, the task will skip adding the picklist option since it’s already there — otherwise, not skipping the picklist option would throw an error on deployment.

**Validation:** If the object or field doesn’t exist, or the field exists but isn’t a picklist field, an error is thrown when running the task. Additionally, any record types that are specified that don’t exist or are not marked as active in the org are skipped.
* * *

##### Task Documentation

Task name: `add_picklist_values`
Options:

* `sobject` (required) - SObject of the picklist field being modified.
* `field` (required) - The picklist field being modified.
* `values` (required) - A comma-delimited list of the picklist values being added.
* `recordtypes` (optional) - The record types for which these new picklist values will be available.
* `sorted` (optional) - If true, sets the entire picklist to be sorted in alphabetical order. Defaults to the current definition of the picklist in the org.
* `otherlast` (optional) - If true, the Other value (if it exists) will remain at the end of the values. Default is false.

```
cci task run add_picklist_values --org ORG 
    -o sobject SOBJECT
    -o field FIELD
    -o values VALUES
    -o recordtypes RECORD_TYPES
    -o sorted True/False
    -o otherlast True/False
```

Validation: `sorted` and `otherlast` cannot both be true in the same task execution, otherwise an error is thrown.

#### Examples

##### Basic Example

This adds the “Has Single Parent” picklist option to the end of the Attribute Type picklist on the Attribute object in EDA.

```
cci task run add_picklist_values --org dev
    -o sobject hed__Attribute__c
    -o field hed__Attribute_Type__c
    -o values "Has Single Parent"
```

##### Basic Example With Sorting

This adds the “Has Single Parent” picklist option to the Attribute Type picklist on the Attribute object in EDA. When the user uses the dropdown in the UI, all of the values will appear alphabetically.

```
cci task run add_picklist_values --org dev
    -o sobject hed__Attribute__c
    -o field hed__Attribute_Type__c
    -o values "Has Single Parent"
    -o sorted True
```

##### Basic Example With Other Last

This adds the “Has Single Parent” picklist option to the end of the Attribute Type picklist on the Attribute object in EDA. If the Other option exists on the picklist field (which it does for Attribute Type unless the customer has removed it), Other will remain or be moved to the bottom of the picklist.

```
cci task run add_picklist_values --org dev
    -o sobject hed__Attribute__c
    -o field hed__Attribute_Type__c
    -o values "Has Single Parent"
    -o otherlast True
```

##### Including Record Types

This adds the “Has Single Parent” picklist option to the end of the Attribute Type picklist on the Attribute object in EDA. It is also made available to the Student Characteristic record type.

```
cci task run add_picklist_values --org dev
    -o sobject hed__Attribute__c
    -o field hed__Attribute_Type__c
    -o values "Has Single Parent"
    -o recordtypes hed__Student_Characteristic
```

##### Including Multiple Record Types

This adds the “Other” picklist option to the end of the Attribute Type picklist on the Attribute object in EDA. It is also made available to both the Student Characteristic and Credential record type.

```
cci task run add_picklist_values --org dev
    -o sobject hed__Attribute__c
    -o field hed__Attribute_Type__c
    -o values "Other"
    -o recordtypes hed__Student_Characteristic,hed__Credential
```

##### Adding Multiple Values

This adds the “2020”, “2021”, and “2022” picklist options to the end of the Year picklist on the custom Grants object.

```
cci task run add_picklist_values --org dev
    -o sobject Grants__c
    -o field Year__c
    -o values "2020,2021,2022"
```

##### Sorting Alphabetically, With Other Last

This is an interesting use case! This requires the task to be run twice.

First, this adds the “Has Single Parent” picklist option to the Attribute Type picklist on the Attribute object in EDA. When the user uses the dropdown in the UI, all of the values will appear alphabetically.

Running the task a second time *without* the `sorted` option specified and with the `otherlast` option specified will move the existing Other option to the bottom of the picklist. The “Has Single Parent” picklist option will not be added again since it was added during the first execution of the task.

```
cci task run add_picklist_values --org dev
    -o sobject hed__Attribute__c
    -o field hed__Attribute_Type__c
    -o values "Has Single Parent"
    -o sorted True
    
cci task run add_picklist_values --org dev
    -o sobject hed__Attribute__c
    -o field hed__Attribute_Type__c
    -o values "Has Single Parent"
    -o otherlast True
```

#### Limitations

A few limitations exist in the current implementation of the task:

* Multi-select picklist fields are not yet supported.
* Picklist fields that use a Global Value Set are not yet supported.
* Standard fields are not yet supported, such as the Status field on the Case object.
* There is no way to specify any of the new values as the default picklist value, or as the default value for a particular record type.
    * If a default picklist value is already defined on the field, it will remain as the default.
* There is no way to specify a specific order for the existing or new values, except:
    * Sorting the entire picklist alphabetically
    * Adding the new values to the end (above the Other value, if applicable)

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
