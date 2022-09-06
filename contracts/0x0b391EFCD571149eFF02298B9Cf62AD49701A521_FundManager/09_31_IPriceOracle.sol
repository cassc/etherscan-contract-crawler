// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPriceOracle {
    function factory() external view returns (address);

    function wethAddress() external view returns (address);

    function convertToETH(address token, uint256 amount) external view returns (uint256);

    function convert(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256);

    function getTokenETHPool(address token) external view returns (address);

    function getPool(address token0, address token1) external view returns (address);
}