// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Envious.sol";

/**
 * @title Additional extension for IERC721Envious, in order to make 
 * `tokenURI` dynamic, based on actual collateral.
 * @author 571nkY @ghostchain
 * @dev Ability to get royalty payments from collateral NFTs.
 */
interface IERC721EnviousDynamic is IERC721Envious {
	struct Edge {
		uint256 value;
		uint256 offset;
		uint256 range;
	}

	/**
	 * @dev Get `tokenURI` for specific token based on edges. Where actual 
	 * collateral should define which edge should be used, range shows
	 * maximum value in current edge, offset shows minimal value in current
	 * edge.
	 *
	 * @param tokenId unique identifier for token
	 */
	function getTokenPointer(uint256 tokenId) external view returns (uint256);
}