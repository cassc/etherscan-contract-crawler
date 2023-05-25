// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint16 fee,
        uint256 allPairsLength
    );

    function possibleFees(uint256) external view returns (uint16);

    function allPairs(uint256) external view returns (address);

    function antfarmToken() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint16 fee
    ) external view returns (address pair);

    function feesForPair(
        address tokenA,
        address tokenB,
        uint256
    ) external view returns (uint16);

    function getFeesForPair(address tokenA, address tokenB)
        external
        view
        returns (uint16[8] memory fees);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint16 fee
    ) external returns (address pair);
}