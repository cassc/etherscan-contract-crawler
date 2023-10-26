//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ITheChainCollection {
	struct HashData {
		bytes32 previousHash;
		address creator;
		uint96 tokenId;
		string uri;
	}

	function mint(
		uint256 tokenId,
		address creator,
		address transferTo,
		bytes32 currentHash,
		bytes32 previousHash,
		string calldata uri
	) external;
}