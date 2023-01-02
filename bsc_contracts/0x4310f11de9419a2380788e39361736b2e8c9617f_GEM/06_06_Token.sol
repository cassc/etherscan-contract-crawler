// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {ERC20Burnable} from "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

contract GEM is ERC20Burnable {
    constructor() ERC20("GEN Token", "GEN") {
        _mint(_msgSender(), 1_000_000 ether);
    }
}