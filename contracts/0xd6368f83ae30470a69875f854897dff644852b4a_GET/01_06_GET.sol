// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract GET is ERC20Burnable {
    constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}