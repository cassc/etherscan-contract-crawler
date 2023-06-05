// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


interface IMarket {
    function execute(bytes memory tradeData)
        external
        payable;
}