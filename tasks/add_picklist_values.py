import json
from cumulusci.tasks.salesforce import BaseSalesforceApiTask

# Adds picklist values to the given field, if they don't already exist.
# Optionally adds the picklist values for the specified record types, if the record types exist.
# Optionally updates the picklist values to be alphabetical.
class AddPicklistValues(BaseSalesforceApiTask):
    task_options = {
        "sobject": {
            "description": "SObject of the picklist being modified",
            "required": True,
        },
        "field": {
            "description": "The picklist being modified",
            "required": True,
        },
        "values": {
            "description": "A comma-delimited list of the picklist values being added",
            "required": True,
        },
        "recordtypes": {
            "description": "The record types that these new picklist values will be available for",
            "required": False,
        },
        "alphabetical": {
            "description": "If true, set the entire picklist to be alphabetical order",
            "required": False,
        }
    }

    def _run_task(self):
        sobject = self.options["sobject"]
        field = self.options["field"]
        values = self.options["values"]

        describe_results = getattr(self.sf, sobject).describe()
        
        active_record_types = None
        record_types = None
        # build up a list of active record types
        if "recordtypes" in self.options:
            active_record_types = [
                rt for rt in describe_results["recordTypeInfos"] if not rt["master"] and rt["active"] is True
            ]
        
            for rt in active_record_types:
                print(rt["name"]) # temporary
                print(rt["active"]) # temporary

            record_types = self.options["recordtypes"].split(',')
            # to-do: validate record_types against active_record_types
            print(record_types) # temporary

        validated_field = None
        for f in describe_results["fields"]:
            if f["name"] == field:
                validated_field = f["name"]
                field_describe = f
                break

        if validated_field != field:
            raise Exception('{} field not found on {}'.format(field, sobject))

        print(field_describe) # temporary
        print(field_describe["name"]) # temporary

        if field_describe["type"] == "picklist":
            for picklist in field_describe["picklistValues"]:
                print(picklist["label"]) # temporary
                print(picklist["active"]) # temporary
        else:
            raise Exception('{} field is not a picklist field'.format(field))

        # to-do: build list of existing & new picklist values (removing duplicates), then deploy
        
        # to-do: set record type picklist values assignment if record_types is not None

        if "alphabetical" in self.options:
            print("Not yet implemented")
            # to-do: set alphabetical
        
        return