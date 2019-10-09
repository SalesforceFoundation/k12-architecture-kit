import json
from cumulusci.tasks.salesforce import BaseSalesforceApiTask

package_xml_template = """
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>{field}</members>
        <name>CustomField</name>
    </types>
    {record_types}
    <version>45.0</version>
</Package>
"""

package_xml_record_types_block_template = """
    <types>
        {record_types}
        <name>RecordType</name>
    </types>
"""

package_xml_record_type_template = """
        <members>{object}.{record_type_name}</members>
"""

object_template = """
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fields>
        <fullName>{field}</fullName>
        <!--<description></description>
        <externalId>false</externalId>
        <inlineHelpText></inlineHelpText>
        <label></label>
        <required>false</required>
        <trackFeedHistory>false</trackFeedHistory>
        <type>Picklist</type>-->
        <valueSet>
            <restricted>{restricted}</restricted>
            <valueSetDefinition>
                <sorted>{sorted}</sorted>
                {picklist_value}
            </valueSetDefinition>
        </valueSet>
    </fields>
    {record_types}
</CustomObject>
"""

picklist_value_template = """
                <value>
                    <fullName>{name}</fullName>
                    <default>{default}</default>
                    <label>{name}</label>
                </value>
"""

record_type_picklist_template = """
    <recordTypes>
        <fullName>{fullName}</fullName>
        <active>true</active>
        <label>{label}</label>
        <picklistValues>
            <picklist>{field}</picklist>
            {picklist_value}
        </picklistValues>
    </recordTypes>
"""

record_type_picklist_value_template = """
            <values>
                <fullName>{name}</fullName>
                <default>{default}</default>
            </values>
"""

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
        values = self.options["values"].split(',')

        active_picklist_values = []
        describe_results = getattr(self.sf, sobject).describe()
        
        validated_field = None
        for f in describe_results["fields"]:
            if f["name"] == field:
                validated_field = f["name"]
                field_describe = f
                break

        if validated_field != field:
            raise Exception('{} field not found on {}'.format(field, sobject))

        # build up a list of active record types
        picklist_record_types = self._get_active_record_types(describe_results)
        print('Record types for the picklist: {}'.format(picklist_record_types)) # temporary

        if field_describe["type"] == "picklist":
            active_picklist_values = [
                picklist for picklist in field_describe["picklistValues"] if picklist["active"] is True
            ]
        else:
            raise Exception('{} field is not a picklist field'.format(field))

        # remove any existing picklist values from the list of picklist values to add
        for active_picklist_value in active_picklist_values:
            if active_picklist_value["value"] in values:
                print('{} is already a picklist value on {}. Skipping...'.format(active_picklist_value["value"], field))
                values.remove(active_picklist_value["value"])

        print('Validated new picklist values: {}'.format(values))

        # to-do: build XML...
        # build package.xml:
        package_xml = ""

        if picklist_record_types:
            package_xml_record_types = ""
            for rt in picklist_record_types:
                package_xml_record_types += package_xml_record_type_template.format(object = sobject, record_type_name = rt["developerName"])
            
            package_xml_record_types_block = package_xml_record_types_block_template.format(record_types = package_xml_record_types)
            print(package_xml_record_types_block) # temporary
            # to-do: append to package.xml

        # build object xml:
        # using record types?

        if "alphabetical" in self.options:
            print("Not yet implemented")

            if self.options["alphabetical"] == "True":
                print("Set the picklist values to alphabetical")
                # to-do: set alphabetical (sorted = true in the XML)

    def _get_active_record_types(self, describe_results):
        picklist_record_types = []
        picklist_record_type_names = []
        if "recordtypes" in self.options:
            record_types = self.options["recordtypes"].split(',')

            active_record_types = [
                rt for rt in describe_results["recordTypeInfos"] if not rt["master"] and rt["active"] is True
            ]

            # validate record_types against active_record_types
            for active_record_type in active_record_types:
                if active_record_type["name"] in record_types:
                    picklist_record_types.append(active_record_type)
                    picklist_record_type_names.append(active_record_type["name"])

            for rt in record_types:
                if rt not in picklist_record_type_names:
                    print('{} is not an active record type for the {} object.'.format(rt, describe_results["name"]))

        return picklist_record_types