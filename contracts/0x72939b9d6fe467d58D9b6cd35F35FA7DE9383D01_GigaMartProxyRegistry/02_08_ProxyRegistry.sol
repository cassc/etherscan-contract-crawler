// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./AuthenticatedProxy.sol";
import "../interfaces/IProxyRegistry.sol";
import "../proxy/OwnableDelegateProxy.sol";

/// Thrown if an address authentifying is already an authorized caller.
error AlreadyAuthorized ();

/// Thrown if an address is already pending authentication.
error AlreadyPendingAuthentication ();

/// Thrown if an address ending authentication has not yet started it.
error AddressHasntStartedAuth ();

/// Thrown if an address ending authentication has not delayed long enough.
error AddressHasntClearedTimelock ();

/// Thrown if a caller has already registered a proxy.
error ProxyAlreadyRegistered ();

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
contract ProxyRegistry is IProxyRegistry, Ownable {

	/**
		Each `OwnableDelegateProxy` contract ultimately dictates its implementation
		details elsewhere, to `delegateProxyImplementation`.
	*/
	address public delegateProxyImplementation;

	/**
		This mapping relates an addresses to its own personal `OwnableDelegateProxy`
		which allow it to proxy functionality to the various callers contained in
		`authorizedCallers`.
	*/
	mapping ( address => address ) public proxies;

	/**
		This mapping relates addresses which are pending access to the registry to
		the timestamp where they began the `startGrantAuthentication` process.
	*/
	mapping ( address => uint256 ) public pendingCallers;

	/**
		This mapping relates an address to a boolean specifying whether or not it is
		allowed to call the `OwnableDelegateProxy` for any given address in the
		`proxies` mapping.
	*/
	mapping ( address => bool ) public authorizedCallers;

	/**
		A delay period which must elapse before adding an authenticated contract to
		the registry, thus allowing it to call the `OwnableDelegateProxy` for an
		address in the `proxies` mapping.

		This `ProxyRegistry` contract was designed with the intent to be owned by a
		DAO, so this delay mitigates a particular class of attack against an owning
		DAO. If at any point the value of assets accessible to the
		`OwnableDelegateProxy` contracts exceeded the cost of gaining control of the
		DAO, a malicious but rational attacker could spend (potentially 
		considerable) resources to then have access to all `OwnableDelegateProxy`
		contracts via a malicious contract upgrade. This delay period renders this
		attack ineffective by granting time for addresses to remove assets from
		compromised `OwnableDelegateProxy` contracts.

		Under its present usage, this delay period protects exchange users from a 
		malicious upgrade.
	*/
	uint256 public DELAY_PERIOD = 1 weeks;

	/**
		Construct this registry by specifying the initial implementation of all
		`OwnableDelegateProxy` contracts that are registered by users. This registry
		will use `AuthenticatedProxy` as its initial implementation.
	*/
	constructor () {
		delegateProxyImplementation = address(new AuthenticatedProxy());
	}

	/**
		Allow the `ProxyRegistry` owner to begin the process of enabling access to
		the registry for the unauthenticated address `_unauthenticated`. Once the
		grant authentication process has begun, it is subject to the `DELAY_PERIOD`
		before the authentication process may conclude. Once concluded, the new
		address `_unauthenticated` will have access to the registry.

		@param _unauthenticated The new address to grant access to the registry.

		@custom:throws AlreadyAuthorized if the address beginning authentication is 
			already an authorized caller.
		@custom:throws AlreadyPendingAuthentication if the address beginning 
			authentication is already pending.
	*/
	function startGrantAuthentication (
		address _unauthenticated
	) external onlyOwner {
		if (authorizedCallers[_unauthenticated]) {
			revert AlreadyAuthorized();
		}
		if (pendingCallers[_unauthenticated] != 0) {
			revert AlreadyPendingAuthentication();
		}
		pendingCallers[_unauthenticated] = block.timestamp;
	}

	/**
		Allow the `ProxyRegistry` owner to end the process of enabling access to the
		registry for the unauthenticated address `_unauthenticated`. If the required
		`DELAY_PERIOD` has passed, then the new address `_unauthenticated` will have
		access to the registry.

		@param _unauthenticated The new address to grant access to the registry.

		@custom:throws AlreadyAuthorized if the address beginning authentication is
			already an authorized caller.
		@custom:throws AddressHasntStartedAuth if the address attempting to end 
			authentication has not yet started it.
		@custom:throws AddressHasntClearedTimelock if the address attempting to end 
			authentication has not yet incurred a sufficient delay.
	*/
	function endGrantAuthentication(
		address _unauthenticated
	) external onlyOwner {
		if (authorizedCallers[_unauthenticated]) {
			revert AlreadyAuthorized();
		}
		if (pendingCallers[_unauthenticated] == 0) {
			revert AddressHasntStartedAuth();
		}
		unchecked {
			if (
				(pendingCallers[_unauthenticated] + DELAY_PERIOD) >= block.timestamp
			) {
				revert AddressHasntClearedTimelock();
			}
		}
		pendingCallers[_unauthenticated] = 0;
		authorizedCallers[_unauthenticated] = true;
	}

	/**
		Allow the owner of the `ProxyRegistry` to immediately revoke authorization
		to call proxies from the specified address.

		@param _caller The address to revoke authentication from.
	*/
	function revokeAuthentication (
		address _caller
	) external onlyOwner {
		authorizedCallers[_caller] = false;
	}

	/**
		Enables an address to register its own proxy contract with this registry.

		@return _ The address of the new `OwnableMutableDelegateProxy` contract 
			with its `delegateProxyImplementation` implementation.

		@custom:throws ProxyAlreadyRegistered if the caller has already registered 
			a proxy.
	*/
	function registerProxy () external returns (address) {
		if (address(proxies[_msgSender()]) != address(0)) {
			revert ProxyAlreadyRegistered();
		}

		/** 
			Construct the new `OwnableDelegateProxy` with this registry's initial
			implementation and call said implementation's "initialize" function.
		*/
		OwnableDelegateProxy proxy = new OwnableDelegateProxy(
			_msgSender(),
			delegateProxyImplementation,
			abi.encodeWithSignature("initialize(address)", address(this))
		);
		address proxyAddr = address(proxy);
		proxies[_msgSender()] = proxyAddr;
		return proxyAddr;
	}

	/**
		Returns the address of the caller's proxy and the current implementation 
		address.

		@param _caller The address of the caller.

		@return _ A tuple containing the address of the caller's proxy and the 
			address of the current implementation of the proxy.
	*/
	function userProxyConfig(
		address _caller
	) external view returns (address, address) {
		return (proxies[_caller], delegateProxyImplementation);
	}
}