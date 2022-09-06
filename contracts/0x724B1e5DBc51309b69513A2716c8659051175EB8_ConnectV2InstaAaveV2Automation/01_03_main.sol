//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title InstaAutomation
 * @dev Insta-Aave-v2-Automation
 */

import "./events.sol";
import "./interfaces.sol";

abstract contract Resolver is Events {
	InstaAaveAutomation internal immutable automation =
		InstaAaveAutomation(0x08c1c01be430C9381AD2794412C3E940254CD97c); // production

	function submitAutomationRequest(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		bool isAuth = AccountInterface(address(this)).isAuth(
			address(automation)
		);

		if (!isAuth)
			AccountInterface(address(this)).enable(address(automation));

		automation.submitAutomationRequest(
			safeHealthFactor,
			thresholdHealthFactor
		);

		(_eventName, _eventParam) = (
			"LogSubmitAutomation(uint256,uint256)",
			abi.encode(safeHealthFactor, thresholdHealthFactor)
		);
	}

	function cancelAutomationRequest()
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		automation.cancelAutomationRequest();

		bool isAuth = AccountInterface(address(this)).isAuth(
			address(automation)
		);

		if (isAuth)
			AccountInterface(address(this)).disable(address(automation));

		(_eventName, _eventParam) = ("LogCancelAutomation()", "0x");
	}

	function updateAutomationRequest(
		uint256 safeHealthFactor,
		uint256 thresholdHealthFactor
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		automation.cancelAutomationRequest();

		automation.submitAutomationRequest(
			safeHealthFactor,
			thresholdHealthFactor
		);

		(_eventName, _eventParam) = (
			"LogUpdateAutomation(uint256,uint256)",
			abi.encode(safeHealthFactor, thresholdHealthFactor)
		);
	}
}

contract ConnectV2InstaAaveV2Automation is Resolver {
	string public constant name = "Insta-Aave-V2-Automation-v1";
}