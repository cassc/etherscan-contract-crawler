// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ERC20Token is ERC20, ERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply,
        address mintaddr
    ) ERC20(name, symbol) {
        ERC20._mint(mintaddr, supply);
    }
}