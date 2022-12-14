// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Required interface of mintable potion contracts.
 */
interface IMintablePotion {

    /**
     * @notice Mints multiple potions crafted with the specified dark spirit token ids and dark hero spirit token ids
     */
    function mintPotionsBatch(address to, uint256[] calldata darkSpiritTokenIds, uint256[] calldata darkHeroSpiritTokenIds) external;
}