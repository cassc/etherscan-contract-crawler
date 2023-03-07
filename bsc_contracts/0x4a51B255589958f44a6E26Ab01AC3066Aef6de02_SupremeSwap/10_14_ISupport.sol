// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IPriceAggregator {
    function swap(address)
        external
        returns (uint256 swappedAmount, address swappedToken);
}

interface IPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);
}