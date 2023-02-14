//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IRewardHandler {

    /**
     * Modification functions
     */
    function rewardTrader(address trader, address feeToken, uint amount) external;
}