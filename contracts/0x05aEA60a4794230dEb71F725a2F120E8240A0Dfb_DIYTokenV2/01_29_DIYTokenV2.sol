// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./DIYToken.sol";
import "hardhat/console.sol";

contract DIYTokenV2 is DIYToken {
    function initializeV2(
        string memory name,
        string memory symbol
    ) public  reinitializer(2) {
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        console.log("Ran reinitializer");
    }
}