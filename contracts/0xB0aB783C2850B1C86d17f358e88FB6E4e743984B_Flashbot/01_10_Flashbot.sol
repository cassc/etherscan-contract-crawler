//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Withdraw.sol";

contract Flashbot is Withdraw {
    string private greeting;

    function transferToCoinBase(uint256 value) public {
        block.coinbase.transfer(value);
    }

    receive() external payable {}
}