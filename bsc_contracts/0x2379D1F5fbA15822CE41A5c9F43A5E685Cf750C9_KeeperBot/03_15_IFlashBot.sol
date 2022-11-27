//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFlashBot {
    function getProfit(address pool0, address pool1)
        external
        view
        returns (uint256 profit, address baseToken);

    function flashArbitrage(address pool0, address pool1) external;
}