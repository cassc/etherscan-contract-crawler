// SPDX-License-Identifier: MIT
// https://t.me/o_Oportal
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DisapprovingFace is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 420800851010101 * 10 ** decimals());
    }
}