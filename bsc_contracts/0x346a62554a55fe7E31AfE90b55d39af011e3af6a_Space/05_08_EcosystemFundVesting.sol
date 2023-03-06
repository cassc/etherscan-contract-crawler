// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vesting.sol";

contract EcosystemFundVesting is Vesting {
    constructor(){
        max = toWei(129150000);
        amountList = [
            toWei(129150000)
        ];
    }
}