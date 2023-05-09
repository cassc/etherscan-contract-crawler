// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address walletAddress
    ) ERC20(name, symbol) {
        uint256 devAmount = (initialSupply * 9) / 100;
        _mint(walletAddress, devAmount);
        _mint(msg.sender, initialSupply - devAmount);
    }
}