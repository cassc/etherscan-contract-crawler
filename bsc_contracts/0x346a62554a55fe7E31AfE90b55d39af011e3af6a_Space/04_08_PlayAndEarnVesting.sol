// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vesting.sol";

contract PlayAndEarnVesting is Vesting {
    constructor(){
        max = toWei(221400000);
        amountList = [
            toWei(55350000),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500),
            toWei(13837500)
        ];
    }
}