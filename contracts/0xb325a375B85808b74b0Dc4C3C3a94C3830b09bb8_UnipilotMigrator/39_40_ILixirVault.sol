// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "./ILixirVaultToken.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface ILixirVault is ILixirVaultToken {
    function initialize(
        string memory name,
        string memory symbol,
        address _token0,
        address _token1,
        address _strategist,
        address _keeper,
        address _strategy
    ) external;

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function activeFee() external view returns (uint24);

    function activePool() external view returns (IUniswapV3Pool);

    function performanceFee() external view returns (uint24);

    function strategist() external view returns (address);

    function strategy() external view returns (address);

    function keeper() external view returns (address);

    function setKeeper(address _keeper) external;

    function setStrategist(address _strategist) external;

    function setStrategy(address _strategy) external;

    function setPerformanceFee(uint24 newFee) external;

    function mainPosition()
        external
        view
        returns (int24 tickLower, int24 tickUpper);

    function rangePosition()
        external
        view
        returns (int24 tickLower, int24 tickUpper);

    function rebalance(
        int24 mainTickLower,
        int24 mainTickUpper,
        int24 rangeTickLower0,
        int24 rangeTickUpper0,
        int24 rangeTickLower1,
        int24 rangeTickUpper1,
        uint24 fee
    ) external;

    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver,
        uint256 deadline
    ) external returns (uint256 amount0Out, uint256 amount1Out);

    function withdrawFrom(
        address withdrawer,
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        uint256 deadline
    ) external returns (uint256 amount0Out, uint256 amount1Out);

    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        uint256 deadline
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    function calculateTotals()
        external
        view
        returns (
            uint256 total0,
            uint256 total1,
            uint128 mL,
            uint128 rL
        );

    function calculateTotalsFromTick(int24 virtualTick)
        external
        view
        returns (
            uint256 total0,
            uint256 total1,
            uint128 mL,
            uint128 rL
        );
}