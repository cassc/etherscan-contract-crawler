// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";

error NotMinter();

contract G3MToken is ERC20 {
    constructor(
    ) ERC20("Ardaria Gem", "G3M", 18) {
        _mint(msg.sender, 444_000_000_000_000_000_000_000_000);
    }
}