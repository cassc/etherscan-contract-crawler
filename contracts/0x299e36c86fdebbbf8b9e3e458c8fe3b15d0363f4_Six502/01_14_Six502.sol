// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Six502 is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("SIX502", "SIX502") ERC20Permit("SIX502") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}