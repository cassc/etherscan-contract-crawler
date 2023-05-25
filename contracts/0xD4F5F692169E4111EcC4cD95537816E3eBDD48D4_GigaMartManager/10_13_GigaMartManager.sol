// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	AssetHandler
} from "./lib/AssetHandler.sol";

import {
	IGigaMartManager,
	InitialCallerIsAlreadySet
} from "./interfaces/IGigaMartManager.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Proxy Registry
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	@custom:date March 17th, 2023.
*/
contract GigaMartManager is AssetHandler, IGigaMartManager { 

	/// The public name of this registry.
	string public constant name = "GigaMart Manager";

	/// A flag for whether or not the initial authorized caller has been set.
	bool public initialCallersSet = false;

	/**
		Allow the owner of this registry to grant immediate authorization to a
		set of addresses for calling proxies in this registry. This is to avoid
		waiting for the `DELAY_PERIOD` otherwise specified for further caller
		additions.

		@param _initials The array of initial callers authorized to operate in this 
			registry.

		@custom:throws InitialCallerIsAlreadySet if an intial caller is already set 
			for this proxy registry.
	*/
	function grantInitialAuthentication (
		address[] calldata _initials
	) external onlyOwner {
		if (initialCallersSet) {
			revert InitialCallerIsAlreadySet();
		}
		initialCallersSet = true;

		// Authorize each initial caller.
		for (uint256 i; i < _initials.length; ) {
			authorizedCallers[_initials[i]] = true;
			unchecked {
				++i;
			}
		}
	}
}