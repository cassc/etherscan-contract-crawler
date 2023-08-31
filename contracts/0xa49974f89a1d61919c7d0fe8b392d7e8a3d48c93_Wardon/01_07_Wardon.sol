// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Wardon is ERC20Capped, Ownable {
    constructor(uint256 cap) ERC20("Wardon", "WRDN") ERC20Capped(cap) {}

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }
}