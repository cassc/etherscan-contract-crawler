/*
██   ██ ██████   █████   ██████      ████████  ██████  ██   ██ ███████ ███    ██ 
 ██ ██  ██   ██ ██   ██ ██    ██        ██    ██    ██ ██  ██  ██      ████   ██ 
  ███   ██   ██ ███████ ██    ██        ██    ██    ██ █████   █████   ██ ██  ██ 
 ██ ██  ██   ██ ██   ██ ██    ██        ██    ██    ██ ██  ██  ██      ██  ██ ██ 
██   ██ ██████  ██   ██  ██████         ██     ██████  ██   ██ ███████ ██   ████ 
*/
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract XDAO is ERC20, ERC20Permit {
    constructor() ERC20("XDAO", "XDAO") ERC20Permit("XDAO") {
        _mint(msg.sender, 1000000000 * 10**decimals());
    }
}