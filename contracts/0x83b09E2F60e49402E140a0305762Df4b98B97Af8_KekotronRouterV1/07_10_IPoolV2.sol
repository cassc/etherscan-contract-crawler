// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPoolV2 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}