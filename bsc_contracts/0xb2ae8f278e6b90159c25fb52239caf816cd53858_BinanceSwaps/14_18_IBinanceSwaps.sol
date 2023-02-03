//SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface IBinanceSwaps {
    function binanceSwaps(uint8[] calldata, bytes[] calldata) external payable;
}