import unittest
from tasks import add_picklist_values
from unittest import mock
import responses
from cumulusci.salesforce_api.tests.metadata_test_strings import deploy_result
from cumulusci.tasks.salesforce.tests.util import create_task

# to-do: add otherlast test? assert sorted?
task_options = {
    "sobject": "hed__Attribute__c",
    "field": "hed__Attribute_Type__c",
    "values": "Test Value 1,Test Value 2,Test Value 3"
}

task_options_with_record_types = {
    "sobject": "hed__Attribute__c",
    "field": "hed__Attribute_Type__c",
    "values": "Test Value",
    "recordtypes": "hed__Student_Characteristic",
    "sorted": True
}

task_options_invalid_sobject = {
    "sobject": "hed__Attibute__c",
    "field": "hed__Attribute_Type__c",
    "values": "Test Value"
}

task_options_invalid_field = {
    "sobject": "hed__Attribute__c",
    "field": "hed__Attibute_Type__c",
    "values": "Test Value"
}

expected_customobject_query_response = {
    "done": True,
    "records": [{
        "DurableId": 123
    }],
    "size": 1,
}

expected_customfield_query_response = {
    "done": True,
    "records": [{
        "Id": 1,
        "Metadata": {
            "description": "Test",
            "inlineHelpText": "Test",
            "label": "Attribute Type",
            "type": "Picklist",
            "valueSet": {
                "valueSetDefinition": {
                    "sorted": False,
                    "value": [
                        {
                            "default": False,
                            "label": "Existing Value",
                            "valueName": "Existing Value"
                        }
                    ]
                }
            }
        }
    }],
    "size": 1,
}

expected_recordtypes_query_response = {
    "done": True,
    "records": [{
        "Id": 1,
        "FullName": "hed__Attribute__c.hed__Credential",
        "Metadata": {
            "active": True,
            "description": "Test",
            "label": "Credential",
            "picklistValues": [{
                "picklist": "Some_Other_Field__c",
                "values": [{
                    "default": False,
                    "valueName": "Test"
                }]
            },
                {
                "picklist": "hed__Attribute_Type__c",
                "values": [{
                    "default": False,
                    "valueName": "Existing Value"
                }]
            }]
        },
        "Name": "Credential"
    },
        {
        "Id": 2,
        "FullName": "hed__Attribute__c.hed__Student_Characteristic",
        "Metadata": {
            "active": True,
            "description": "Test",
            "label": "Student Characteristic",
            "picklistValues": [{
                "picklist": "Some_Other_Field__c",
                "values": [{
                    "default": False,
                    "valueName": "Test"
                }]
            },
                {
                "picklist": "hed__Attribute_Type__c",
                "values": [{
                    "default": False,
                    "valueName": "Existing Value"
                }]
            }]
        },
        "Name": "Student Characteristic"
    }],
    "size": 2,
}

api_version = "48.0"


class TestAddPicklistValues(unittest.TestCase):

    def _get_base_tooling_url(self, instance_url):
        return "{}/services/data/v{}/tooling/".format(
            instance_url,
            api_version
        )

    def _get_base_deployment_url(self, instance_url, org_id):
        return "{}/services/Soap/m/{}/{}".format(
            instance_url,
            api_version,
            org_id
        )

    @responses.activate
    def test_basic(self):
        add_picklist_values_task = create_task(
            add_picklist_values.AddPicklistValues, task_options)

        base_tooling_url = self._get_base_tooling_url(
            add_picklist_values_task.org_config.instance_url)

        base_deployment_url = self._get_base_deployment_url(
            add_picklist_values_task.org_config.instance_url,
            add_picklist_values_task.org_config.org_id
        )

        customobject_query_url = (
            base_tooling_url
            + "query/?q=SELECT+DeveloperName%2C+DurableId+FROM+EntityDefinition+"
            "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute%27"
        )

        customfield_query_url = (
            base_tooling_url
            + "query/?q=SELECT+Id%2C+DeveloperName%2C+Metadata+FROM+CustomField+"
            + "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute_Type%27+AND+TableEnumOrId+%3D+%27123%27"
        )

        responses.add(
            method=responses.GET,
            url=customobject_query_url,
            match_querystring=True,
            json=expected_customobject_query_response
        )

        responses.add(
            method=responses.GET,
            url=customfield_query_url,
            match_querystring=True,
            json=expected_customfield_query_response
        )

        responses.add(
            method=responses.POST,
            url=base_deployment_url,
            body=deploy_result.format(
                status="Succeeded", extra="<id>123</id>"),
            status=200,
            content_type="text/xml; charset=utf-8",
        )

        add_picklist_values_task()

        self.assertEqual(4, len(responses.calls))
        self.assertEqual(customobject_query_url,
                         responses.calls[0].request.url)
        self.assertEqual(customfield_query_url, responses.calls[1].request.url)
        self.assertEqual(base_deployment_url, responses.calls[2].request.url)
        self.assertEqual(base_deployment_url, responses.calls[3].request.url)

    @responses.activate
    def test_record_types(self):
        add_picklist_values_task = create_task(
            add_picklist_values.AddPicklistValues, task_options_with_record_types)

        base_tooling_url = self._get_base_tooling_url(
            add_picklist_values_task.org_config.instance_url)

        base_deployment_url = self._get_base_deployment_url(
            add_picklist_values_task.org_config.instance_url,
            add_picklist_values_task.org_config.org_id
        )

        customobject_query_url = (
            base_tooling_url
            + "query/?q=SELECT+DeveloperName%2C+DurableId+FROM+EntityDefinition+"
            "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute%27"
        )

        customfield_query_url = (
            base_tooling_url
            + "query/?q=SELECT+Id%2C+DeveloperName%2C+Metadata+FROM+CustomField+"
            + "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute_Type%27+AND+TableEnumOrId+%3D+%27123%27"
        )

        recordtypes_query_url = (
            base_tooling_url
            + "query/?q=SELECT+Id%2C+FullName%2C+Metadata%2C+Name+FROM+RecordType+"
            "WHERE+SobjectType+%3D+%27hed__Attribute__c%27+AND+IsActive+%3D+True"
        )

        responses.add(
            method=responses.GET,
            url=customobject_query_url,
            match_querystring=True,
            json=expected_customobject_query_response
        )

        responses.add(
            method=responses.GET,
            url=customfield_query_url,
            match_querystring=True,
            json=expected_customfield_query_response
        )

        responses.add(
            method=responses.GET,
            url=recordtypes_query_url,
            match_querystring=True,
            json=expected_recordtypes_query_response
        )

        responses.add(
            method=responses.POST,
            url=base_deployment_url,
            body=deploy_result.format(
                status="Succeeded", extra="<id>123</id>"),
            status=200,
            content_type="text/xml; charset=utf-8",
        )

        add_picklist_values_task()

        self.assertEqual(5, len(responses.calls))
        self.assertEqual(customobject_query_url,
                         responses.calls[0].request.url)
        self.assertEqual(customfield_query_url, responses.calls[1].request.url)
        self.assertEqual(recordtypes_query_url, responses.calls[2].request.url)
        self.assertEqual(base_deployment_url, responses.calls[3].request.url)
        self.assertEqual(base_deployment_url, responses.calls[4].request.url)

    @responses.activate
    def test_invalid_sobject(self):
        add_picklist_values_task = create_task(
            add_picklist_values.AddPicklistValues, task_options_invalid_sobject)

        base_tooling_url = self._get_base_tooling_url(
            add_picklist_values_task.org_config.instance_url)

        customobject_query_url = (
            base_tooling_url
            + "query/?q=SELECT+DeveloperName%2C+DurableId+FROM+EntityDefinition+"
            "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attibute%27"
        )

        expected_customobject_query_response_with_no_records = {
            "done": True,
            "records": [],
            "size": 0,
        }

        responses.add(
            method=responses.GET,
            url=customobject_query_url,
            match_querystring=True,
            json=expected_customobject_query_response_with_no_records
        )

        with self.assertRaises(Exception) as ex:
            add_picklist_values_task()

        self.assertEqual(1, len(responses.calls))
        self.assertEqual(customobject_query_url,
                         responses.calls[0].request.url)
        self.assertEqual('hed__Attibute__c object not found',
                         str(ex.exception))

    @responses.activate
    def test_invalid_field(self):
        add_picklist_values_task = create_task(
            add_picklist_values.AddPicklistValues, task_options_invalid_field)

        base_tooling_url = self._get_base_tooling_url(
            add_picklist_values_task.org_config.instance_url)

        customobject_query_url = (
            base_tooling_url
            + "query/?q=SELECT+DeveloperName%2C+DurableId+FROM+EntityDefinition+"
            "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute%27"
        )

        customfield_query_url = (
            base_tooling_url
            + "query/?q=SELECT+Id%2C+DeveloperName%2C+Metadata+FROM+CustomField+"
            + "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attibute_Type%27+AND+TableEnumOrId+%3D+%27123%27"
        )

        expected_customfield_query_response_with_no_records = {
            "done": True,
            "records": [],
            "size": 0,
        }

        responses.add(
            method=responses.GET,
            url=customobject_query_url,
            match_querystring=True,
            json=expected_customobject_query_response
        )

        responses.add(
            method=responses.GET,
            url=customfield_query_url,
            match_querystring=True,
            json=expected_customfield_query_response_with_no_records
        )

        with self.assertRaises(Exception) as ex:
            add_picklist_values_task()

        self.assertEqual(2, len(responses.calls))
        self.assertEqual(customobject_query_url,
                         responses.calls[0].request.url)
        self.assertEqual(customfield_query_url,
                         responses.calls[1].request.url)
        self.assertEqual('hed__Attibute_Type__c field not found on hed__Attribute__c',
                         str(ex.exception))

    @responses.activate
    def test_invalid_picklist_field(self):
        add_picklist_values_task = create_task(
            add_picklist_values.AddPicklistValues, task_options)

        base_tooling_url = self._get_base_tooling_url(
            add_picklist_values_task.org_config.instance_url)

        customobject_query_url = (
            base_tooling_url
            + "query/?q=SELECT+DeveloperName%2C+DurableId+FROM+EntityDefinition+"
            "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute%27"
        )

        customfield_query_url = (
            base_tooling_url
            + "query/?q=SELECT+Id%2C+DeveloperName%2C+Metadata+FROM+CustomField+"
            + "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute_Type%27+AND+TableEnumOrId+%3D+%27123%27"
        )

        expected_customfield_query_response_with_invalid_field = {
            "done": True,
            "records": [{
                "Id": 1,
                "Metadata": {
                    "description": "Test",
                    "inlineHelpText": "Test",
                    "label": "Attribute Type",
                    "type": "NotAPicklist",
                }
            }],
            "size": 1,
        }

        responses.add(
            method=responses.GET,
            url=customobject_query_url,
            match_querystring=True,
            json=expected_customobject_query_response
        )

        responses.add(
            method=responses.GET,
            url=customfield_query_url,
            match_querystring=True,
            json=expected_customfield_query_response_with_invalid_field
        )

        with self.assertRaises(Exception) as ex:
            add_picklist_values_task()

        self.assertEqual(2, len(responses.calls))
        self.assertEqual(customobject_query_url,
                         responses.calls[0].request.url)
        self.assertEqual(customfield_query_url,
                         responses.calls[1].request.url)
        self.assertEqual('hed__Attribute_Type__c field is not a picklist field',
                         str(ex.exception))
