// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IDystPair {
    function getAmountOut(uint256, address) external view returns (uint256);

    function token0() external returns (address);

    function token1() external returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function stable() external returns (bool);
}