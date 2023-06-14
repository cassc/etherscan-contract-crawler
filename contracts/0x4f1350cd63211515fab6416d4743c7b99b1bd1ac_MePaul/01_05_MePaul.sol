/**
 * __       __                  _______                      __ 
 *|  \     /  \                |       \                    |  \
 *| $$\   /  $$  ______        | $$$$$$$\ ______   __    __ | $$
 *| $$$\ /  $$$ /      \       | $$__/ $$|      \ |  \  |  \| $$
 *| $$$$\  $$$$|  $$$$$$\      | $$    $$ \$$$$$$\| $$  | $$| $$
 *| $$\$$ $$ $$| $$    $$      | $$$$$$$ /      $$| $$  | $$| $$
 *| $$ \$$$| $$| $$$$$$$$      | $$     |  $$$$$$$| $$__/ $$| $$
 *| $$  \$ | $$ \$$     \      | $$      \$$    $$ \$$    $$| $$
 * \$$      \$$  \$$$$$$$       \$$       \$$$$$$$  \$$$$$$  \$$
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MePaul is ERC20 {
    constructor(uint256 initialSupply) ERC20("Me Paul", "PAUL") {
        _mint(msg.sender, initialSupply);
    }
}