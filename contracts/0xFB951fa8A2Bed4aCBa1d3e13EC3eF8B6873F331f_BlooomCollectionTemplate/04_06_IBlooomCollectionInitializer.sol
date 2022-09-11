// SPDX-License-Identifier: CC0
pragma solidity ^0.8.14;

interface IBlooomCollectionInitializer {
	function initialize(
		address payable creator_,
		string memory name_,
		string memory symbol_,
		uint32 maxSupply_,
		uint32 maxPerWallet_,
		uint64 price_,
		string memory baseURI_
	) external;
}