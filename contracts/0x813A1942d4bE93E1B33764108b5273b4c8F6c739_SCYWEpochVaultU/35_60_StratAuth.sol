// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Auth } from "./Auth.sol";
import { EAction } from "../interfaces/Structs.sol";
import { SectorErrors } from "../interfaces/SectorErrors.sol";

// import "hardhat/console.sol";

abstract contract StratAuth is Auth, SectorErrors {
	address public vault;

	modifier onlyVault() {
		if (msg.sender != vault) revert OnlyVault();
		_;
	}

	event EmergencyAction(address indexed target, bytes data);

	/// @notice calls arbitrary function on target contract in case of emergency
	function emergencyAction(EAction[] calldata actions) public payable onlyOwner {
		uint256 l = actions.length;
		for (uint256 i; i < l; ++i) {
			address target = actions[i].target;
			bytes memory data = actions[i].data;
			(bool success, ) = target.call{ value: actions[i].value }(data);
			require(success, "emergencyAction failed");
			emit EmergencyAction(target, data);
		}
	}
}