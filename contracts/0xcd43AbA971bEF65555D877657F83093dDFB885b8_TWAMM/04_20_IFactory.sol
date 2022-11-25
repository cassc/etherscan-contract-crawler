// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

interface IFactory {
    event PairCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pair,
        uint256
    );

    function getPair(
        address token0,
        address token1
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function feeArg() external view returns (uint32);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function allPairsLength() external view returns (uint256);

    function initialize(address _twammAdd) external;

    function twammAdd() external view returns (address);

    function createPair(
        address token0,
        address token1
    ) external returns (address pair);

    function setFeeArg(uint32) external;

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}