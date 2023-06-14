// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Powel is ERC20 {
    constructor(uint256 _supply) ERC20("Powel Printer", "POWEL") {
        _mint(msg.sender, _supply);
    }
}