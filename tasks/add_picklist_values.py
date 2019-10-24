import os
import json
import shutil
import tempfile

from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.tasks.salesforce import Deploy

package_xml_template = """<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>{object}.{field}</members>
        <name>CustomField</name>
    </types>{record_types_block}
    <version>45.0</version>
</Package>"""

package_xml_record_types_block_template = """
    <types>{record_types}
        <name>RecordType</name>
    </types>"""

package_xml_record_type_template = """
        <members>{object}.{record_type_name}</members>"""

object_template = """<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fields>
        <fullName>{field}</fullName>
        <description>The type of credential or Attribute.</description><!-- to-do: update this -->
        <inlineHelpText>The type of credential or Attribute.</inlineHelpText><!-- to-do: update this -->
        <label>Attribute Type</label><!-- to-do: update this -->
        <type>Picklist</type>
        <valueSet>
            <valueSetDefinition>
                <sorted>{sorted}</sorted>{picklist_values}
            </valueSetDefinition>
        </valueSet>
    </fields>{record_types}
</CustomObject>"""

picklist_value_template = """
                <value>
                    <fullName>{name}</fullName>
                    <default>{default}</default>
                    <label>{label}</label>
                </value>"""

record_type_picklist_template = """
    <recordTypes>
        <fullName>{name}</fullName>
        <active>true</active>
        <label>{label}</label>
        <picklistValues>
            <picklist>{field}</picklist>{picklist_values}
        </picklistValues>
    </recordTypes>"""

record_type_picklist_value_template = """
            <values>
                <fullName>{name}</fullName>
                <default>{default}</default>
            </values>"""

# Adds picklist values to the given field, if they don't already exist.
# Optionally adds the picklist values for the specified record types, if the record types exist.
# Optionally updates the picklist values to be alphabetical.
class AddPicklistValues(BaseSalesforceApiTask, Deploy):
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
        # to-do: issue when the record type has a namespace... duplicate is created without a namespace
        picklist_record_types = self._get_active_record_types(describe_results)

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

        # build the package.xml:
        package_xml = self._build_package_xml(picklist_record_types, sobject, field)
        print(package_xml) # temporary

        # build the object XML:
        object_xml = self._build_object_xml(picklist_record_types, active_picklist_values, values, field)
        print(object_xml) # temporary

        # deploy back to Salesforce
        self.tempdir = tempfile.mkdtemp()
        package_xml_file = os.path.join(self.tempdir, "package.xml")
        with open(package_xml_file, "w") as f:
            f.write(package_xml)

        print(self.tempdir) # temporary
        print(package_xml_file) # temporary

        object_folder = os.mkdir("{}/{}".format(self.tempdir, "objects"))
        object_xml_file = os.path.join(self.tempdir, "objects", "{}.object".format(sobject))
        with open(object_xml_file, "w") as f:
            f.write(object_xml)

        print(object_xml_file) # temporary
        
        self._deploy_metadata()
        shutil.rmtree(self.tempdir)

    def _get_active_record_types(self, describe_results):
        picklist_record_types = []
        picklist_record_type_names = []
        if "recordtypes" in self.options:
            record_types = self.options["recordtypes"].split(',')

            active_record_types = [
                rt for rt in describe_results["recordTypeInfos"] if not rt["master"] and rt["active"] is True
            ]

            print(active_record_types)

            # validate record_types against active_record_types
            for active_record_type in active_record_types:
                if active_record_type["developerName"] in record_types:
                    picklist_record_types.append(active_record_type)
                    picklist_record_type_names.append(active_record_type["developerName"])
                    # to-do: The describe doesn't include the namespace, which is necessary otherwise duplicate record types are created. WHY???

            for rt in record_types:
                if rt not in picklist_record_type_names:
                    # Choosing to not throw an exception here since a customer might have deactivated or deleted a record type.
                    print('{} is not an active record type for the {} object.'.format(rt, describe_results["name"]))

        return picklist_record_types

    def _build_package_xml(self, picklist_record_types, sobject, field):
        # include the record types, if any were specified
        package_xml_record_types_block = ""
        if picklist_record_types:
            package_xml_record_types = ""
            for rt in picklist_record_types:
                package_xml_record_types += package_xml_record_type_template.format(
                    object = sobject, 
                    record_type_name = rt["developerName"]
                )
            
            package_xml_record_types_block = package_xml_record_types_block_template.format(record_types = package_xml_record_types)

        # combine it all together
        package_xml = package_xml_template.format(
            object = sobject, 
            field = field, 
            record_types_block = package_xml_record_types_block
        )

        return package_xml

    def _build_object_xml(self, picklist_record_types, active_picklist_values, values, field):
        # to-do: "Other" should always be at the bottom? (if it's already there)

        picklist_values_xml = ""
        record_type_picklist_xml = ""
        record_type_picklist_values_xml = ""

        # add the existing picklist values
        for active_picklist_value in active_picklist_values:
            picklist_values_xml += picklist_value_template.format(
                name = active_picklist_value["value"], 
                default = active_picklist_value["defaultValue"], 
                label = active_picklist_value["label"]
            )

            if picklist_record_types:
                record_type_picklist_values_xml += record_type_picklist_value_template.format(
                    # to-do: Not all picklist values should be available for the record type... it will be dependent on how its configured in the org.
                    name = active_picklist_value["value"], 
                    default = active_picklist_value["defaultValue"] # to-do: I don't think this is right. Can we look at the record type XML describe?
                )
        
        # add the new picklist values
        for value in values:
            picklist_values_xml += picklist_value_template.format(
                name = value, 
                default = False, 
                label = value
            )

            if picklist_record_types:
                record_type_picklist_values_xml += record_type_picklist_value_template.format(
                    name = value,
                    default = False
                )

        # add the picklist values to the record types, if any were specified
        if picklist_record_types:
            for rt in picklist_record_types:
                record_type_picklist_xml += record_type_picklist_template.format(
                    name = rt["developerName"], 
                    label = rt["name"], 
                    field = field,
                    picklist_values = record_type_picklist_values_xml
                )

        sorted_picklist = False
        if "alphabetical" in self.options:
            if self.options["alphabetical"] == "True":
                sorted_picklist = True

        # combine it all together
        object_xml = object_template.format(
            field = field,
            sorted = sorted_picklist,
            picklist_values = picklist_values_xml,
            record_types = record_type_picklist_xml
        )

        return object_xml

    def _deploy_metadata(self):
        self.logger.info("Deploying updated picklist values...")
        api = self._get_api(path=self.tempdir)
        return api()