import click
import unittest
from tasks import add_picklist_values
from unittest import mock
from cumulusci.cli import cci
from cumulusci.core.config import BaseGlobalConfig
from cumulusci.core.config import BaseProjectConfig
from cumulusci.core.config import OrgConfig
from cumulusci.core.config import TaskConfig
from cumulusci.core.config import ServiceConfig
from cumulusci.core.keychain import BaseProjectKeychain

def run_click_command(cmd, *args, **kw):
    """Run a click command with a mock context and injected CCI config object.
    """
    config = kw.pop("config", None)
    with mock.patch("cumulusci.cli.cci.TEST_CONFIG", config):
        with click.Context(command=mock.Mock()):
            return cmd.callback(*args, **kw)

class TestAddPicklistValues(unittest.TestCase):
    
    def setUp(self):
        self.api_version = 46.0
        self.global_config = BaseGlobalConfig(
            {"project": {"package": {"api_version": self.api_version}}}
        )
        self.project_config = BaseProjectConfig(
            self.global_config, config={"noyaml": True}
        )
        self.project_config.config["project"] = {
            "package": {"api_version": self.api_version}
        }
        self.project_config.config["services"] = {
            "connected_app": {"attributes": {"client_id": {}}}
        }
        self.keychain = BaseProjectKeychain(self.project_config, "")
        self.project_config.set_keychain(self.keychain)

        self.task_config = TaskConfig()
        self.org_config = OrgConfig(
            {"instance_url": "https://example.com", "access_token": "abc123"}, "test"
        )
        self.base_tooling_url = "{}/services/data/v{}/tooling/".format(
            self.org_config.instance_url, self.api_version
        )
    
    def test_basic(self):
        config = mock.Mock()
        self.org_config.refresh_oauth_token = mock.Mock()
        config.get_org = mock.Mock(return_value=("test", self.org_config))
        config.project_config = self.project_config
        config.project_config.config["tasks"] = {
            "add_picklist_values": {"class_path": "tasks.add_picklist_values.AddPicklistValues"}
        }

        run_click_command(
            cci.task_run,
            config=config,
            task_name="add_picklist_values",
            org="test",
            o=[("sobject", "test"), ("field", "test"), ("values", "test")],
            debug=False,
            debug_before=False,
            debug_after=False,
            no_prompt=True,
        )