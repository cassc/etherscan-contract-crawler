// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// Thrown if a caller is not authorized in the proxy registry.
error NonAuthorizedCaller ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Ownable Delegate Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	A proxy registry contract. This contract was originally developed 
	by Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
interface IProxyRegistry {

	/// Return the address of tje current valid implementation of delegate proxy.
	function delegateProxyImplementation () external view returns (address);

	/**
		Returns the address of a proxy which was registered for the user address 
		before listing items.

		@param _owner The address of items lister.
	*/
	function proxies (
		address _owner
	) external view returns (address);

	/**
		Returns true if the `_caller` to the proxy registry is eligible and 
		registered.

		@param _caller The address of the caller.
	*/
	function authorizedCallers (
		address _caller
	) external view returns (bool);

	/**
		Returns the address of the `_caller`'s proxy and current implementation 
		address.

		@param _caller The address of the caller.
	*/
	function userProxyConfig (
		address _caller
	) external view returns (address, address);

	/**
		Enables an address to register its own proxy contract with this registry.

		@return _ The new contract with its implementation.
	*/
	function registerProxy () external returns (address);
}