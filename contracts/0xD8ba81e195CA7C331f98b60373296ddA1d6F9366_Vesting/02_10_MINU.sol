// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MINU is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address vestingAddress
    ) ERC20(name, symbol) {
        uint256 amountForOwner = (initialSupply / 100) * 90;
        _mint(msg.sender, amountForOwner);
        _mint(vestingAddress, initialSupply - amountForOwner);
    }
}