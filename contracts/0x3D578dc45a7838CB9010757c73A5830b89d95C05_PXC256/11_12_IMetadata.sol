// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IMetadata {
	function getTokenURI(
		uint256 _tokenId,
		uint256 _incrementalId,
		address _creator,
        string calldata _creatorName
	) external view returns (string memory uri);
}