// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A minimalistic, gas-efficient ERC-721 implementation forked from the
		`Super721` ERC-721 implementation used by SuperFarm.
	@author Tim Clancy <tim-clancy.eth>
	@author 0xthrpw
	@author Qazawat Zirak
	@author Rostislav Khlebnikov

	Compared to the original `Super721` implementation that this contract forked
	from, this is a very pared-down contract.

	@custom:date February 8th, 2022.
*/
interface ITiny721 {

	/**
		Return the total number of this token that have ever been minted.

		@return The total supply of minted tokens.
	*/
	function totalSupply () external view returns (uint256);

	/**
		Provided with an address parameter, this function returns the number of all
		tokens in this collection that are owned by the specified address.

		@param _owner The address of the account for which we are checking balances
	*/
	function balanceOf (
		address _owner
	) external returns (uint256);

	/**
		Return the address that holds a particular token ID.

		@param _id The token ID to check for the holding address of.

		@return The address that holds the token with ID of `_id`.
	*/
	function ownerOf (
		uint256 _id
	) external returns (address);

	/**
		This function performs an unsafe transfer of token ID `_id` from address
		`_from` to address `_to`. The transfer is considered unsafe because it does
		not validate that the receiver can actually take proper receipt of an
		ERC-721 token.

		@param _from The address to transfer the token from.
		@param _to The address to transfer the token to.
		@param _id The ID of the token being transferred.
	*/
	function transferFrom (
		address _from,
		address _to,
		uint256 _id
	) external;

	/**
		This function allows permissioned minters of this contract to mint one or
		more tokens dictated by the `_amount` parameter. Any minted tokens are sent
		to the `_recipient` address.

		Note that tokens are always minted sequentially starting at one. That is,
		the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
		Also note that per our use cases the intended recipient of these minted
		items will always be externally-owned accounts and not other contracts. As a
		result there is no safety check on whether or not the mint destination can
		actually correctly handle an ERC-721 token.

		@param _recipient The recipient of the tokens being minted.
		@param _amount The amount of tokens to mint.
	*/
	function mint_Qgo (
		address _recipient,
		uint256 _amount
	) external;
}