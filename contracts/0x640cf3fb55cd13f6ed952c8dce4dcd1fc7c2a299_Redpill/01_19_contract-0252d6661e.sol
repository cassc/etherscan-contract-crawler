// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Redpill is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("Redpill", "REDPILL") ERC20Permit("Redpill") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}