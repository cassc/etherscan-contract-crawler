// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IOracleEthStakingEvents.sol";

/**
 * @title Alkimiya OraclePoS
 * @author Alkimiya Team
 * @notice This is the interface for Proof of Stake Oracle contract
 * */
interface IOracleEthStaking is IOracleEthStakingEvents {
    /**
     * @notice Update the Alkimiya Index for PoS instruments on Oracle for a given day
     */
    function updateIndex(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized,
        bytes memory signature
    ) external returns (bool success);

    /// @notice Function to return Oracle index on given day
    function get(uint256 _referenceDay)
        external
        view
        returns (
            uint256 referenceDay,
            uint256 baseRewardPerIncrementPerDay,
            uint256 burnFee,
            uint256 priorityFee,
            uint256 burnFeeNormalized,
            uint256 priorityFeeNormalized,
            uint256 timestamp
        );

    /// @notice Function to return array of oracle data between firstday and lastday (inclusive)
    function getInRange(uint256 _firstDay, uint256 _lastDay) external view returns (uint256[] memory baseRewardPerIncrementPerDayArray);

    /**
     * @notice Return if the network data on a given day is updated to Oracle
     */
    function isDayIndexed(uint256 _referenceDay) external view returns (bool);

    /**
     * @notice Return the last day on which the Oracle is updated
     */
    function getLastIndexedDay() external view returns (uint32);
}