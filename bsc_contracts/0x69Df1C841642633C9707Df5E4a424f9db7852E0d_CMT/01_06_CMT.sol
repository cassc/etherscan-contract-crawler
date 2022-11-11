// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract CMT is ERC20Upgradeable {
    constructor(address holder) public {
        __ERC20_init("Coin Manage Token", "CMT");
        _mint(holder, 42000000 ether);
    }
}