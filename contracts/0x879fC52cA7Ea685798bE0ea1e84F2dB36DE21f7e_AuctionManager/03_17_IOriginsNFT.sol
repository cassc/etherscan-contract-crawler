// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Utils
import "../utils/NFTPayoutsUpgradeable.sol";

/**
 * @title IOriginsNFT
 * @dev Interface for OriginsNFT contract
 * @author kazunetakeda25
 */
interface IOriginsNFT {
    /**
     * @dev Mint NFT with ID `tokenId_` (called by Auction Manager)
     * @param to_ (address) Mint to address
     * @param tokenId_ (uint256) Token ID to mint
     */
    function mint(address to_, uint256 tokenId_) external;
}