// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KekCash is ERC20 {
    constructor() ERC20("KekCash", "KEK") {
        _mint(msg.sender, 80081358008135e18);
    }
}