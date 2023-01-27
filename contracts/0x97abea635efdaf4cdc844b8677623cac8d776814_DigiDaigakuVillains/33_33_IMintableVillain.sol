// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Required interface of mintable villain contracts.
 */
interface IMintableVillain {

    /**
     * @notice Mints multiple villains unmasked with the specified masked villain token ids
     */
    function unmaskVillainsBatch(address to, uint256[] calldata villainTokenIds, uint256[] calldata potionTokenIds) external;
}