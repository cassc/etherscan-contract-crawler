// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IAtomicCollateralizableERC721
 * @author Parallel
 * @notice Defines the basic interface for an AtomicCollateralizableERC721.
 **/
interface IAtomicCollateralizableERC721 {
    /**
     * @dev check if specific token has atomic pricing (has atomic oracle wrapper)
     */
    function isAtomicPricing() external view returns (bool);

    /**
     * @dev get the avg trait multiplier of collateralized tokens
     */
    function avgMultiplierOf(address user) external view returns (uint256);

    /**
     * @dev get the trait multiplier of specific NFT
     */
    function getTraitMultiplier(uint256 tokenId)
        external
        view
        returns (uint256);
}