// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.19;

import { IFUMOToken } from "./interfaces/IFUMOToken.sol";
import { FUMOMintable } from "./FUMOMintable.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A contract for redeeming whole $FUMO tokens for a legendary new NFT.
	@author cheb <evmcheb.eth>
	@author Tim Clancy <tim-clancy.eth>
	
	This redemption contract allows for anyone to mint FUMO NFT by burning
	multiples of whole $FUMO token.

	@custom:date Jun 28th, 2023
*/
contract Redeemer {

	/// The number of times an address has redeemed a $FUMO.
	mapping ( address => uint256 ) public redeemCount;

	/// The address of the $FUMO ERC-20 token contract.
	IFUMOToken public immutable fumo;

	/// The address of the ERC-721 receipt contract.
	FUMOMintable public immutable receipt;

	/**
		Construct a new instance of the FUMO ERC-721 token.

		@param _fumo The address of the $FUMO ERC-20 token contract.
		@param _receipt The address of the ERC-721 receipt contract.
	*/
	constructor (
		IFUMOToken _fumo,
		FUMOMintable _receipt
	) {
		fumo = _fumo;
		receipt = _receipt;
	}

	/**
		Redeems `_count` $FUMO and mints `2 * _count` receipt NFTs.

		@param _count The number of whole $FUMO token to redeem.
	*/
	function redeem (
		uint256 _count
	) external {

		// Reduces the $FUMO supply AND user balance by `_count`.
		fumo.burnFrom(msg.sender, _count * 1e18);
		redeemCount[msg.sender] += _count;
		for (uint256 i = 0; i < _count; ) {
			receipt.mint(msg.sender);
			receipt.mint(msg.sender);
			unchecked { ++i; }
		}
	}
}