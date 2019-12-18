import unittest
from tasks import add_picklist_values
from unittest import mock
import responses
from cumulusci.salesforce_api.tests.metadata_test_strings import deploy_result
from cumulusci.tasks.salesforce.tests.util import create_task

task_options = {
    "sobject": "hed__Attribute__c",
    "field": "hed__Attribute_Type__c",
    "values": "Test Value" # recordtypes, sorted, otherlast
}

task_options_invalid_object = {
    "sobject": "hed__Attibute__c",
    "field": "hed__Attribute_Type__c",
    "values": "Test Value"
}

task_options_invalid_field = {
    "sobject": "hed__Attribute__c",
    "field": "hed__Attibute_Type__c",
    "values": "Test Value"
}

api_version = "47.0"

class TestAddPicklistValues(unittest.TestCase):

    # to-do tests: record types, sorted, otherlast, bad object, bad field, etc
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
        add_picklist_values_task = create_task(add_picklist_values.AddPicklistValues, task_options)
        add_picklist_values_task.task_config
        
        base_tooling_url = self._get_base_tooling_url(add_picklist_values_task.org_config.instance_url)
        
        base_deployment_url = self._get_base_deployment_url(
            add_picklist_values_task.org_config.instance_url, 
            add_picklist_values_task.org_config.org_id
        )

        customobject_query_url = (
            base_tooling_url
            + "query/?q=SELECT+DeveloperName%2C+DurableId+FROM+EntityDefinition+"
            "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute%27"
        )

        expected_customobject_query_response = {
            "done": True,
            "records": [{
                "DurableId": 123
            }],
            "size": 1,
        }

        customfield_query_url = (
            base_tooling_url
            + "query/?q=SELECT+Id%2C+DeveloperName%2C+Metadata+FROM+CustomField+"
            + "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute_Type%27+AND+TableEnumOrId+%3D+%27123%27"
        )
        
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
            body=deploy_result.format(status="Succeeded", extra="<id>123</id>"),
            status=200,
            content_type="text/xml; charset=utf-8",
        )

        add_picklist_values_task()

        self.assertEqual(4, len(responses.calls))
        self.assertEqual(customobject_query_url, responses.calls[0].request.url)
        self.assertEqual(customfield_query_url, responses.calls[1].request.url)
        self.assertEqual(base_deployment_url, responses.calls[2].request.url)
        self.assertEqual(base_deployment_url, responses.calls[3].request.url)