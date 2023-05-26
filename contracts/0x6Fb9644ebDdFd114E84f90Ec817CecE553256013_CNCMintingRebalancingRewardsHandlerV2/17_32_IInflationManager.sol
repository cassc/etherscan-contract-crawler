// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IInflationManager {
    event TokensClaimed(address indexed pool, uint256 cncAmount);
    event RebalancingRewardHandlerAdded(address indexed pool, address indexed handler);
    event RebalancingRewardHandlerRemoved(address indexed pool, address indexed handler);
    event PoolWeightsUpdated();

    function executeInflationRateUpdate() external;

    function updatePoolWeights() external;

    /// @notice returns the weights of the Conic pools to know how much inflation
    /// each of them will receive, as well as the total amount of USD value in all the pools
    function computePoolWeights()
        external
        view
        returns (address[] memory _pools, uint256[] memory poolWeights, uint256 totalUSDValue);

    function computePoolWeight(
        address pool
    ) external view returns (uint256 poolWeight, uint256 totalUSDValue);

    function currentInflationRate() external view returns (uint256);

    function getCurrentPoolInflationRate(address pool) external view returns (uint256);

    function handleRebalancingRewards(
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external;

    function addPoolRebalancingRewardHandler(
        address poolAddress,
        address rebalancingRewardHandler
    ) external;

    function removePoolRebalancingRewardHandler(
        address poolAddress,
        address rebalancingRewardHandler
    ) external;

    function rebalancingRewardHandlers(
        address poolAddress
    ) external view returns (address[] memory);

    function hasPoolRebalancingRewardHandlers(
        address poolAddress,
        address handler
    ) external view returns (bool);
}