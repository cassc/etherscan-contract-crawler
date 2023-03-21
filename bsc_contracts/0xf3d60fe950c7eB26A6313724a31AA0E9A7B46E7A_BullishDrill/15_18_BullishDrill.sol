// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "./Bullish.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract BullishDrill is Bullish
{
	constructor(address _address_chick, address _address_nft)
		Bullish(_address_chick, _address_nft)
	{
	}
}