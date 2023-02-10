//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title OwnershipChecker
/// @author @dievardump
contract OwnershipChecker {
	/// @notice function that tries to hget an NFT owner address... might need to deploy a specific contract
	///         for this if there is a need for collections not implemneting ownerOf rightly
	/// @param collection the collection
	/// @param tokenId the token id
	function ownerOf(address collection, uint256 tokenId) public view returns (address to) {
		// punks maybe?
		if (collection == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
			to = IOwnershipChecker(collection).punkIndexToAddress(tokenId);
		} else {
			to = IERC721(collection).ownerOf(tokenId);
		}
	}
}

interface IOwnershipChecker {
	function punkIndexToAddress(uint256) external view returns (address);

	function ownerOf(address, uint256) external view returns (address);
}