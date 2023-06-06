// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPoolSelector {
    // Error
    error InvalidTargetWeight();
    error InvalidNewTargetInput();
    error InvalidSumOfPoolWeights();

    // Events

    event UpdatedPoolWeight(uint8 indexed poolId, uint256 poolWeight);
    event UpdatedPoolAllocationMaxSize(uint16 poolAllocationMaxSize);
    event UpdatedStaderConfig(address staderConfig);

    // Getters

    // returns the index in poolIdArray of the pool with excess supply
    function poolIdArrayIndexForExcessDeposit() external view returns (uint256);

    function computePoolAllocationForDeposit(uint8, uint256) external view returns (uint256);

    function poolAllocationForExcessETHDeposit(uint256 _excessETH) external returns (uint256[] memory, uint8[] memory);
}