// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vesting.sol";

contract TeamVesting is Vesting {
    constructor(){
        max = toWei(18450000);
        amountList = [
            toWei(0),
            toWei(922500),
            toWei(1845000),
            toWei(1845000),
            toWei(2767500),
            toWei(1383750),
            toWei(1383750),
            toWei(1383750),
            toWei(1383750),
            toWei(1383750),
            toWei(1383750),
            toWei(1383750),
            toWei(1383750)
        ];
    }
}