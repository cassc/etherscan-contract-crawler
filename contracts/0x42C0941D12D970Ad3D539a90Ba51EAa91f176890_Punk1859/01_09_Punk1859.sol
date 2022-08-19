// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./TradingCard.sol";

contract Punk1859 is TradingCard {

	constructor(
		string memory name_,
		string memory symbol_,
		string memory metadataRoot_,
		string memory contractMetadata_
	) TradingCard(
		name_,
		symbol_,
		metadataRoot_,
		contractMetadata_
	){

	}

}