/*
GYSR team vesting token

Basic ERC20 compliant contract to stake in Geyser which enforces
team vesting schedule

https://github.com/gysr-io/aux

SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TeamToken is ERC20 {
    uint256 DECIMALS = 18;
    uint256 TOTAL_SUPPLY = 1 * 10**DECIMALS;

    constructor() ERC20("GYSR-team-2", "TEAM-2") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}