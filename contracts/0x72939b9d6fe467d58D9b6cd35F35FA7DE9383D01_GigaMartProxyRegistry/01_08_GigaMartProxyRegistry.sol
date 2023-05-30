// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./proxy/ProxyRegistry.sol";

/// Thrown if any initial caller of this proxy registry is already set.
error InitialCallerIsAlreadySet ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Proxy Registry
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>
	
	A fully-implemented proxy registry contract.

	@custom:date December 4th, 2022.
*/
contract GigaMartProxyRegistry is ProxyRegistry {

	/// The public name of this registry.
	string public constant name = "GigaMart Proxy Registry";

	/// A flag for whether or not the initial authorized caller has been set.
	bool public initialCallersSet = false;

	/**
		Constructing a new instance of this registry is passed through to the 
		`ProxyRegistry` constructor.
	*/
	constructor () ProxyRegistry() { }

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