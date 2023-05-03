// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.6;

interface IApeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address token0, address token1) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address token0, address token1) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}