// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/// Thrown if non-authorized account tries to execute asset transfer.
error NonAuthorized(address);

/*
Enum of ItemTypes for the transfer.
	1. ERC721 - 0
	2. ERC1155 - 1
*/
enum ItemType {
	ERC721,
	ERC1155
}

/*
	Helper Struct for restricted ERC721 or ERC1155 token transfers.

	itemType - defines the type of the Item to transfer..
	collection - address of the collection, to which the item belongs to.
	from - address, from which item is being transferred.
	to - address where item is being transferred.
	id - it of the token.
	amount - amount of the token to transfer in case of ERC1155.
*/
struct Item {
	ItemType itemType;
	address collection;
	address from;
	address to;
	uint256 id;
	uint256 amount;
}

/*
	Helper struct for restricted ERC20 token transfers.

	token - address of the token, which is being transferred.
	from - address, from which token is being transferred.
	to - address where token is being transferred.
	amount - amount of ERC20 token to transfer.
*/
struct ERC20Payment {
	address token;
	address from;
	address to;
	uint256 amount;
}

/*
	Enum of Asset types for the transfer.
	1. ERC20 - 0
	2. ERC721 - 1
	3. ERC1155 - 2
*/
enum AssetType {
	ERC20,
	ERC721,
	ERC1155
}

/*
	Helper struct for public transfers.

	assetType - defines the type of the Asset to transfer.
	collection - address of the collection, to which the asset belongs to.
	to - address where item is being transferred.
	id - it of the token.
	amount - amount of ERC20 token to transfer.
*/
struct Transfer {
	AssetType assetType;
	address collection;
	address to;
	uint256 id;
	uint256 amount;
}

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Asset Handler component interface.
*/
interface IAssetHandler {

	/**
		Execute restricted ERC721 or ERC1155 transfer. Reverts if caller is
		not authorized to call this function.

		@param _item Item to transfer.
		
		@custom:throws NonAuthorized.
	*/
	function transferItem (Item calldata _item) external;


	/**
		Execute multiple transfers. 

		@param _transfers Items to transfer.
	*/
	function transferMultipleItems (
		Transfer[] calldata _transfers
	) external;

	/**
		Executes restricted ERC20 transfer. Reverts if caller is
		not authorized to call this function.

		@param _token Address of the token.
		@param _from Address, from which tokens are being transferred.
		@param _to Address, to which tokens are being transferrec.
		@param _amount Amount of tokens.

		@custom:throws NonAuthorized.
	*/
	function transferERC20 (
		address _token,
		address _from,
		address _to,
		uint256 _amount
	) external;

	/**
		Executes multiple restricted ERC20 transfers. Reverts if caller is
		not authorized to call this function.

		@param _payments Array of helper structs, which contains information
		about ERC20 token transfers.

		@custom:throws NonAuthorized.
	*/
	function transferPayments (
		ERC20Payment[] calldata _payments
	) external;

}

/// Thrown if an address authentifying is already an authorized caller.
error AlreadyAuthorized ();

/// Thrown if an address is already pending authentication.
error AlreadyPendingAuthentication ();

/// Thrown if an address ending authentication has not yet started it.
error AddressHasntStartedAuth ();

/// Thrown if an address ending authentication has not delayed long enough.
error AddressHasntClearedTimelock ();


/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Registry component interface.
*/
interface IRegistry {

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
	) external;

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
	) external;

	/**
		Allow the owner of the `ProxyRegistry` to immediately revoke authorization
		to call proxies from the specified address.

		@param _caller The address to revoke authentication from.
	*/
	function revokeAuthentication (
		address _caller
	) external;
}

/// Thrown if any initial caller of this proxy registry is already set.
error InitialCallerIsAlreadySet ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Manager contract interface.
*/
interface IGigaMartManager is IRegistry, IAssetHandler{
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
	) external;
}