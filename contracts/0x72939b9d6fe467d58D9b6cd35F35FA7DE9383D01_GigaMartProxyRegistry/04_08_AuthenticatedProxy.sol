// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IProxyRegistry.sol";

/**
	Thrown if attempting to initialize a proxy which has already been initialized.
*/
error ProxyAlreadyInitialized ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Authenticated Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@custom:contributor Rostislav Khlebnikov <@catpic5buck>

	An ownable call-delegating proxy which can receive tokens and only make calls 
	against contracts that have been approved by a `ProxyRegistry`. This contract 
	was originally developed by Project Wyvern. It has been modified to support a 
	more modern version of Solidity with associated best practices. The 
	documentation has also been improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract AuthenticatedProxy is Ownable {

	/**
		An enum for selecting the method by which we would like to perform a call 
		in the `proxy` function.
	*/
	enum CallType {
		Call,
		DelegateCall
	}

	/// Whether or not this proxy is initialized. It may only initialize once.
	bool public initialized = false;

	/// The associated `ProxyRegistry` contract with authentication information.
	address public registry;

	/// Whether or not access has been revoked.
	bool public revoked;

	/**
		An event fired when the proxy contract's access is revoked or unrevoked.

		@param revoked The status of the revocation call; true if access is 
			revoked and false if access is unrevoked.
	*/
	event Revoked (
		bool revoked
	);

	/**
		Initialize this authenticated proxy for its owner against a specified
		`ProxyRegistry`. The registry controls the eligible targets.

		@param _registry The registry to create this proxy against.
	*/
	function initialize (
		address _registry
	) external {
		if (initialized) {
			revert ProxyAlreadyInitialized();
		}
		initialized = true;
		registry = _registry;
	}

	/**
		Allow the owner of this proxy to set the revocation flag. This permits them
		to revoke access from the associated `ProxyRegistry` if needed.

		@param _revoke The revocation flag to set for this proxy.
	*/
	function setRevoke (
		bool _revoke
	) external onlyOwner {
		revoked = _revoke;
		emit Revoked(_revoke);
	}

	/**
		Trigger this proxy to call a specific address with the provided data. The
		proxy may perform a direct or a delegate call. This proxy can only be called
		by the owner, or on behalf of the owner by a caller authorized by the
		registry. Unless the user has revoked access to the registry, that is.

		@param _target The target address to make the call to.
		@param _type The type of call to make: direct or delegated.
		@param _data The call data to send to `_target`.

		@return _ Whether or not the call succeeded.

		@custom:throws NonAuthorizedCaller if the proxy caller is not the owner or 
			an authorized caller from the proxy registry.
	*/
	function call (
		address _target,
		CallType _type,
		bytes calldata _data
	) public returns (bool) {
		if (
			_msgSender() != owner() &&
			(revoked || !IProxyRegistry(registry).authorizedCallers(_msgSender()))
		) {
			revert NonAuthorizedCaller();
		}

		// The call is authorized to be performed, now select a type and return.
		if (_type == CallType.Call) {
			(bool success, ) = _target.call(_data);
			return success;
		} else if (_type == CallType.DelegateCall) {
			(bool success, ) = _target.delegatecall(_data);
			return success;
		}
		return false;
	}
}