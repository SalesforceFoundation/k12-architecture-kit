import os
import json
import shutil
import tempfile

from cumulusci.core.exceptions import TaskOptionsError
from cumulusci.core.utils import process_bool_arg
from cumulusci.core.utils import process_list_arg
from cumulusci.tasks.salesforce import BaseSalesforceApiTask
from cumulusci.tasks.salesforce import Deploy
from xml.sax.saxutils import escape

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
        {description}
        <inlineHelpText>{helpText}</inlineHelpText>
        <label>{label}</label>
        <type>Picklist</type>
        <valueSet>
            <restricted>{restricted}</restricted>
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
        {business_process}
        <active>true</active>
        {description}
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


class AddPicklistValues(BaseSalesforceApiTask, Deploy):
    task_options = {
        "sobject": {
            "description": "SObject of the picklist field being modified",
            "required": True,
        },
        "field": {"description": "The picklist field being modified", "required": True},
        "values": {
            "description": "A comma-delimited list of the picklist values being added",
            "required": True,
        },
        "recordtypes": {
            "description": "The record types for which these new picklist values will be available",
            "required": False,
        },
        "existing_values": {
            "description": "The record types for which these new picklist values will be available",
            "required": False,
        },
        "sorted": {
            "description": "If true, sets the entire picklist to be sorted in alphabetical order",
            "required": False,
        },
        "restricted": {
            "description": "If picklist value is a required field",
            "required": False,
        },
    }

    def _init_options(self, kwargs):
        super()._init_options(kwargs)
        self.options["values"] = process_list_arg(self.options.get("values", []))
        self.options["recordtypes"] = process_list_arg(
            self.options.get("recordtypes", [])
        )
        self.options["restricted"] = process_bool_arg(
            self.options.get("restricted", False)
        )
        self.options["sorted"] = process_bool_arg(self.options.get("sorted", False))

    # Adds picklist values to the given field, if they don't already exist.
    # Optionally adds the picklist values for the specified record types, if the record types exist.
    # Optionally updates the picklist values to be alphabetical.
    def _run_task(self):
        self.api_version = "47.0"
        sobject = self.options["sobject"]
        field = self.options["field"]

        # The Tooling API does not have the namespace or the '__c' suffix in the DeveloperName of the CustomField object
        # or in the DeveloperName of the EntityDefinition object, so we have to remove it.
        split_field = field.split("__")
        if len(split_field) == 3:
            field_developer_name = split_field[1]
            field_namespace_query = "NamespacePrefix = '{}' AND ".format(split_field[0])
        else:
            field_developer_name = split_field[0]
            field_namespace_query = "NamespacePrefix = '' AND "

        split_sobject = sobject.split("__")
        if len(split_sobject) == 3:
            # Namespaced Custom Object
            sobject_developer_name = split_sobject[1]
            sobject_namespace_query = "NamespacePrefix = '{}' AND ".format(
                split_sobject[0]
            )
        else:
            # Standard or Custom Object -- will not be found if NamespacePrefix is left in the query.
            sobject_developer_name = split_sobject[0]
            sobject_namespace_query = ""

        sobject_tooling_results = self.tooling.query(
            "SELECT DeveloperName, DurableId "
            "FROM EntityDefinition "
            "WHERE {namespace_query}"
            "DeveloperName = '{sobject}'".format(
                namespace_query=sobject_namespace_query, sobject=sobject_developer_name
            )
        )

        if sobject_tooling_results["size"] != 1:
            raise Exception(f"{sobject} object not found")

        validated_sobject_id = sobject_tooling_results["records"][0]["DurableId"]

        field_tooling_results = self.tooling.query(
            "SELECT Id, DeveloperName, Metadata "
            "FROM CustomField "
            "WHERE {namespace_query}"
            "DeveloperName = '{developer_name}' "
            "AND TableEnumOrId = '{sobject_id}'".format(
                namespace_query=field_namespace_query,
                developer_name=field_developer_name,
                sobject_id=validated_sobject_id,
            )
        )

        if field_tooling_results["size"] != 1:
            raise Exception(f"{field} field not found on {sobject}")

        validated_field = field_tooling_results["records"][0]["Metadata"]
        existing_picklist_values = []

        # build up a list of active record types
        picklist_record_types = self._get_active_record_types(sobject)

        if validated_field["type"] == "Picklist":
            if validated_field["valueSet"]["valueSetDefinition"] != None:
                existing_picklist_values = validated_field["valueSet"][
                    "valueSetDefinition"
                ]["value"]
            else:
                raise Exception(
                    f"Picklist fields that use Global Value Sets are not currently supported."
                )
        else:
            raise Exception(f"{field} field is not a picklist field")

        # build the package.xml:
        package_xml = self._build_package_xml(picklist_record_types, sobject, field)

        # build the object XML:
        object_xml = self._build_object_xml(
            validated_field, picklist_record_types, existing_picklist_values, field
        )

        # create temporary files & deploy back to Salesforce
        with tempfile.TemporaryDirectory() as self.tempdir:
            package_xml_file = os.path.join(self.tempdir, "package.xml")
            with open(package_xml_file, "w") as f:
                f.write(package_xml)

            os.mkdir("{}/{}".format(self.tempdir, "objects"))
            object_xml_file = os.path.join(
                self.tempdir, "objects", "{}.object".format(sobject)
            )
            with open(object_xml_file, "w") as f:
                f.write(object_xml)

            self._deploy_metadata()

    def _get_active_record_types(self, sobject):
        picklist_record_types = []
        picklist_record_type_names = []
        if len(self.options["recordtypes"]) > 0:
            record_type_tooling_results = self.tooling.query(
                "SELECT Id, FullName, Metadata, Name "
                "FROM RecordType "
                "WHERE SobjectType = '{sobject}' "
                "AND IsActive = True".format(sobject=sobject)
            )

            active_record_types = [
                rt
                for rt in record_type_tooling_results["records"]
                if rt["Metadata"]["active"] is True
            ]

            # validate against active_record_types
            for active_record_type in active_record_types:
                record_type_name = active_record_type["FullName"].split(".")[
                    1
                ]  # removes the SObject from FullName
                if record_type_name in self.options["recordtypes"]:
                    picklist_record_types.append(active_record_type)
                    picklist_record_type_names.append(record_type_name)

            for rt in self.options["recordtypes"]:
                if rt not in picklist_record_type_names:
                    # Choosing to not throw an exception here since a customer might have deactivated or deleted a record type.
                    self.logger.info(
                        f"{rt} is not an active record type for the {sobject} object. Skipping over..."
                    )

        return picklist_record_types

    def _build_package_xml(self, picklist_record_types, sobject, field):
        # include the record types, if any were specified
        package_xml_record_types_block = ""
        if picklist_record_types:
            package_xml_record_types = ""
            for rt in picklist_record_types:
                package_xml_record_types += package_xml_record_type_template.format(
                    record_type_full_name=rt["FullName"]
                )

            package_xml_record_types_block = package_xml_record_types_block_template.format(
                record_types=package_xml_record_types
            )

        # combine it all together
        package_xml = package_xml_template.format(
            object=sobject,
            field=field,
            record_types_block=package_xml_record_types_block,
        )

        return package_xml

    def _build_object_xml(
        self, validated_field, picklist_record_types, existing_picklist_values, field
    ):
        picklist_values_xml = ""
        record_type_picklist_xml = ""
        other_picklist_xml = ""
        values_added = []
        # add the existing picklist values
        for existing_picklist_value in existing_picklist_values:
            values_added.append(existing_picklist_value["label"].lower())
            # if it exists, should "Other" remain at the bottom of the picklist?
            if (
                "existing_values" in self.options
                and existing_picklist_value["label"] in self.options["existing_values"]
            ):
                continue
            if existing_picklist_value["label"] == "Other":
                other_picklist_xml = picklist_value_template.format(
                    name=existing_picklist_value["valueName"],
                    default=existing_picklist_value["default"],
                    label=existing_picklist_value["label"],
                )

            else:
                picklist_values_xml += picklist_value_template.format(
                    name=escape(existing_picklist_value["valueName"]),
                    default=existing_picklist_value["default"],
                    label=escape(existing_picklist_value["label"]),
                )

        # add the new picklist values
        for value in self.options["values"]:
            # ignore any existing picklist values
            # if value.lower() in values_added:
            #     self.logger.info(
            #         f"{value} is already a picklist value on {field}. Skipping over..."
            #     )

            # else:
            picklist_values_xml += picklist_value_template.format(
                name=escape(value), default=False, label=escape(value)
            )

        # add "Other", if it exists
        picklist_values_xml += other_picklist_xml

        # add the picklist values to the record types, if any were specified
        if picklist_record_types:
            for rt in picklist_record_types:
                record_type_picklist_values_xml = ""
                values_added_to_record_type = []
                other_record_type_picklist_values_xml = ""

                # add back the existing picklist values assigned to the record type
                for picklist in rt["Metadata"]["picklistValues"]:
                    
                    if picklist["picklist"] == field:
                        for picklist_value in picklist["values"]:
                            values_added_to_record_type.append(
                                picklist_value["valueName"].lower()
                            )
                            if picklist["values"][0]["valueName"] == "Other": 
                                other_record_type_picklist_values_xml += record_type_picklist_value_template.format(
                                name=escape(picklist_value["valueName"]),
                                default=picklist_value["default"],
                            )
                            else:
                                record_type_picklist_values_xml += record_type_picklist_value_template.format(
                                    name=escape(picklist_value["valueName"]),
                                    default=picklist_value["default"],
                                )
                        break
                            
                # assign the new picklist values to the record type
                for value in self.options["values"]:
                    # ignore any existing picklist values
                    if value.lower() in values_added_to_record_type:
                        continue

                    record_type_picklist_values_xml += record_type_picklist_value_template.format(
                        name=escape(value), default=False
                    )
            
                record_type_picklist_values_xml += other_record_type_picklist_values_xml  
                print(record_type_picklist_values_xml)   
                # only include the description if there's a value -- if it's blank, an error is thrown if the record type is managed
                record_type_description = ""
                if rt["Metadata"]["description"] != None:
                    record_type_description = "<description>{}</description>".format(
                        escape(rt["Metadata"]["description"])
                    )
                if rt["Metadata"]["businessProcess"] != None:
                    record_type_business_process = "<businessProcess>{}</businessProcess>".format(
                        escape(rt["Metadata"]["businessProcess"])
                    )

                record_type_picklist_xml += record_type_picklist_template.format(
                    business_process=record_type_business_process,
                    name=rt["FullName"].split(".")[
                        1
                    ],  # removes the SObject from FullName
                    description=record_type_description,
                    label=escape(rt["Name"]),
                    field=field,
                    picklist_values=record_type_picklist_values_xml,
                )

        sorted_picklist = validated_field["valueSet"]["valueSetDefinition"]["sorted"]
        if self.options["sorted"]:
            sorted_picklist = True

        # only include the object description if there's a value -- if it's blank, an error is thrown if the object is managed
        object_description = ""
        if validated_field["description"] != None:
            object_description = "<description>{}</description>".format(
                escape(validated_field["description"])
            )

        object_help_text = ""
        if validated_field["inlineHelpText"] != None:
            object_help_text = escape(validated_field["inlineHelpText"])

        # combine it all together
        object_xml = object_template.format(
            restricted=self.options["restricted"],
            field=field,
            description=object_description,
            helpText=object_help_text,
            label=escape(validated_field["label"]),
            sorted=sorted_picklist,
            picklist_values=picklist_values_xml,
            record_types=record_type_picklist_xml,
        )

        return object_xml

    def _deploy_metadata(self):
        self.logger.info("Deploying updated picklist values...")
        api = self._get_api(path=self.tempdir)
        return api()
