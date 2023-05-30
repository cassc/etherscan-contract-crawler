// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// Thrown if the proxy's implementation is not set.
error ImplementationIsNotSet ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Delegate Proxy
	@author Facu Spagnuolo, OpenZeppelin
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>

	A basic call-delegating proxy contract which is compliant with the current 
	draft version of ERC-897. This contract was originally developed by Project 
	Wyvern. It has been modified to support a more modern version of Solidity 
	with associated best practices. The documentation has also been improved to 
	provide more clarity.

	@custom:date December 4th, 2022.
*/
abstract contract DelegateProxy {

	/**
		This payable fallback function exists to automatically delegate all calls to
		this proxy to the contract specified from `implementation()`. Anything
		returned from the delegated call will also be returned here.

		@custom:throws ImplementationIsNotSet if the contract implementation is not 
			set.
	*/
	fallback () external payable virtual {
		address target = implementation();

		// Ensure that the proxy implementation has been set correctly.
		if (target == address(0)) {
			revert ImplementationIsNotSet();
		}

		// Perform the actual call delegation.
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
			let size := returndatasize()
			returndatacopy(ptr, 0, size)
			switch result
			case 0 {
				revert(ptr, size)
			}
			default {
				return(ptr, size)
			}
		}
	}

	/**
		Return the current address where all calls to this proxy are delegated. If
		`proxyType()` returns `1`, ERC-897 dictates that this address MUST not
		change.

		@return _ The current address where calls to this proxy are delegated.
	*/
	function implementation () public view virtual returns (address);
}