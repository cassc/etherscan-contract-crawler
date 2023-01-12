// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Six502 is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("TEST Six502", "TEST_SIX502") ERC20Permit("TEST Six502") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}