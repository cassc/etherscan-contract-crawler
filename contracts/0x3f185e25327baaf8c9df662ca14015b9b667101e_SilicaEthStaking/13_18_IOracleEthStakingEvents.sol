// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Alkimiya OraclePoS
 * @author Alkimiya Team
 * @notice This is the interface for Proof of Stake Oracle contract
 * */
interface IOracleEthStakingEvents {
    /**
     * @notice Oracle Uptade Event
     */
    event OracleUpdate(
        address indexed caller,
        uint256 indexed referenceDay,
        uint256 timestamp,
        uint256 baseRewardPerIncrementPerDay,
        uint256 burnFee,
        uint256 priorityFee,
        uint256 burnFeeNormalized,
        uint256 priorityFeeNormalized
    );
}