// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IBonfireFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}