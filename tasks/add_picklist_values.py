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
        <members>{record_type_full_name}</members>"""

object_template = """<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fields>
        <fullName>{field}</fullName>
        <description>{description}</description>
        <inlineHelpText>{helpText}</inlineHelpText>
        <label>{label}</label>
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
        <description>{description}</description>
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
        "sorted": {
            "description": "If true, set the entire picklist to be sorted in alphabetical order",
            "required": False,
        }
    }

    def _run_task(self):
        sobject = self.options["sobject"]
        field = self.options["field"]
        values = self.options["values"].split(',')

        # The Tooling API does not have the namespace or the '__c' suffix in the DeveloperName of the CustomField object,
        # so we have to remove it.
        split_field = field.split('__')
        if len(split_field) is 3:
            field_developer_name = split_field[1]
            namespace = split_field[0]
        else:
            field_developer_name = split_field[0]
            namespace = ""

        field_tooling_results = self.tooling.query(
            "SELECT Id, DeveloperName, Metadata "
            "FROM CustomField "
            "WHERE NamespacePrefix = '{namespace}' "
            "AND DeveloperName = '{developer_name}' ".format(namespace = namespace, developer_name = field_developer_name)
        )

        if field_tooling_results["size"] is not 1:
            raise Exception('{} field not found on {}'.format(field, sobject))

        validated_field = field_tooling_results["records"][0]["Metadata"]
        existing_picklist_values = []

        # build up a list of active record types
        picklist_record_types = self._get_active_record_types(sobject)

        if validated_field["type"] == "Picklist":
            existing_picklist_values = validated_field["valueSet"]["valueSetDefinition"]["value"]
        else:
            raise Exception('{} field is not a picklist field'.format(field))

        # remove any existing picklist values from the list of picklist values to add
        for existing_picklist_value in existing_picklist_values:
            if existing_picklist_value["label"] in values:
                print('{} is already a picklist value on {}. Skipping...'.format(existing_picklist_value["label"], field))
                values.remove(existing_picklist_value["label"])

        # build the package.xml:
        package_xml = self._build_package_xml(picklist_record_types, sobject, field)
        print(package_xml) # temporary

        # build the object XML:
        object_xml = self._build_object_xml(validated_field, picklist_record_types, existing_picklist_values, values, field)
        print(object_xml) # temporary

        # create temporary files & deploy back to Salesforce
        self.tempdir = tempfile.mkdtemp()
        package_xml_file = os.path.join(self.tempdir, "package.xml")
        with open(package_xml_file, "w") as f:
            f.write(package_xml)

        print(self.tempdir) # temporary
        print(package_xml_file) # temporary

        os.mkdir("{}/{}".format(self.tempdir, "objects"))
        object_xml_file = os.path.join(self.tempdir, "objects", "{}.object".format(sobject))
        with open(object_xml_file, "w") as f:
            f.write(object_xml)

        print(object_xml_file) # temporary
        
        self._deploy_metadata()
        shutil.rmtree(self.tempdir)

    def _get_active_record_types(self, sobject):
        picklist_record_types = []
        picklist_record_type_names = []
        if "recordtypes" in self.options:
            record_type_tooling_results = self.tooling.query(
                "SELECT Id, FullName, Metadata, Name "
                "FROM RecordType "
                "WHERE SobjectType = '{sobject}' "
                "AND IsActive = True ".format(sobject = sobject)
            )

            record_types = self.options["recordtypes"].split(',')
            active_record_types = [
                rt for rt in record_type_tooling_results["records"] if rt["Metadata"]["active"] is True
            ]

            # validate record_types against active_record_types
            for active_record_type in active_record_types:
                record_type_name = active_record_type["FullName"].split('.')[1] # removes the SObject from FullName
                if record_type_name in record_types:
                    picklist_record_types.append(active_record_type)
                    picklist_record_type_names.append(record_type_name)

            for rt in record_types:
                if rt not in picklist_record_type_names:
                    # Choosing to not throw an exception here since a customer might have deactivated or deleted a record type.
                    print('{} is not an active record type for the {} object.'.format(rt, sobject))

        return picklist_record_types

    def _build_package_xml(self, picklist_record_types, sobject, field):
        # include the record types, if any were specified
        package_xml_record_types_block = ""
        if picklist_record_types:
            package_xml_record_types = ""
            for rt in picklist_record_types:
                package_xml_record_types += package_xml_record_type_template.format(
                    record_type_full_name = rt["FullName"]
                )
            
            package_xml_record_types_block = package_xml_record_types_block_template.format(record_types = package_xml_record_types)

        # combine it all together
        package_xml = package_xml_template.format(
            object = sobject, 
            field = field, 
            record_types_block = package_xml_record_types_block
        )

        return package_xml

    def _build_object_xml(self, validated_field, picklist_record_types, existing_picklist_values, values, field):
        # to-do: "Other" should always be at the bottom? (if it's already there)

        picklist_values_xml = ""
        record_type_picklist_xml = ""

        # add the existing picklist values
        for existing_picklist_value in existing_picklist_values:
            picklist_values_xml += picklist_value_template.format(
                name = existing_picklist_value["valueName"], 
                default = existing_picklist_value["default"], 
                label = existing_picklist_value["label"]
            )
        
        # add the new picklist values
        for value in values:
            picklist_values_xml += picklist_value_template.format(
                name = value, 
                default = False, 
                label = value
            )

        # add the picklist values to the record types, if any were specified
        if picklist_record_types:
            for rt in picklist_record_types:
                record_type_picklist_values_xml = ""

                # add back the existing picklist values assigned to the record type
                for picklist in rt["Metadata"]["picklistValues"]:
                    if picklist["picklist"] == field:
                        for picklist_value in picklist["values"]:
                            record_type_picklist_values_xml += record_type_picklist_value_template.format(
                                name = picklist_value["valueName"],
                                default = picklist_value["default"]
                            )

                # assign the new picklist values to the record type
                for value in values:
                    record_type_picklist_values_xml += record_type_picklist_value_template.format(
                        name = value,
                        default = False
                    )

                record_type_picklist_xml += record_type_picklist_template.format(
                    name = rt["FullName"].split('.')[1], # removes the SObject from FullName
                    description = rt["Metadata"]["description"],
                    label = rt["Name"], 
                    field = field,
                    picklist_values = record_type_picklist_values_xml
                )

        sorted_picklist = validated_field["valueSet"]["valueSetDefinition"]["sorted"]
        if "sorted" in self.options:
            if self.options["sorted"] == "True":
                sorted_picklist = True

        # combine it all together
        object_xml = object_template.format(
            field = field,
            description = validated_field["description"],
            helpText = validated_field["inlineHelpText"],
            label = validated_field["label"],
            sorted = sorted_picklist,
            picklist_values = picklist_values_xml,
            record_types = record_type_picklist_xml
        )

        return object_xml

    def _deploy_metadata(self):
        self.logger.info("Deploying updated picklist values...")
        api = self._get_api(path=self.tempdir)
        return api()