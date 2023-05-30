// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IPricingStrategy {
    /**
     * @notice Returns the next price for an N mint
     */
    function getNextPriceForNHoldersInWei(
        uint256 numberOfMints,
        address account,
        bytes memory data
    ) external view returns (uint256);

    /**
     * @notice Returns the next price for an open mint
     */
    function getNextPriceForOpenMintInWei(
        uint256 numberOfMints,
        address account,
        bytes memory data
    ) external view returns (uint256);
}