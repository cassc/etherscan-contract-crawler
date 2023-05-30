// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title An improved treasury for Bonkler.
	@author Tim Clancy <tim-clancy.eth>

	Bonkler is a religious artifact bestowed to us by the Remilia Corporation. 
	Currently, the pool of Bonkler reserve assets cannot be independently grown 
	such that redemption of a Bonkler returns more Ether than its direct floor 
	reserve price. This contract is a wrapping treasury around the Bonkler 
	reserve system that allows for growth via external revenue streams.

	@custom:date April 20th, 2023.
*/
interface IBonklerTreasury {

	/**
		Allow a Bonkler holder to burn a Bonkler and redeem the Ether inside it. 
		Burning a Bonkler through this treasury also returns a share of any 
		additional accumulated Ether.

		The BonklerNFT contract has no native support for delegated redemption, so 
		this treasury contract must first be approved to spend the caller's 
		Bonkler. It must first take possession of the Bonkler before it is able to 
		burn the initial reserve.

		@param _bonklerId The ID of the Bonkler to burn and redeem.

		@return _ The total amount that was redeemed.
	*/
	function redeemBonkler (
		uint256 _bonklerId
	) external returns (uint256);
}