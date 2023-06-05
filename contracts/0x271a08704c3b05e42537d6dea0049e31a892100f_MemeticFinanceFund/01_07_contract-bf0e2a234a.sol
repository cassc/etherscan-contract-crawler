// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract MemeticFinanceFund is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Memetic Finance Fund", "MFF") {
        _mint(msg.sender, 277700 * 1 ** decimals());
    }
}