// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Interface of an ERC721ABurnable compliant contract.
 */
interface IOwnershipable {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}