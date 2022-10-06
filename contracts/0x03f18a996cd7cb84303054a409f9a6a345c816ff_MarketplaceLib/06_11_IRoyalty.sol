// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Royalty interfaces
 */
interface IRoyalty {

    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

}