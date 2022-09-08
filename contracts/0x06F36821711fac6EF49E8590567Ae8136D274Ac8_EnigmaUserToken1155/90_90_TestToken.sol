// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e10);
    }
}