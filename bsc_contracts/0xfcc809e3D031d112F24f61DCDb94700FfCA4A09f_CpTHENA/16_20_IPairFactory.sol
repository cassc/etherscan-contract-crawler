// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IPairFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function token0() external view returns (address);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
}