// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gifto is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Gifto", "GFT") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}