// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockToken is Ownable, ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

    }
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}