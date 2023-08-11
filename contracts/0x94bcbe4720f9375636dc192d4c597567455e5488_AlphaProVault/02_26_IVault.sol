// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IVault {
    function deposit(
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external returns (uint256, uint256, uint256);

    function withdraw(uint256, uint256, uint256, address) external returns (uint256, uint256);

    function getTotalAmounts() external view returns (uint256, uint256);

    function getBalance0() external view returns (uint256);

    function getBalance1() external view returns (uint256);

    function rebalance() external;

    function checkCanRebalance() external view;

    // state variables
    function fullLower() external view returns (int24);

    function fullUpper() external view returns (int24);

    function baseLower() external view returns (int24);

    function baseUpper() external view returns (int24);

    function limitLower() external view returns (int24);

    function limitUpper() external view returns (int24);

    function pool() external view returns (IUniswapV3Pool);

    function protocolFee() external view returns (uint24);

    function managerFee() external view returns (uint24);

    function manager() external view returns (address);

    function pendingManager() external view returns (address);

    function rebalanceDelegate() external view returns (address);

    function maxTotalSupply() external view returns (uint256);

    function fullRangeWeight() external view returns (uint24);

    function period() external view returns (uint32);

    function minTickMove() external view returns (int24);

    function maxTwapDeviation() external view returns (int24);

    function twapDuration() external view returns (uint32);

    function tickSpacing() external view returns (int24);

    function accruedProtocolFees0() external view returns (uint256);

    function accruedProtocolFees1() external view returns (uint256);

    function accruedManagerFees0() external view returns (uint256);

    function accruedManagerFees1() external view returns (uint256);

    function lastTimestamp() external view returns (uint256);

    function lastTick() external view returns (int24);

    function baseThreshold() external view returns (int24);

    function limitThreshold() external view returns (int24);

    function pendingManagerFee() external view returns (uint24);
}