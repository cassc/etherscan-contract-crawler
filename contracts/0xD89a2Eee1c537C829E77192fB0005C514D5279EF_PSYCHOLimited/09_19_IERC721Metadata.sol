// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IERC721Metadata {
	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function tokenURI(uint256 _tokenId) external view returns (string memory);
}