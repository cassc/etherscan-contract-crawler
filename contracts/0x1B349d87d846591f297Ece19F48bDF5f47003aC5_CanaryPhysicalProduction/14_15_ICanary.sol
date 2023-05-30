// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ICanary is IERC721Enumerable {
    function MAX_SUPPLY() external view returns (uint256 maxSupply);
    
    function tokenIdToMetadataIndex(uint256 tokenId) external view returns (uint256 metadataIndex);

    function metadataAssigned(uint256 tokenId) external view returns (bool assigned);
}