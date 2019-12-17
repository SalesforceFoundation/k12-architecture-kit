import unittest
from tasks import add_picklist_values
from unittest import mock
import responses
from cumulusci.salesforce_api.tests.metadata_test_strings import deploy_result
from cumulusci.tasks.salesforce.tests.util import create_task
#from cumulusci.salesforce_api import soap_envelopes

task_options = {
    "sobject": "hed__Attribute__c",
    "field": "hed__Attribute_Type__c",
    "values": "Test Value" # recordtypes, sorted, otherlast
}

api_version = "47.0"

class TestAddPicklistValues(unittest.TestCase):

    # to-do tests: record types, sorted, otherlast, bad object, bad field, etc
    
    @responses.activate
    def test_basic(self):
        add_picklist_values_task = create_task(add_picklist_values.AddPicklistValues, task_options)
        
        # to-do: define URLs
        # to-do: define responses
        base_tooling_url = "{}/services/data/v{}/tooling/".format(
            add_picklist_values_task.org_config.instance_url,
            api_version
        )
        
        base_deployment_url = "{}/services/Soap/m/{}/{}".format(
            add_picklist_values_task.org_config.instance_url,
            api_version,
            add_picklist_values_task.org_config.org_id
        )

        customfield_query_url = (
            base_tooling_url
            + "query/?q=SELECT+Id%2C+DeveloperName%2C+Metadata+FROM+CustomField+"
            + "WHERE+NamespacePrefix+%3D+%27hed%27+AND+DeveloperName+%3D+%27Attribute_Type%27+"
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
            url=customfield_query_url, 
            match_querystring=True, 
            json=expected_customfield_query_response
        )

        responses.add(
            method=responses.POST,
            url=base_deployment_url,
            body=deploy_result.format(status="Succeeded", extra=""), #soap_envelopes.CHECK_DEPLOY_STATUS.format(process_id="123"),
            status=200,
            content_type="text/xml; charset=utf-8",
        )

        add_picklist_values_task()