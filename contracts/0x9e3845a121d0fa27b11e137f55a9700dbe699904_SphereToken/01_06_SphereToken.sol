// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract SphereToken is ERC20Burnable {
    constructor(uint256 initialBalance) ERC20("Sphere", "SXS") {
        _mint(msg.sender, initialBalance * 10 ** decimals());
    }
}