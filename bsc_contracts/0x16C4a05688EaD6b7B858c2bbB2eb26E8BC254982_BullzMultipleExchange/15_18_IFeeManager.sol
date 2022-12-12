// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

/**
 * @title Fee manager
 * @dev Interface to managing DEX fee.
 */
interface IFeeManager {
    /**
     * @notice Manage fee to be paid to each nft sell
     * @dev set fee percentage by index
     * @param index the index of the fee
     * @param newFee the fee percentage
     */
    function setFeeTo(uint256 index, uint256 newFee) external;

    event SetFeeTo(uint256 index, uint256 newFee);
}