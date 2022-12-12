// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {ERC20Burnable} from "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

contract LevelToken is ERC20Burnable {
    uint256 public constant MAX_SUPPLY = 50_000_000 ether;

    constructor() ERC20("Level Token", "LVL") {
        _mint(_msgSender(), MAX_SUPPLY);
    }
}