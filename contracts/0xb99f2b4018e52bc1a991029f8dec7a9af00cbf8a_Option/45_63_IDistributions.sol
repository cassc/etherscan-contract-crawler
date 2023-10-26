// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

/**
 * @title IDistributions interface
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @dev Interface for managing fee and reward distributions
 */
interface IDistributions {
    /**
     * @notice Get the entry fee ratio
     * @dev Returns the current entry fee ratio in basis points (i.e., parts per 10,000)
     * @return The current entry fee ratio
     */
    function readEntryFeeRatio() external view returns (uint16);

    /**
     * @notice Get the exercise fee ratio
     * @dev Returns the current exercise fee ratio in basis points (i.e., parts per 10,000)
     * @return The current exercise fee ratio
     */
    function readExerciseFeeRatio() external view returns (uint16);

    /**
     * @notice Get the withdraw fee ratio
     * @dev Returns the current withdraw fee ratio in basis points (i.e., parts per 10,000)
     * @return The current withdraw fee ratio
     */
    function readWithdrawFeeRatio() external view returns (uint16);

    /**
     * @notice Get the redeem fee ratio
     * @dev Returns the current redeem fee ratio in basis points (i.e., parts per 10,000)
     * @return The current redeem fee ratio
     */
    function readRedeemFeeRatio() external view returns (uint16);

    /**
     * @notice Get the BULLET-to-reward ratio
     * @dev Returns the current BULLET-to-reward ratio in percentage points (i.e., parts per 100)
     * @return The current BULLET-to-reward ratio
     */
    function readBulletToRewardRatio() external view returns (uint16);

    /**
     * @notice Get the number of fee distribution targets
     * @dev Returns the number of fee distribution targets
     * @return The number of fee distribution targets
     */
    function readFeeDistributionLength() external view returns (uint256);

    /**
     * @notice Get the fee distribution target at the specified index
     * @dev Returns the fee distribution target at the specified index
     * @param i The index of the fee distribution target to retrieve
     * @return The fee distribution target at the specified index as a tuple (fee ratio, target address)
     */
    function readFeeDistribution(uint256 i) external view returns (uint8, address);

    /**
     * @notice Get the number of BULLET distribution targets
     * @dev Returns the number of BULLET distribution targets
     * @return The number of BULLET distribution targets
     */
    function readBulletDistributionLength() external view returns (uint256);

    /**
     * @notice Get the BULLET distribution target at the specified index
     * @dev Returns the BULLET distribution target at the specified index
     * @param i The index of the BULLET distribution target to retrieve
     * @return The BULLET distribution target at the specified index as a tuple (distribution ratio, target address)
     */
    function readBulletDistribution(uint256 i) external view returns (uint8, address);
}