// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is ERC20, ERC20Burnable {
    uint256 constant private TOTAL_SUPPLY = 100000000 ether;

    constructor() ERC20("Relaxik", "RELAX") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}