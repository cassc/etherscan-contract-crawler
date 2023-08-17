// SPDX-License-Identifier: MIT
// @ Fair.xyz dev

pragma solidity 0.8.17;

/**
 * @dev Interface to the Collars contract with required functions
 */
interface IERC721xyzUpgradeable {

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    
    /**
     * @dev Burn a token. Requires being an approved operator or the owner of an NFT
     */
    function burn(uint256 tokenId) external returns (uint256);
}