// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISpringNode is IERC721Enumerable {
	function generateNfts(
		string memory name,
		address user,
		uint count
	)
		external
		returns(uint[] memory);
	
	function burnBatch(address user, uint[] memory tokenIds) external;

	function setTokenIdToNodeType(uint tokenId, string memory nodeType) external;

	function tokenIdsToType(uint256 tokenId) external view returns (string memory nodeType);
}