// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.19;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title An interface for the $FUMO ERC-20 token.
	@author cheb <evmcheb.eth>
	@author Tim Clancy <tim-clancy.eth>
	
	This interface is for basic interactions with the existing $FUMO token.

	@custom:date Jun 28th, 2023
*/
interface IFUMOToken {
	function burnFrom (
		address _from,
		uint256 _value
	) external returns (bool out);

	function totalSupply () external view returns (uint256 out);

	function balanceOf (
		address _owner
	) external view returns (uint256 out);

	function approve (
		address _spender,
		uint256 _value
	) external returns (bool out);
}