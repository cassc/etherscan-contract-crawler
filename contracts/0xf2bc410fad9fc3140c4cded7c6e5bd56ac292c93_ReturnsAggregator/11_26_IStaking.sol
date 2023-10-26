// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingInitiationRead {
    /// @notice The total amount of ETH sent to the beacon chain deposit contract.
    function totalDepositedInValidators() external view returns (uint256);

    /// @notice The number of validators initiated by the staking contract.
    function numInitiatedValidators() external view returns (uint256);

    /// @notice The block number at which the staking contract has been initialised.
    function initializationBlockNumber() external view returns (uint256);
}

interface IStakingReturnsWrite {
    /// @notice Accepts funds sent by the returns aggregator.
    function receiveReturns() external payable;

    /// @notice Accepts funds sent by the unstake requests manager.
    function receiveFromUnstakeRequestsManager() external payable;
}

interface IStaking is IStakingInitiationRead, IStakingReturnsWrite {}