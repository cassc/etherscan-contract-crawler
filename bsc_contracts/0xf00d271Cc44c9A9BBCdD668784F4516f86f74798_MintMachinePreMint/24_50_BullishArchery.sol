// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "./Bullish.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract BullishArchery is Bullish
{
	constructor(address _address_chick, address _address_nft, address _address_nft_holder) Bullish(_address_chick, _address_nft, _address_nft_holder)
	{
	}
}