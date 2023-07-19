// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IUniswapV2Oracle {
    function currentBlockTimestamp() external view returns (uint32);

    function currentCumulativePrices(address pair)
        external
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        );
}