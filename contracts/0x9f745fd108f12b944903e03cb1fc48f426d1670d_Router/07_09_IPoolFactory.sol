// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint32 feeNumerator
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function owner() external view returns (address);

    function ownerSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint32 feeNumerator
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}