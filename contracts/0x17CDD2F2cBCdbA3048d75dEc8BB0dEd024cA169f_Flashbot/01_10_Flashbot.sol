//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Withdraw.sol";

contract Flashbot is Withdraw {
    string private greeting;

    constructor() {}

    function transferToCoinBase(uint256 value) public {
        block.coinbase.transfer(value);
    }

}