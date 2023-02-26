// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "./XNFTBase.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract XNFTBoom is XNFTBase
{
	constructor(string memory uri_) XNFTBase(uri_)
	{
		address_operator = msg.sender;
	}
}