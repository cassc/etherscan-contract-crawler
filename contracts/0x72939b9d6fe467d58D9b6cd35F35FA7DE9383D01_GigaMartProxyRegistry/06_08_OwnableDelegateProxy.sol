// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DelegateProxy.sol";

/// Thrown if the initial delgate call from this proxy is not successful.
error InitialTargetCallFailed ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Ownable Delegate Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	A call-delegating proxy with an owner. This contract was originally developed 
	by Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract OwnableDelegateProxy is Ownable, DelegateProxy {

	/// Whether or not the proxy was initialized.
	bool public initialized;

	/**
		This is a storage escape slot to match `AuthenticatedProxy` storage.
		uint8(bool) + uint184 = 192 bits. This prevents target (160 bits) from
		being placed in this storage slot.
	*/
	uint184 private _escape;

	/// The address of the proxy's current target.
	address public target;

	/**
		Construct this delegate proxy with an owner, initial target, and an initial
		call sent to the target.

		@param _owner The address which should own this proxy.
		@param _target The initial target of this proxy.
		@param _data The initial call to delegate to `_target`.

		@custom:throws InitialTargetCallFailed if the proxy initialization call 
			fails.
	*/
	constructor (
		address _owner,
		address _target,
		bytes memory _data
	) {
	
		/*
			Do not perform a redundant ownership transfer if the deployer should remain as the owner of this contract.
		*/
		if (_owner != owner()) {
			transferOwnership(_owner);
		}
		target = _target;

		/**
			Immediately delegate a call to the initial implementation and require it 
			to succeed. This is often used to trigger some kind of initialization 
			function on the target.
		*/
		(bool success, ) = _target.delegatecall(_data);
		if (!success) {
			revert InitialTargetCallFailed();
		}
	}

	/**
		Return the current address where all calls to this proxy are delegated. If
		`proxyType()` returns `1`, ERC-897 dictates that this address MUST not
		change.

		@return _ The current address where calls to this proxy are delegated.
	*/
	function implementation () public view override returns (address) {
		return target;
	}
}