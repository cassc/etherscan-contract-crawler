// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event WrapperCreated(address indexed collection, address wrapper, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function getCollection(address wrapper) external view returns (address collection);
    function getWrapper(address collection) external view returns (address wrapper);
    function allWrappers(uint) external view returns (address wrapper);
    function allWrappersLength() external view returns (uint);

    function delegates(address token0, address token1) external view returns (bool);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function createWrapper(address collection) external returns (address wrapper);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}