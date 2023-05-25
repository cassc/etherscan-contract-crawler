// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFeeCollector {
    function recordBuyFee(uint amount) external;

    function recordSellFee(uint amount) external;

    function distributeIfNeeded() external;
}