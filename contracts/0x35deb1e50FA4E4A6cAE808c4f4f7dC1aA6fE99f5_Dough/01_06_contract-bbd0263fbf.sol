// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Dough is ERC20, ERC20Burnable {
    uint256 private DEV_WALLET_PERCENTAGE = 7;

    constructor(address devAddress) ERC20("Dough coin", "DOUGH") {
        uint256 totalSupply = 222_222_222_222_222 ether;
        uint256 devFee = (totalSupply * DEV_WALLET_PERCENTAGE) / 100;
        _mint(devAddress, devFee);
        _mint(msg.sender, totalSupply - devFee);
    }
}