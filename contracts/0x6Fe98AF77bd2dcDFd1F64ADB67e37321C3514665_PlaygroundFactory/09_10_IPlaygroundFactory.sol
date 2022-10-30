//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IPlaygroundFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function validPair(address pair) external view returns (bool);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address router
    ) external returns (address pair);

    function setFeeToSetter(address) external;

    function setFeeTo(address) external;
}