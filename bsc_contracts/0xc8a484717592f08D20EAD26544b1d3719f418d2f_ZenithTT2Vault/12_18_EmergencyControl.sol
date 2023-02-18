// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

contract EmergencyControl
{
	bool public emergencyMode = false;

	modifier inEmergency
	{
		require(emergencyMode, "unavailable");
		_;
	}

	modifier nonEmergency
	{
		require(!emergencyMode, "unavailable");
		_;
	}

	function _declareEmergency() internal
	{
		_beforeEmergencyDeclared();
		emergencyMode = true;
		emit EmergencyDeclared();
		_afterEmergencyDeclared();
	}

	function _beforeEmergencyDeclared() internal virtual {}
	function _afterEmergencyDeclared() internal virtual {}

	event EmergencyDeclared();
}