// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract DoodlesTwo is ERC20, Ownable, ERC20Burnable  {
    constructor() ERC20("Doodles Two", "Doodle") {
        _mint(msg.sender, 69_000_000_000 * 1e18);
    }
}