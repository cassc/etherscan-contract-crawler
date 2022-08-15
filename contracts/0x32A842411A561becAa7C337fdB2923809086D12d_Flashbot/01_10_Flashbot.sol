//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Withdraw.sol";

contract Flashbot is Withdraw {
    uint256 private lastValue;
    address public base;
    address public name;

    function transferToCoinBase(uint256 value) public {
        lastValue = value;
        base = block.coinbase;
        name = msg.sender;
        block.coinbase.transfer(value);
    }

    receive() external payable {}
}