//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ITheChainMinter {
	function mint(
		uint256 tokenId,
		address creator,
		bytes32 currentHash,
		bytes32 previousHash,
		uint96 price,
		uint32 startsSaleAt,
		string calldata uri,
		bytes calldata proof
	) external;
}